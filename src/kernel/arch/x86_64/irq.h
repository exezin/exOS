#ifndef __KERNEL_IRQ_H
#define __KERNEL_IRQ_H

#include <stdint.h>

// interrupt frame
typedef struct __attribute__((packed)) {
  uint16_t ip;
  uint16_t cs;
  uint16_t flags;
  uint16_t sp;
  uint16_t ss;
} int_frame_t;

// generic catch-all handler
void irq_catch_all();

#endif // __KERNEL_IRQ_H