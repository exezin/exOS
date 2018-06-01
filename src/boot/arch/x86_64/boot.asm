extern long_mode_start

bits 32

; multiboot leaves us in protected mode
section .text
global start
start:
  ; init the stack
  mov esp, stack_top

  ; make sure bootloader was multiboot compliant
  call check_multiboot

  ; make sure we support CPUID by attempting
  ; to flip the ID bit (bit 21) in eflags
  call check_cpuid

  ; make sure we support long mode
  call check_long_mode

  ; setup identity mapping for first 2MB
  call init_page_tables

  ; finally enable paging
  call enable_paging

  ; load the 64bit gdt
  lgdt [gdt64.pointer]

  ; far jump to set cs and enter true long mode
  jmp gdt64.code:long_mode_start

  hlt

init_page_tables:
  ; map first p4 entry to p3
  mov eax, p3_table
  or eax, 0b11 ; present and writable bits
  mov [p4_table], eax

  ; map first p3 entry to p2
  mov eax, p2_table
  or eax, 0b11 ; present and writable bits
  mov [p3_table], eax

  ; map first p2 entry to p1
  mov eax, p1_table
  or eax, 0b11 ; present and writable bits
  mov [p2_table], eax

  ; counter
  mov ecx, 0

  ; identity map all 512 p1 entries
.init_p1_tables:
  mov eax, 0x1000    ; 4KiB
  mul ecx            ; start addr of each page (index*size)
  or eax, 0b11 ; present and writable bit
  mov [p1_table + ecx * 8], eax

  inc ecx
  cmp ecx, 512 ; check if done
  jne .init_p1_tables
  ret


enable_paging:
  ; point cr3 to p4 (the root table)
  mov eax, p4_table
  mov cr3, eax

  ; enable PAE bit in cr4
  mov eax, cr4
  or eax, 1 << 5
  mov cr4, eax

  ; set long mode bit in EFER(.LME) MSR
  mov ecx, 0xC0000080
  rdmsr
  or eax, 1 << 8
  wrmsr

  ; set paging bit in cr0 (enable paging)
  mov eax, cr0
  or eax, 1 << 31
  mov cr0, eax
  ret


check_multiboot:
  ; value multiboot will leave in eax
  cmp eax, 0x36d76289
  jne .not_multiboot
  ret
.not_multiboot:
  mov al, "0"
  jmp error


check_cpuid:
  ; copy eflags to eax
  pushfd 
  pop eax

  ; copy to ecx for later comparison
  mov ecx, eax

  ; flip the ID bit
  xor eax, 1 << 21

  ; copy eax to eflags
  push eax
  popfd

  ; copy eflags to eax
  pushfd
  pop eax

  ; restore eflags to original state
  push ecx
  popfd

  ; compare eax and ecx
  ; if they match, bit 21 wasnt flipped
  ; and thus CPUID isn't supported
  cmp eax, ecx
  je .no_cpuid
  ret
.no_cpuid:
  mov al, "1"
  jmp error


check_long_mode:
  ; check if extended cpu info is avail
  ; by getting the highest supported CPUID argument
  mov eax, 0x80000000
  cpuid
  cmp eax, 0x80000001 ; should be at least this
  jb .no_long_mode

  ; use extended cpu info to test for long mode support
  mov eax, 0x80000001 ; req extended info
  cpuid
  test edx, 1 << 29 ; test LM-bit is set in D reg
  jz .no_long_mode
  ret
.no_long_mode:
  mov al, "2"
  jmp error

error:
  ; print 'ER: <al>'
  mov dword [0xb8000], 0x4f524f45 ; E
  mov dword [0xb8004], 0x4f3a4f52 ; R
  mov dword [0xb8008], 0x4f204f20 ; :
  mov byte  [0xb800a], al
  hlt


section .bss
; page tables for identity mapping
; at start of bss to keep them page-aligned
global p4_table
global p3_table
global p2_table
global p1_table
align 4096
p4_table:
  resb 4096
p3_table:
  resb 4096
p2_table:
  resb 4096
p1_table:
  resb 4096

; for the higher half kernel (temporary)
global kp3_table
global kp2_table

kp3_table:
  resb 4096
kp2_table:
  resb 4096

; some space for the stack
stack_bottom:
  resb 4096 ; 4KiB stack
stack_top:


section .rodata
global gdt64
global gdt64.data
gdt64:
  .null: equ $ - gdt64
  dw 0xFFFF                    ; limit low
  dw 0                         ; base low
  db 0                         ; base middle
  db 0                         ; access
  db 1                         ; granularity (4kb pages, 4GB total)
  db 0                         ; base high
  .code: equ $ - gdt64
  dw 0                         ; limit low
  dw 0                         ; base low
  db 0                         ; base middle
  db 10011010b                 ; access (present, read, execute)
  db 10101111b                 ; granularity (64bit, limit 16:19 is lower 4 bits)
  db 0                         ; base high
  .data: equ $ - gdt64
  dw 0                         ; limit low
  dw 0                         ; base low
  db 0                         ; base middle
  db 10010010b                 ; access (present, read, write)
  db 0                         ; granularity
  db 0                         ; base high
  .pointer:
  dw $ - gdt64 - 1             ; limit (size - 1)
  dq gdt64                     ; base (offset)