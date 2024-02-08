# wasm-malloc
A language agnostic malloc implementation for WebAssembly that's written in plain WebAssembly (WAT)

## Features
- Small overhead (8 bytes per chunk)
- Automatic memory growth (starts with 1 page = 64kB, dynamically grows as needed)
- Chunk size of 1 to 2^31 bytes

## Missing Features
- Thread-safety
- Optimization using a free chunk list, currently linear search is performed
- Dynamic growth of allocated chunks (if possible)
- Using imported memory starting at an offset

## Usage
You first need to import the init, malloc & free functions aswell as the memory segment
```wasm
(import "malloc" "init" (func $init))
(import "malloc" "malloc" (func $malloc (param i32) (result i32)))
(import "malloc" "free" (func $free (param i32)))
(import "malloc" "mem" (memory 1))
```
Next you need to call the init function once (and only ONCE!). This can either be done from wasm or js. This will initialize the memory layout
```wasm
call $init
```
You can then allocate blocks of memory by calling the malloc function. It will return the address of the allocated memory in the memory segment.
```wasm
(local $buffer i32)
i32.const 1024
call $malloc
local.set $buffer
```
Using the address you can now store data in linear memory
```wasm
(data $hello "Hello World!")
...
local.get $buffer
i32.const 0
i32.const 12 ;; length of $hello
memory.init $hello
```
IMPORTANT: There is no access control to the memory. Writing more than the allocated memory will result in the entire memory getting in a corrupted state.

Finally if the allocated memory is not needed anymore you can free it by calling the free function with the address of the memory chunk (previously returned by malloc). Again, calling it with any other value or already freed memory corrupts the memory.
```wasm
local.get $buffer
call $free
```
In a real world application you could for example allocate a piece of memory, store a string inside and call a js function passing the address and length to pass over a string to js. The js function can then access the memory segment at the given address to access the string data, decode it and for example print it to the screen.

## How it works
The algorithm is pretty straight forward and doesn't do much optimization (as of right now).

To plan out the algorithm I first implemented a pseudo-version of it in Java. You can check out the "sketches" in the `/docs/java` folder. It is more readable than the web assembly text and is a 1:1 representation.

### Layout
Memory is split up in chunks of varying size, filling up the entire memory (all pages currently allocated). Each chunk starts with an 8 byte header (4 bytes holding the address of the previous chunk, 1 bit usage flag, 31 bit data length). The previous address of the first chunk is always set to the magic value 0xFFFFFFFF.

### Allocation
When malloc is called it will perform a linear search for a chunk that is
1. free (usage bit in the header)
2. big enough (31 bit data length)

When it finds a free chunk, it will either split the chunk into 2 chunks (1 used, 1 free) or allocate the entire chunk when the requested size is equal or very close to the chunk size. If no matching chunk is found it will try to grow the memory as much as needed, grow the last chunk to the new memory size and use it for allocation as explained before.

### Freeing
Freeing a chunk works in 3 steps
1. Unset the usage bit
2. Check if the following chunk is used and merge it in case it's free (extend the data length of the current chunk)
3. Check if the previous chunk is free and merge the current chunk into the previous chunk (extending the data length of the previous chunk)