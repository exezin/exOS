#ifndef __KERNEL_IDT_H
#define __KERNEL_IDT_H

#include <stdint.h>

// idt entry
typedef struct __attribute__((packed)) {
  uint16_t offset_low;
  uint16_t segment;
  uint8_t  ist;
  uint8_t  flags;
  uint16_t offset_mid;
  uint32_t offset_high;
  uint32_t reserved;
} idt_gate_t;

// idt pointer
typedef struct __attribute__((packed)) {
  uint16_t  limit;
  uintptr_t base;
} idt_ptr_t;

// init and load the idt
void idt_init();

// set a specific gate
void idt_gate(uint8_t num, uintptr_t base, uint16_t segment, uint8_t flags);

#endif // __KERNEL_IDT_H