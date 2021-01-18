; -----------------------------------------------------------------------------
; ZXX decoder by Einar Saukas
; "Turbo" version (90 bytes, 25% faster)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

dzxx_turbo:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        ld      a, $80
dzxxt_literals:
        call    dzxxt_elias             ; obtain length
        ldir                            ; copy literals
        add     a, a                    ; check next bit
        call    z, dzxxt_load_bits      ; no more bits left?
        jr      c, dzxxt_new_offset     ; copy from last offset or new offset?
        call    dzxxt_elias             ; obtain length
dzxxt_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; check next bit
        call    z, dzxxt_load_bits      ; no more bits left?
        jr      nc, dzxxt_literals      ; copy from literals or new offset?
dzxxt_new_offset:
        pop     bc                      ; discard last offset
        call    dzxxt_elias             ; obtain offset MSB
        inc     b
        dec     b
        ret     nz                      ; check end marker
        ex      af, af'                 ; adjust for negative offset
        xor     a
        sub     c
        ld      b, a
        ex      af, af'
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        push    bc                      ; preserve new offset
        call    dzxxt_elias             ; obtain length
        inc     bc
        jp      dzxxt_copy
dzxxt_elias:
        add     a, a                    ; check next bit
        call    z, dzxxt_load_bits      ; no more bits left?
        ld      bc, 1
        ret     c
        scf
dzxxt_elias_size:
        rr      b
        rr      c
        add     a, a                    ; check next bit
        call    z, dzxxt_load_bits      ; no more bits left?
        jr      nc, dzxxt_elias_size
        inc     c
dzxxt_elias_value:
        add     a, a                    ; check next bit
        call    z, dzxxt_load_bits      ; no more bits left?
        rl      c
        rl      b
        jr      nc, dzxxt_elias_value
        ret
dzxxt_load_bits:
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
        ret
; -----------------------------------------------------------------------------
