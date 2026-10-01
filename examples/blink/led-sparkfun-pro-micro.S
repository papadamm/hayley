#ifdef SPARKFUN_PRO_MICRO /* LED code for Sparfun Pro Micro rp2040 */
  .syntax unified

  .global led_setup
  .type led_setup, %function
led_setup:
  /* initialize GPIO25 as output for WS2812-2020 control */

  ldr r0, =0x00000120 /* PADS_BANK0 + IO_BANK0 */
  ldr r5, =(0x4000c000 + 0x3000) /* RESET_RESETS (CLR alias) */
  str r0, [r5]

  movs r0, #5
  ldr r5, =(0x400140cc + 0x0000) /* GPIO25_CTRL (normal alias) */
  str r0, [r5]

  ldr r0, =(1 << 25) /* GPIO25 */
  ldr r5, =(0xd0000024 + 0x0000) /* GPIO_OE_SET (normal alias) */
  str r0, [r5]

  bx lr

  .global led_off
  .type led_off, %function
led_off:
  /* not yet implemented */
  bx lr

  .global led_on
  .type led_on, %function
led_on:
  /* generate a waveform for WS2812-2020 */
  /* 1 x 300us reset */
  /* 24 x ( T1H (740ns) + T1L (370ns) ) */

  ldr r5, =(0xd0000014 + 0x0000) /* GPIO_OUT_SET (normal alias) */
  ldr r6, =(0xd0000018 + 0x0000) /* GPIO_OUT_CLR (normal alias) */

  movs r3, #1  /* first run one dummy change */
  movs r4, #2  /* reset + second run when cached */

  str r0, [r5] /* low to high (initial setup, end of T0H, start of T1H) */
loop_on:
  str r0, [r6] /* clear or toggle */
  nop
loop2_on:
  str r0, [r6] /* clear or toggle */
  subs r3, #1
  bne loop_on

  ldr r2, =410  /* duration of a 300 us reset pulse */
dly_on:
  subs r2, #1
  bne dly_on

  ldr r6, =(0xd000001c + 0x0000) /* GPIO_OUT_XOR (normal alias) */
  movs r3, #25 /* generate 24 identical pulses */
  subs r4, #1
  bne loop2_on

  /* force the data pin low as final step */
  ldr r6, =(0xd0000018 + 0x0000) /* GPIO_OUT_CLR (normal alias) */
  str r0, [r6] /* this turns on U3 WS2812-2020 */

  bx lr
#endif
