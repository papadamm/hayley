#ifndef __GPIO_H__
#define __GPIO_H__

typedef enum { GPIO_DIR_INPUT, GPIO_DIR_OUTPUT } gpio_direction_t;
typedef enum { GPIO_MODE_INPUT, GPIO_MODE_OUTPUT, GPIO_MODE_FUNCTION } gpio_mode_t;

// gpio headers for all supported systems are included here
#include "gpio-atmega4809.h"
#include "gpio-ch32v.h"

typedef struct {
  union {
    // a list of private per-uC definitions of how to describe a GPIO
    gpio_atmega4809_port_pin_t atmega4809;
    gpio_ch32v_port_pin_t ch32v;
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
  gpio_ch32v_set_value(pp.u.ch32v, value);
}

// function to get GPIO value (read the state of a GPIO pin)
// this simply goes through all the implementations
// the compiler will exclude not needed variants
static inline int gpio_get_value(const gpio_port_pin_t pp)
{
  int value = -1;
  value == -1 ? value = gpio_atmega4809_get_value(pp.u.atmega4809) : value;
  value == -1 ? value = gpio_ch32v_get_value(pp.u.ch32v) : value;
  return value;
}

// function to set GPIO mode (select between GPIO input, output or function)
// this simply goes through all the implementations
// the compiler will exclude not needed variants
static inline void gpio_set_mode(const gpio_port_pin_t pp, const gpio_mode_t mode)
{
  gpio_atmega4809_set_mode(pp.u.atmega4809, mode);
  gpio_ch32v_set_mode(pp.u.ch32v, mode);
}

// function to set GPIO direction (select between GPIO input or output)
static inline void gpio_set_direction(const gpio_port_pin_t pp,
                                      const gpio_direction_t dir)
{
  if (dir == GPIO_DIR_OUTPUT) {
    gpio_set_mode(pp, GPIO_MODE_OUTPUT);
  } else {
    gpio_set_mode(pp, GPIO_MODE_INPUT);
  }
}

// the GPIO implementation comes with a sequencer
#include "gpio-seq.h"

// used to compile in a missing GPIO definition
#define GPIO_NONE (gpio_port_pin_t)  (gpio_port_pin_t) {}

#endif /* __GPIO_H__ */
