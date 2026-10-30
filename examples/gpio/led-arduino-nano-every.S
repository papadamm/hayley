#ifdef ARDUINO_NANO_EVERY /* LED code for Arduino Nano Every */
  .global led_setup
  .type led_setup, %function
led_setup:
  /* set bit 2 in PORTE.DIRSET to configure PE02 as output */
  ldi r18, 1 << 2 /* bit 2 from PE02 */
  sts 0x0481 ,r18 /* PORTE.DIRSET */
  ret
#endif
