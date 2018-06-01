#include <stdint.h>

#include "idt.h"

static uint16_t* const VGA_MEMORY = (uint16_t*) 0xB8000;
static uint16_t* terminal_buffer;

void kernel_main(void)
{
  idt_init();

  terminal_buffer = VGA_MEMORY;
  terminal_buffer[0] = (uint16_t)0x2f4f; // O
  terminal_buffer[1] = (uint16_t)0x2f4b; // K

  // intentionally fire a div by zero exception
  int i = 1 / 0;
  asm("hlt");
}