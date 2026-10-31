#include <stdint.h>

#include "gpio.h"

#ifdef ARDUINO_NANO_EVERY
#define LED_GPIO_PIN GPIO_ATMEGA4809(GPIO_PORTE, 2)
#endif

#ifndef LED_GPIO_PIN
#define LED_GPIO_PIN GPIO_NONE
#endif

static void led_flash(void)
{
  gpio_seq_run(GPIO_SEQ_PINS( LED_GPIO_PIN ),
               GPIO_SEQ_OPCODES( SEQ_CLEAR(0), SEQ_SET(0),
                                 SEQ_CLEAR(0), SEQ_SET(0),
                                 SEQ_CLEAR(0), SEQ_SET(0),
                                 SEQ_CLEAR(0), SEQ_SET(0) ), 0, 0);
}

void led_on_set_value(void)
{
  gpio_set_value(LED_GPIO_PIN, 1);
}

void led_off_set_value(void)
{
  gpio_set_value(LED_GPIO_PIN, 0);
}

void led_on_seq(void)
{
  gpio_seq_run(GPIO_SEQ_PINS( LED_GPIO_PIN ),
	       GPIO_SEQ_OPCODES( SEQ_SET(0) ), 0, 0);
}

void led_off_seq(void)
{
  gpio_seq_run(GPIO_SEQ_PINS( LED_GPIO_PIN ),
	       GPIO_SEQ_OPCODES( SEQ_CLEAR(0) ), 0, 0);
}

static void silly_delay(uint32_t value)
{
  uint32_t i;

  for (i = 0; i < value; i++) {
    asm volatile ("nop");
  }
}

extern void led_setup(void);

int main(void)
{
  led_setup();

  while (1) {
    led_on_set_value();
    silly_delay(0x100000);
    led_off_set_value();
    silly_delay(0x100000);
    led_on_seq();
    silly_delay(0x100000);
    led_off_seq();
    silly_delay(0x100000);
    led_flash();
    silly_delay(0x100000);
  }

  return 0;
}
