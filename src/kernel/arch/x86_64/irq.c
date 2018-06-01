#include "irq.h"

static uint16_t* const VGA_MEMORY = (uint16_t*) 0xB8000;
static uint16_t* terminal_buffer;

void irq_catch_all()
{
  // derpy error message
  terminal_buffer = VGA_MEMORY;
  terminal_buffer[0] = (uint16_t)0x2f00 + '1'; // O
  terminal_buffer[1] = (uint16_t)0x2f00 + '/'; // O
  terminal_buffer[2] = (uint16_t)0x2f00 + '0'; // O
  terminal_buffer[3] = (uint16_t)0x2f00 + '!'; // O
}