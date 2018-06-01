bits 64

section .text

; kernel calls this from c
extern idt_ptr
global idt_load
idt_load:
  ; set idt pointer
  mov rax, idt_ptr
  lidt [rax]

  ; use APIC/IOAPIC (disable 8259)
  mov al, 0xff
  out 0xa1, al
  out 0x21, al

  ; enable interrupts
  sti
  ret

; generic exception handler
; not even half complete
extern irq_catch_all
global int_catch_all
int_catch_all:
  push rax
  push rcx
  push rdx
  push rbx
  push rbp
  push rsi
  push rdi
  cld
  call irq_catch_all
  pop rdi
  pop rsi
  pop rbp
  pop rbx
  pop rdx
  pop rcx
  pop rax
  iretq