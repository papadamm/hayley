#ifdef ARDUINO_NANO_EVERY /* LED code for Arduino Nano Every */
  .global led_setup
  .type led_setup, %function
led_setup:
  /* set bit 2 in PORTE.DIRSET to configure PE02 as output */
  ldi r18, 1 << 2 /* bit 2 from PE02 */
  sts 0x0481 ,r18 /* PORTE.DIRSET */
  ret

  .global led_off
  .type led_off, %function
led_off:
  /* clear bit 2 in VPORTE.OUT to set PE02 low (and turn off LED) */
  cbi 0x0011, 2 /* clear bit 2 in VPORTE.OUT (faster than set PORTE.OUTCLR) */
  ret

  .global led_on
  .type led_on, %function
led_on:
  /* set bit 2 in VPORTE.OUT to set PE02 high (and turn on LED) */
  sbi 0x0011, 2 /* set bit 2 in VPORTE.OUT (faster than set PORTE.OUTSET) */
  ret
#endif
