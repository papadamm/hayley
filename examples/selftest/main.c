#include <stdint.h>

#define __weak __attribute__((__weak__))

__weak void led_setup(void) {}
__weak void led_on(void) {}
__weak void led_off(void) {}

static void silly_delay(uint32_t value)
{
  uint32_t i;

  for (i = 0; i < value; i++) {
    __asm ("nop");
  }
}

static void blink_forever(int n)
{
  uint32_t k;

  while (1) {
    led_on();
    for (k = 0; k < n; k++) {
      silly_delay(0x100000);
    }
    led_off();
    for (k = 0; k < n; k++) {
      silly_delay(0x100000);
    }
  }
}

#define DATA_LEN 8

/* rodata */
const char known_rodata[DATA_LEN] = { 8, 7, 6, 5, 4, 3, 2, 1 };

/* data */
char known_data[DATA_LEN] = { 1, 2, 3, 4, 5, 6, 7, 8 };

/* bss */
char known_bss[DATA_LEN];

int known_data_correct(char *data, int length, int expected)
{
  int k;
  int sum = 0;

  for (k = 0; k < length; k++) {
    sum = sum + data[k];
  }

  return sum == expected;
}

int main(void)
{
  led_setup();

  /* do a few basic tests for read-only data, data and bss sections */

  if (!known_data_correct((char *)known_rodata, DATA_LEN, 36)) {
    blink_forever(1); /* did not find expected pattern in .rodata */
  }

  if (!known_data_correct(known_data, DATA_LEN, 36)) {
    blink_forever(2); /* did not find expected pattern in .data */
  }

  if (!known_data_correct(known_bss, DATA_LEN, 0)) {
    blink_forever(3); /* we expected all zeroes in .bss */
  }

  /* LED turned on - success */

  led_on();

  while (1) {
    __asm ("nop");
  }
  return 0;
}
