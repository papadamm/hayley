#include <stdint.h>

extern void led_setup(void);
extern void led_on(void);
extern void led_off(void);

static void silly_delay(uint32_t value)
{
  int i;

  for (i = 0; i < value; i++) {
    __asm ("nop");
  }
}

int main(void)
{
  led_setup();

  while (1) {
    led_on();
    silly_delay(0x100000);
    led_off();
    silly_delay(0x100000);
  }
  return 0;
}
