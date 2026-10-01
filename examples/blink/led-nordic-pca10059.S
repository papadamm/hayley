#ifdef PCA10059 /* LED code for pca10059 with LED at P0.06 */
  .syntax unified

  .global led_setup
  .type led_setup, %function
led_setup:
  /* setup P0.06 as output but before that set the GPIO value to high */
  /* pull the GPIO low to turn on the LED */

  movs r0, #0x40 /* 1 << 6 (P0.06) */
  ldr r5, =0x50000508 /* nRF52840 GPIO OUTSET */
  str r0, [r5] /* this makes sure the LED remains off */

  movs r0, #0x03
  ldr r5, =0x50000718 /* nRF52840 GPIO PIN_CNF[6] (P0.06) */
  str r0, [r5] /* select output pin function, LED still off */
  bx lr

  .global led_off
  .type led_off, %function
led_off:
  movs r0, #0x40 /* 1 << 6 (P0.06) */
  ldr r2, =0x50000508 /* nRF52840 GPIO OUTSET */
  str r0, [r2] /* this turn off the LED */
  bx lr

  .global led_on
  .type led_on, %function
led_on:
  movs r0, #0x40 /* 1 << 6 (P0.06) */
  ldr r2, =0x5000050c /* nRF52840 GPIO OUTCLR */
  str r0, [r2] /* clearing the GPIO will make the LED turn on */
  bx lr
#endif
