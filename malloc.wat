(module
    (memory (export "mem") 1)
    (func $init
        i32.const 0
        i32.const 0xFFFFFFFF ;; first chunk magic number
        i32.store
        i32.const 4
        memory.size
        i32.const 65536 ;; memory page size
        i32.mul
        i32.const 8
        i32.sub
        i32.store
    )
    (func $malloc (param $size i32) (result i32)
        (local $ptr i32)
        (local $head i32)
        (local $sz i32)
        (local $newPtr i32)
        (local $missing i32)
        (local $cond i32)
        (local $delta i32)
        i32.const 4
        local.set $ptr
        local.get $ptr
        i32.load
        local.set $head
        local.get $head
        i32.const 0x7FFFFFFF ;; "except lsb" mask
        i32.and
        local.set $sz
        (block $while1
            (loop $while1loop
                local.get $head
                i32.const 31
                i32.shr_u
                i32.const 0
                i32.ne

                local.get $sz
                local.get $size
                i32.lt_u
                i32.or

                i32.eqz
                br_if $while1
                local.get $ptr
                i32.const 8
                i32.add
                local.get $sz
                i32.add
                local.set $newPtr

                (block $if1
                    local.get $newPtr
                    memory.size
                    i32.const 65536 ;; memory page size
                    i32.mul
                    i32.ge_u

                    i32.eqz
                    br_if $if1
                    (block $if2
                        local.get $head
                        i32.const 31
                        i32.shr_u
                        i32.eqz
                        local.tee $cond
                        i32.eqz
                        br_if $if2
                        local.get $size
                        local.get $sz
                        i32.sub
                        local.set $missing
                        local.get $missing
                        i32.const 65536 ;; memory page size
                        i32.add
                        i32.const 1
                        i32.sub
                        i32.const 65536 ;; memory page size
                        i32.div_u
                        local.set $delta
                        local.get $delta
                        memory.grow
                        drop
                        local.get $ptr
                        local.get $delta
                        i32.const 65536 ;; memory page size
                        i32.mul
                        local.get $sz
                        i32.add
                        i32.store
                    )
                    (block $if2else
                        local.get $cond
                        br_if $if2else
                        local.get $size
                        i32.const 8
                        i32.add
                        local.set $missing
                        local.get $missing
                        i32.const 65536 ;; memory page size
                        i32.add
                        i32.const 1
                        i32.sub
                        i32.const 65536 ;; memory page size
                        i32.div_u
                        local.set $delta
                        local.get $delta
                        memory.grow
                        drop
                        local.get $newPtr
                        i32.const 4
                        i32.sub
                        local.get $ptr
                        i32.const 4
                        i32.sub
                        i32.store
                        local.get $newPtr
                        local.get $delta
                        i32.const 65536 ;; memory page size
                        i32.mul
                        i32.const 8
                        i32.sub
                        i32.store
                    )
                    local.get $size
                    call $malloc
                    return
                )
                local.get $newPtr
                local.set $ptr
                local.get $ptr
                i32.load
                local.set $head
                local.get $head
                i32.const 0x7FFFFFFF ;; "except lsb" mask
                i32.and
                local.set $sz
                br $while1loop
            )
        )

        (block $if3
            local.get $sz
            local.get $size
            i32.sub
            i32.const 12
            i32.lt_u
            local.tee $cond
            i32.eqz
            br_if $if3
            local.get $ptr
            local.get $sz
            i32.const 0x80000000 ;; lsb mask
            i32.or
            i32.store
        )
        (block $if3else
            local.get $cond
            br_if $if3else
            local.get $ptr
            local.get $size
            i32.const 0x80000000 ;; lsb mask
            i32.or
            i32.store
            local.get $ptr
            i32.const 4
            i32.add
            local.get $size
            i32.add
            local.get $ptr
            i32.const 4
            i32.sub
            i32.store
            local.get $ptr
            i32.const 8
            i32.add
            local.get $size
            i32.add
            local.get $sz
            local.get $size
            i32.sub
            i32.const 8
            i32.sub
            i32.store
        )
        local.get $ptr
        i32.const 4
        i32.add
        return
    )
    (func $free (param $ptr i32)
        (local $head i32)
        (local $sz i32)
        (local $prev i32)
        (local $nextHead i32)
        (local $nextSz i32)
        (local $prevHead i32)
        (local $prevSz i32)
        local.get $ptr
        i32.const 4
        i32.sub
        i32.load
        local.set $head
        local.get $head
        i32.const 0x7FFFFFFF ;; "except lsb" mask
        i32.and
        local.set $sz
        local.get $ptr
        i32.const 8
        i32.sub
        i32.load
        local.set $prev
        local.get $ptr
        local.get $sz
        i32.add
        i32.const 4
        i32.add
        i32.load
        local.set $nextHead
        (block $if1
            local.get $nextHead
            i32.const 31
            i32.shr_u
            i32.eqz

            i32.eqz
            br_if $if1
            local.get $nextHead
            i32.const 0x7FFFFFFF ;; "except lsb" mask
            i32.and
            local.set $nextSz
            local.get $sz
            i32.const 8
            i32.add
            local.get $nextSz
            i32.add
            local.set $sz
        )
        (block $if2
            local.get $prev
            i32.const 0xFFFFFFFF ;; first chunk magic number
            i32.ne

            i32.eqz
            br_if $if2
            local.get $prev
            i32.const 4
            i32.add
            i32.load
            local.set $prevHead

            (block $if3
                local.get $prevHead
                i32.const 31
                i32.shr_u
                i32.eqz

                i32.eqz
                br_if $if3
                local.get $prevHead
                i32.const 0x7FFFFFFF ;; "except lsb" mask
                i32.and
                local.set $prevSz
                local.get $sz
                local.get $prevSz
                i32.and
                i32.const 8
                i32.and
                local.set $sz
                local.get $prev
                i32.const 8
                i32.add
                local.set $ptr
                local.get $prev
                i32.load
                local.set $prev
                local.get $ptr
                i32.const 8
                i32.sub
                local.get $prev
                i32.store
            )
        )
        local.get $ptr
        i32.const 4
        i32.sub
        local.get $sz
        i32.store
    )
    (export "init" (func $init))
    (export "malloc" (func $malloc))
    (export "free" (func $free))
)