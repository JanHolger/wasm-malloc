(module
    (import "log" "print" (func $print (param i32 i32)))
    (import "malloc" "malloc" (func $malloc (param i32) (result i32)))
    (import "malloc" "free" (func $free (param i32)))
    (import "malloc" "mem" (memory 1))
    (data $hello "Hello World!")
    (func $example
        (local $s i32)
        i32.const 12
        call $malloc
        local.tee $s
        i32.const 0
        i32.const 12
        memory.init $hello
        local.get $s
        i32.const 12
        call $print
        local.get $s
        call $free
    )
    (start $example)
)