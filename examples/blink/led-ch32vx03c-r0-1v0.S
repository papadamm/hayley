#ifdef CH32V203C8T6_R0_1V0 /* LED code for CH32V203C8T6_R0_1V0 using PC13 */
  .global led_setup
  .type led_setup, %function
led_setup:
  /* turn on clock to GPIO PORTC via IOPCEN bit in RCC_APB2PCENR */
  /* setup R32_GPIOC_CFGHR to configure GPIO PC13 */

  li t0, 0x10 /* IOPCEN=1 */
  li t1, 0x40021018 /* RCC_APB2PCENR */
  sw t0, 0(t1)

  li t0, 0x44644444 /* MODE13[1:0], CNF13[1:0] PC13 setup and reset default */
  li t1, 0x40011004 /* R32_GPIOC_CFGHR */
  sw t0, 0(t1)

  .global led_off
  .type led_off, %function
led_off:
  li t0, 1 << (13 + 0) /* lower 16 bits: set GPIO output to 1 */
  li t1, 0x40011010 /* R32_GPIOC_BSHR */
  sw t0, 0(t1)
  ret

  .global led_on
  .type led_on, %function
led_on:
  li t0, 1 << (13 + 16) /* upper 16 bits: clear GPIO output to 0 */
  li t1, 0x40011010 /* R32_GPIOC_BSHR */
  sw t0, 0(t1)
  ret
#endif
