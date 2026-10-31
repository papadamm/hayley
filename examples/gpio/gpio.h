#ifndef __GPIO_H__
#define __GPIO_H__

// gpio headers for all supported systems are included here
#include "gpio-atmega4809.h"

typedef struct {
  union {
    // a list of private per-uC definitions of how to describe a GPIO
    gpio_atmega4809_port_pin_t atmega4809;
    // make the structure at least 1 byte large to avoid div-by-zero
    uint8_t something_rather_than_nothing;
  } u;
} gpio_port_pin_t;

// function to set a GPIO to a certain value (write the state of a GPIO pin)
// this simply goes through all the implementations
// the compiler will exclude not needed variants
static inline void gpio_set_value(const gpio_port_pin_t pp,
                                  const int value)
{
  gpio_atmega4809_set_value(pp.u.atmega4809, value);
}

// function to get GPIO value (read the state of a GPIO pin)
// this simply goes through all the implementations
// the compiler will exclude not needed variants
static inline int gpio_get_value(const gpio_port_pin_t pp)
{
  int value = -1;
  value == -1 ? value = gpio_atmega4809_get_value(pp.u.atmega4809) : value;
  return value;
}

// the GPIO implementation comes with a sequencer
#include "gpio-seq.h"

// used to compile in a missing GPIO definition
#define GPIO_NONE (gpio_port_pin_t)  (gpio_port_pin_t) {}

#endif /* __GPIO_H__ */
