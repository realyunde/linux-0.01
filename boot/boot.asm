;
;       boot.asm
;
; boot.s is loaded at 0x7c00 by the bios-startup routines, and moves itself
; out of the way to address 0x90000, and jumps there.
;
; It then loads the system at 0x10000, using BIOS interrupts. Thereafter
; it disables all interrupts, moves the system down to 0x0000, changes
; to protected mode, and calls the start of system. System then must
; RE-initialize the protected mode in it's own tables, and enable
; interrupts as needed.
;
; NOTE! currently system is at most 8*65536 bytes long. This should be no
; problem, even in the future. I want to keep it simple. This 512 kB
; kernel size should be enough - in fact more would mean we'd have to move
; not just these start-up routines, but also do something about the cache-
; memory (block IO devices). The area left over in the lower 640 kB is meant
; for these. No other memory is assumed to be "physical", ie all memory
; over 1Mb is demand-paging. All addresses under 1Mb are guaranteed to match
; their physical addresses.
;
; NOTE1 abouve is no longer valid in it's entirety. cache-memory is allocated
; above the 1Mb mark as well as below. Otherwise it is mainly correct.
;
; NOTE 2! The boot disk type must be set at compile-time, by setting
; the following equ. Having the boot-up procedure hunt for the right
; disk type is severe brain-damage.
; The loader has been made as simple as possible (had to, to get it
; in 512 bytes with the code to move to protected mode), and continuos
; read errors will result in a unbreakable loop. Reboot by hand. It
; loads pretty fast by getting whole sectors at a time whenever possible.

; 1.44Mb disks
%define sectors 18
; 1.2Mb disks
; %define sectors 15
; 720kB disks
; %define sectors 9

%define SYSSIZE ((117249 + 15) / 16)
%define INITSEG 0x7FB0
%define KERNSEG 0x1000
%define ENDSEG  KERNSEG + SYSSIZE

        cpu     386
        section .text
        bits    16
        global  start16
start16:
        mov     ax, 0x07C0
        mov     ds, ax
        mov     ax, INITSEG
        mov     es, ax
        mov     cx, 256
        sub     si, si
        sub     di, di
        rep     movsw
        jmp     INITSEG:proceed

proceed:
        mov     ax, cs
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, 0x0400

        mov     ah, 0x03
        xor     bh, bh
        int     0x10

        mov     cx, 24
        mov     bx, 0x0007
        mov     bp, message
        mov     ax, 0x1301
        int     0x10

        mov     ax, KERNSEG
        mov     es, ax
        call    read_it
        call    kill_motor

        mov     ah, 0x03
        xor     bh, bh
        int     0x10
        mov     [510], dx

        ; move kernel
        cli
        mov     ax, 0x0000
        cld
do_move:
        mov     es, ax
        add     ax, 0x1000
        cmp     ax, 0x9000
        jz      end_move
        mov     ds, ax
        sub     di, di
        sub     si, si
        mov     cx, 0x8000
        rep     movsw
        jmp     do_move
end_move:
        mov     ax, cs
        mov     ds, ax

        lidt    [idt_48]
        lgdt    [gdt_48]

        ; enable A20
        call    empty_8042
        mov     al, 0xD1
        out     0x64, al
        call    empty_8042
        mov     al, 0xDF
        out     0x60, al
        call    empty_8042

        mov     al,0x11                ; initialization sequence
        out     0x20,al                ; send it to 8259A-1
        out     0xA0,al                ; and to 8259A-2
        mov     al,0x20                ; start of hardware int's (0x20)
        out     0x21,al
        mov     al,0x28                ; start of hardware int's 2 (0x28)
        out     0xA1,al
        mov     al,0x04                ; 8259-1 is master
        out     0x21,al
        mov     al,0x02                ; 8259-2 is slave
        out     0xA1,al
        mov     al,0x01                ; 8086 mode for both
        out     0x21,al
        out     0xA1,al
        mov     al,0xFF                ; mask off all interrupts for now
        out     0x21,al
        out     0xA1,al

        ; switch from real to protected mode
        mov     eax, cr0
        or      eax, 0x00000001
        mov     cr0, eax
        jmp     0x0008:0x0000


empty_8042:
        in      al,0x64         ; 8042 status port
        test    al,2            ; is input buffer full?
        jnz     empty_8042      ; yes - loop
        ret


sread:  dw 1            ; sectors read of current track
head:   dw 0            ; current head
track:  dw 0            ; current track

read_it:
        mov     ax, es
        test    ax, 0x0FFF
        jne     $               ; es must be at 64kB boundary
        xor     bx, bx
rp_read:
        mov     ax, es
        cmp     ax, ENDSEG
        jb      ok1_read
        ret
ok1_read:
        mov     ax, sectors
        sub     ax, [sread]
        mov     cx, ax
        shl     cx, 9
        add     cx, bx
        jnc     ok2_read
        je      ok2_read
        xor     ax,ax
        sub     ax,bx
        shr     ax,9
ok2_read:
        call    read_track
        mov     cx,ax
        add     ax,[sread]
        cmp     ax,sectors
        jne     ok3_read
        mov     ax, 1
        sub     ax, [head]
        jne     ok4_read
        inc     word [track]
ok4_read:
        mov     [head], ax
        xor     ax, ax
ok3_read:
        mov     [sread], ax
        shl     cx, 9
        add     bx, cx
        jnc     rp_read
        mov     ax, es
        add     ax, 0x1000
        mov     es, ax
        xor     bx, bx
        jmp     rp_read


read_track:
        push    ax
        push    bx
        push    cx
        push    dx
        mov     dx, [track]
        mov     cx, [sread]
        inc     cx
        mov     ch, dl
        mov     dx, [head]
        mov     dh, dl
        mov     dl, 0
        and     dx, 0x0100
        mov     ah, 2
        int     0x13
        jc      bad_rt
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

bad_rt: mov     ax, 0
        mov     dx, 0
        int     0x13
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        jmp     read_track

kill_motor:
        push    dx
        mov     dx, 0x3f2
        mov     al, 0
        out     dx, al
        pop     dx
        ret


gdt:
        dw      0x0000, 0x0000
        dw      0x0000, 0x0000

        ; 8Mb - limit=2047 (2048*4096=8Mb)
        ; base address=0
        ; code read/exec
        ; granularity=4096, 386
        dw      0x07FF, 0x0000
        dw      0x9A00, 0x00C0

        ; 8Mb - limit=2047 (2048*4096=8Mb)
        ; base address=0
        ; data read/write
        ; granularity=4096, 386
        dw      0x07FF, 0x0000
        dw      0x9200, 0x00C0


idt_48:
        dw      0       ; idt limit=0
        dw      0, 0    ; idt base=0L

gdt_48:
        dw      0x800           ; gdt limit=2048, 256 GDT entries
        dw      gdt, 0x9        ; gdt base = 0X9xxxx

message:
        db      0x0D, 0x0A
        db      "Loading system ..."
        db      0x0D, 0x0A
        db      0x0D, 0x0A

        times   510-($-$$) nop
        db      0x55, 0xAA
