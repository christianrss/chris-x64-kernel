;; Constants
STACKSIZE       equ 4096 * 4
MULTIBOOTMAGIC  equ 0x36d76289
CHECKLONGMODE	equ 0x80000000
CHECKLONGMODE2 	equ 0x80000001
PAGETABLESIZE   equ 4096
ENABLELONGMODE  equ 0xC0000080

global start

section .text
bits 32
start:
    mov esp, stack_top

    call check_multiboot
    call check_cpuid
    call check_long_mode

    call setup_page_tables
    call enable_paging

	;; print `OK`
	mov dword [0xb8000], 0x2f4b2f4f
	hlt

check_multiboot:
    cmp eax, MULTIBOOTMAGIC
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "M"
    jmp error

check_cpuid:
	pushfd
	pop eax
	mov ecx, eax
	xor eax, 1 << 21
	push eax
	popfd
	pushfd
	pop eax
	push ecx
	popfd
	cmp eax, ecx
	je .no_cpuid
	ret
.no_cpuid:
	mov al, "C"
	jmp error

check_long_mode:
	mov eax, CHECKLONGMODE
	cpuid
	cmp eax, CHECKLONGMODE2
	jb .no_long_mode

	mov eax, CHECKLONGMODE2
	cpuid
	test edx, 1 << 29
	jz .no_long_mode

	ret
.no_long_mode:
	mov al, "L"
	jmp error

setup_page_tables:
    mov eax, page_table_l3
    or eax, 0b11 ; present, writable
    mov [page_table_l4], eax

    mov eax, page_table_l2
    or eax, 0b11 ; present, writable
    mov [page_table_l3], eax

    mov ecx, 0 ; counter

.loop:
    mov eax, 0x200000   ; 2MiB
    mul ecx
    or eax, 0b10000011  ; present, writable, huge page
    mov [page_table_l2 + ecx * 8], eax

    inc ecx      ; increment counter
    cmp ecx, 512 ; checks if the whole table is mapped
    jne .oop     ; if not, continue

    ret

enable_paging:
    ; pass page table location to cpu
    mov eax, page_table_l4
    mov cr3, eax

    ; Enable PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Enable long mode
    mov ecx, ENABLELONGMODE
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Enable paging
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret

error:
	mov dword [0xb8000], 0x4f524f45 ; Print "ERR: X" where X is the error code
	mov dword [0xb8004], 0x4f3a4f52
	mov dword [0xb8008], 0x4f204f20
	mov byte  [0xb800a], al
	hlt

section .bss
align PAGETABLESIZE
page_table_l4:
    resb PAGETABLESIZE
page_table_l3:
    resb PAGETABLESIZE
page_table_l2:
    resb PAGETABLESIZE
stack_bottom:
    resb STACKSIZE
stack_top: