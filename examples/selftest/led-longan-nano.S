#ifdef LONGAN_NANO /* LED code for longan nano using PC13 */
  .global led_setup
  .type led_setup, %function
led_setup:
  /* setup RCC_APB2ENR to enable clocks to GPIO blocks */
  /* clear PC13 using GPIOCBSRR to turn off the LED by default */
  /* configure GPIOC_CRH */
  /* clear/set PC13 using GPIOC_BSRR to enable/disable LED */

  li t0, 0x1fc
  li t1, 0x40021018 /* RCC_APB2ENR */
  sw t0, 0(t1)

  li t0, 0x00002000 /* LED is set to off by default */
  li t1, 0x40011010 /* GPIOC_BSRR */
  sw t0, 0(t1)

  li t0, 0x44344444
  li t1, 0x40011004 /* GPIOC_CRH */
  sw t0, 0(t1)
  ret

  .global led_off
  .type led_off, %function
led_off:
  li t0, 0x00002000 /* turn off LED */
  li t1, 0x40011010 /* GPIOC_BSRR */
  sw t0, 0(t1)
  ret

  .global led_on
  .type led_on, %function
led_on:
  li t0, 0x20000000 /* turn on LED */
  li t1, 0x40011010 /* GPIOC_BSRR */
  sw t0, 0(t1)
  ret
#endif
