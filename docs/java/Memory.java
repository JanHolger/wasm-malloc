public class Malloc {

    private static Memory memory = new Memory(1);

    public static void init() {
        memory.store(0, 0xFFFFFFFF);
        memory.store(4, (memory.size() * Memory.PAGE_SIZE) - 8);
    }

    private static final int OVERHEAD = 8 + 4; // PREV + HEAD + 4 Bytes Data

    public static synchronized int malloc(int size) {
        int ptr = 4;
        int head = memory.load(ptr);
        int sz = head & 0x7FFFFFFF;
        while ((head >> 31) != 0 || sz < size) {
            int newPtr = ptr + 8 + sz;
            if(newPtr >= (memory.size() * Memory.PAGE_SIZE)) {
                if((head >> 31) == 0) {
                    int missing = size - sz;
                    int delta = (missing + Memory.PAGE_SIZE - 1) / Memory.PAGE_SIZE;
                    memory.grow(delta);
                    memory.store(ptr, sz + (delta * Memory.PAGE_SIZE));
                } else {
                    int missing = size + 8;
                    int delta = (missing + Memory.PAGE_SIZE - 1) / Memory.PAGE_SIZE;
                    memory.grow(delta);
                    memory.store(newPtr - 4, ptr - 4);
                    memory.store(newPtr, (delta * Memory.PAGE_SIZE) - 8);
                }
                return malloc(size);
            }
            ptr = newPtr;
            head = memory.load(ptr);
            sz = head & 0x7FFFFFFF;
        }
        if((sz - size) < OVERHEAD) {
            memory.store(ptr, sz | 0x80000000);
        } else {
            memory.store(ptr, size | 0x80000000);
            memory.store(ptr + 4 + size, ptr - 4);
            memory.store(ptr + 8 + size, sz - size - 8);
        }
        return ptr + 4;
    }

    public static synchronized void free(int ptr) {
        int head = memory.load(ptr - 4);
        int sz = head & 0x7FFFFFFF;
        int prev = memory.load(ptr - 8);
        int nextHead = memory.load(ptr + sz + 4);
        if((nextHead >> 31) == 0) {
            int nextSz = nextHead & 0x7FFFFFFF;
            sz += 8 + nextSz;
        }
        if(prev != 0xFFFFFFFF) {
            int prevHead = memory.load(prev + 4);
            if((prevHead >> 31) == 0) {
                int prevSz = prevHead & 0x7FFFFFFF;
                sz += prevSz + 8;
                ptr = prev + 8;
                prev = memory.load(prev);
                memory.store(ptr - 8, prev);
            }
        }
        memory.store(ptr - 4, sz);
    }

}
