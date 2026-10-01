#ifdef SEEEDUINO_NANO /* LED code for Seeeduino Nano */
  .global led_setup
  .type led_setup, %function
led_setup:
  sbi 0x04, 5 /* set DDRB5 in DDRB register to configure PB5 as output */
  ret

  .global led_off
  .type led_off, %function
led_off:
  cbi 0x05, 5 /* clear PORTB5 in PORTB register to keep PB5 low */
  ret

  .global led_on
  .type led_on, %function
led_on:
  sbi 0x05, 5 /* set PORTB5 in PORTB register to drive PB5 high (LED on) */
  ret
#endif
