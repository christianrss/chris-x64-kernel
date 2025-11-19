;; CONSTANTS
MULTIBOOTMAGIC equ 0xe85250d6 ; multiboot2 magic number
HEADERLENGTH equ header_end - header_start

section .multiboot_header
header_start:
    ;; magic number
    dd MULTIBOOTMAGIC ; multiboot2
    ;; architecture
    dd 0 ; protected mode i386
    ;; header length
    dd HEADERLENGTH
    ;; checksum
    dd 0x100000000 - (MULTIBOOTMAGIC + 0 + HEADERLENGTH)

    ;; end tag
    dw 0
    dw 0
    dd 8
header_end: