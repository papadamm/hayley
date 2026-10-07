#ifdef CH32V003F4P6_R0_1V1 /* LED code for CH32V003F4P6_R0_1V1 using PC0 */
  .global led_setup
  .type led_setup, %function
led_setup:
  /* turn on clock to GPIO PORTC via IOPCEN bit in RCC_APB2PCENR */
  /* setup R32_GPIOC_CFGLR to configure GPIO PC0 */

  li t0, 0x10 /* IOPCEN=1 */
  li t1, 0x40021018 /* RCC_APB2PCENR */
  sw t0, 0(t1)

  li t0, 0x44444446 /* MODE0[1:0], CNF0[1:0] setup, others reset default */
  li t1, 0x40011000 /* R32_GPIOC_CFGLR */
  sw t0, 0(t1)

  .global led_off
  .type led_off, %function
led_off:
  li t0, 1 << 16 /* clear GPIO output to 0 */
  li t1, 0x40011010 /* R32_GPIOC_BSHR */
  sw t0, 0(t1) /* set GPIO output to 0 */
  ret

  .global led_on
  .type led_on, %function
led_on:
  li t0, 1 << 0 /* set GPIO output to 1 */
  li t1, 0x40011010 /* R32_GPIOC_BSHR */
  sw t0, 0(t1) /* set GPIO output to 1 */
  ret
#endif
