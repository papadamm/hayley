#ifdef GR_MANGO /* LED code for GR MANGO with LED at P0_3 */
  .syntax unified

  .global led_setup
  .type led_setup, %function
led_setup:
  /* initialize P0_3 as output set low to make sure LED is off */

  movs r0, #0xc0 /* PDR3[1:0] */
  ldr r5, =0xfcffe000 /* PORT0.PDR (16-bit) */
  strh r0, [r5]

  movs r0, #0x00 /* PODR3 */
  ldr r5, =0xfcffe040 /* PORT0.PODR (8-bit) */
  strb r0, [r5]
  bx lr

  .global led_off
  .type led_off, %function
led_off:
  movs r0, #0x00 /* PODR3 */
  ldr r5, =0xfcffe040 /* PORT0.PODR (8-bit) */
  strb r0, [r5]
  bx lr

  .global led_on
  .type led_on, %function
led_on:
  movs r0, #0x08 /* PODR3 */
  ldr r5, =0xfcffe040 /* PORT0.PODR (8-bit) */
  strb r0, [r5]
  bx lr
#endif
