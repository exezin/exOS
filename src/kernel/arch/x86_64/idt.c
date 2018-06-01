#include "idt.h"

idt_gate_t idt[256];
idt_ptr_t idt_ptr;

// defined in int.asm
extern void idt_load();
extern void int_catch_all();

void idt_init()
{
  // setup the idt pointer
  idt_ptr.limit = (256 * sizeof(idt_gate_t)) - 1;
  idt_ptr.base  = (uintptr_t)&idt;

  // memset 0
  for (int i=0; i<256; i++) {
    idt[i].offset_low = 0;
    idt[i].segment = 0;
    idt[i].ist = 0;
    idt[i].flags = 0;
    idt[i].offset_mid = 0;
    idt[i].offset_high = 0;
  }

  // div by zero exception
  idt_gate(0, (uintptr_t)&int_catch_all, 0x8, 0xE);

  // load the idt
  idt_load();
}

void idt_gate(uint8_t num, uintptr_t base, uint16_t segment, uint8_t flags)
{
  idt[num].offset_low  = (base & 0xFFFF);
  idt[num].offset_mid  = (base >> 16) & 0xFFFF;
  idt[num].offset_high = (base >> 32) & 0xFFFFFFFF;
  idt[num].segment     = segment;
  idt[num].reserved    = 0;
  idt[num].flags       = flags | 0x80;
}