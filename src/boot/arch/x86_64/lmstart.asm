global long_mode_start
extern gdt64
extern gdt64.data

KERN_START equ 0xFFFFFFFF80000000
VADDR_MASK equ 0b111111111

; we are in true 64bit long mode
bits 64

section .text
long_mode_start:
  ; set all segment registers to data descriptor
  cli
  mov ax, gdt64.data
  mov ss, ax
  mov ds, ax
  mov es, ax
  mov fs, ax
  mov gs, ax

  call setup_hh_tables

  extern kernel_main
  mov rax, KERN_START
  jmp rax

  hlt 

setup_hh_tables:
  ; linker script symbols
  extern __boot_st
  extern __boot_en
  extern __kern_st
  extern __kern_en

  ; | MSB <-----------> LSB |
  ; |  9 |  9 |  9 |   21   |
  ; | p4 | p3 | p2 | offset |
  ; using large pages in p2 (2MiB) so disregard p1

  xor rbx, rbx
  xor rax, rax
  xor r9,r9
  xor r8,r8
  xor r10,r10

  ; translate vaddr to table index
  mov rax, KERN_START
  shr rax, 39         ; p4
  and rax, VADDR_MASK ; first 9 bits
  mov r8, rax

  mov rax, KERN_START
  shr rax, 30         ; p3
  and rax, VADDR_MASK ; first 9 bits
  mov r9, rax

  mov rax, KERN_START
  shr rax, 21         ; p2
  and rax, VADDR_MASK ; first 9 bits
  mov r10, rax
  
  extern p4_table
  extern kp3_table
  extern kp2_table
  
  ; map p4 -> p3
  mov rbx, r8  ; p4
  mov rax, r9  ; p3
  mov rax, kp3_table
  or rax, 0b11 ; present and writable
  mov [p4_table + rbx * 8], rax

  ; map p3 -> p2
  mov rbx, r9  ; p3
  mov rax, r10 ; p2
  mov rax, kp2_table
  or rax, 0b11 ; present and writable
  mov [kp3_table + rbx * 8], rax

  ; get size of kernel
  mov rax, __kern_en
  sub rax, __kern_st

  ; calculate how many 2MiB pages we need
  mov r8, 0x200000 ; 2MiB
  xor rdx, rdx
  idiv r8          ; kernel size / 2MiB
  inc rax

  mov rcx, rax       ; counter, number of page tables needed
  mov rax, __kern_st ; physical start addr of kernel1
  or rax, 0b10000011 ; huge, present and writable bit
  mov rbx, r10       ; page table index

.init_hh_tables:
  mov [kp2_table + rbx * 8], rax
  add rax, 0x200000 ; move to next p2 table entry
  inc rbx           ; increase table index

  dec rcx    ; decrease counter
  cmp rcx, 0 ; check if done
  jne .init_hh_tables
  ret

; kernel calls this from c
idt_load:
  mov ax, [esp]