#include <stdint.h>

#include "gpio.h"

#ifdef SEEEDUINO_NANO
#define LED_GPIO_PIN GPIO_ATMEGA328(GPIO_PORTB, 5)
#endif

#ifdef ARDUINO_NANO_EVERY
#define LED_GPIO_PIN GPIO_ATMEGA4809(GPIO_PORTE, 2)
#endif

#if defined(PIXHAWK_6C_STM32H743)
#define LED_GPIO_PIN GPIO_STM32H7(GPIOD_PORT, 10)
#endif

#if defined(PIXHAWK_6C_STM32F103)
#define LED_GPIO_PIN GPIO_STM32F1(GPIOB_PORT, 14)
#endif

#ifdef CH32V003F4P6_R0_1V1
#define LED_GPIO_PIN GPIO_CH32V(GPIO_PORTC, 0)
#define LED_GPIO_PIN_MODE_DETAIL \
  GPIO_MODE_DETAIL_CH32V(GPIO_PUSH_PULL_OUTPUT_MODE)
#endif

#ifdef CH32V203C8T6_R0_1V0
#define LED_GPIO_PIN GPIO_CH32V(GPIO_PORTC, 13)
#define LED_GPIO_PIN_MODE_DETAIL \
  GPIO_MODE_DETAIL_CH32V(GPIO_PUSH_PULL_OUTPUT_MODE)
#endif

#ifndef LED_GPIO_PIN
#define LED_GPIO_PIN GPIO_NONE
#endif

void led_setup(void)
{
#ifdef LED_GPIO_PIN_MODE_DETAIL
  gpio_set_mode_detail(LED_GPIO_PIN, GPIO_MODE_OUTPUT, LED_GPIO_PIN_MODE_DETAIL);
#else
  gpio_set_direction(LED_GPIO_PIN, GPIO_DIR_OUTPUT);
#endif
}

void led_on_set_value(void)
{
  gpio_set_value(LED_GPIO_PIN, 1);
}

void led_off_set_value(void)
{
  gpio_set_value(LED_GPIO_PIN, 0);
}

void led_on_seq(void)
{
  gpio_seq_run(GPIO_SEQ_PINS( LED_GPIO_PIN ),
	       GPIO_SEQ_OPCODES( SEQ_SET(0) ), 0, 0);
}

void led_off_seq(void)
{
  gpio_seq_run(GPIO_SEQ_PINS( LED_GPIO_PIN ),
	       GPIO_SEQ_OPCODES( SEQ_CLEAR(0) ), 0, 0);
}

void led_flash(void)
{
  gpio_seq_run(GPIO_SEQ_PINS( LED_GPIO_PIN ),
               GPIO_SEQ_OPCODES( SEQ_CLEAR(0), SEQ_SET(0),
                                 SEQ_CLEAR(0), SEQ_SET(0),
                                 SEQ_CLEAR(0), SEQ_SET(0),
                                 SEQ_CLEAR(0), SEQ_SET(0) ), 0, 0);
}

static void silly_delay(uint32_t value)
{
  uint32_t i;

  for (i = 0; i < value; i++) {
    asm volatile ("nop");
  }
}

#if 0

#define PIN_SDA GPIO_ATMEGA4809(GPIO_PORTD, 3) // A0
#define PIN_SCL GPIO_ATMEGA4809(GPIO_PORTD, 2) // A1

#define SEQ_SDA_L SEQ_CLEAR(0)
#define SEQ_SDA_H SEQ_SET(0)
#define SEQ_SCL_L SEQ_CLEAR(1)
#define SEQ_SCL_H SEQ_SET(1)

int i2c_send_data(uint8_t data)
{
  gpio_sequence_data_out_t data_out = GPIO_SEQ_DATA_OUT(0, 0, 0, 0, 0, 0, 0, 0);
  gpio_sequence_data_in_t data_in = GPIO_SEQ_DATA_IN(0);
  int k;

  for (k = 0; k < 8; k++) {
    data_out.data_out[k] = data & 0x01;
    data >>= 1;
  }

  /* execute i2c sequence */
  gpio_seq_run(GPIO_SEQ_PINS( PIN_SDA, PIN_SCL ),
               GPIO_SEQ_OPCODES(
                                 SEQ_SET(0), SEQ_SET(1),
                                 SEQ_MODE_OUTPUT(0), SEQ_MODE_OUTPUT(1),
                                 /* generate start condition */
                                 SEQ_SDA_L, SEQ_BARRIER,
                                 SEQ_SCL_L, SEQ_BARRIER,
                                 /* clock out bit 7 */
                                 SEQ_DATA_OUT(7), SEQ_SET_VALUE(0),
                                 SEQ_SCL_H, SEQ_BARRIER, SEQ_SCL_L,
                                 /* clock out bit 6 */
                                 SEQ_DATA_OUT(6), SEQ_SET_VALUE(0),
                                 SEQ_SCL_H, SEQ_BARRIER, SEQ_SCL_L,
                                 /* clock out bit 5 */
                                 SEQ_DATA_OUT(5), SEQ_SET_VALUE(0),
                                 SEQ_SCL_H, SEQ_BARRIER, SEQ_SCL_L,
                                 /* clock out bit 4 */
                                 SEQ_DATA_OUT(4), SEQ_SET_VALUE(0),
                                 SEQ_SCL_H, SEQ_BARRIER, SEQ_SCL_L,
                                 /* clock out bit 3 */
                                 SEQ_DATA_OUT(3), SEQ_SET_VALUE(0),
                                 SEQ_SCL_H, SEQ_BARRIER, SEQ_SCL_L,
                                 /* clock out bit 2 */
                                 SEQ_DATA_OUT(2), SEQ_SET_VALUE(0),
                                 SEQ_SCL_H, SEQ_BARRIER, SEQ_SCL_L,
                                 /* clock out bit 1 */
                                 SEQ_DATA_OUT(1), SEQ_SET_VALUE(0),
                                 SEQ_SCL_H, SEQ_BARRIER, SEQ_SCL_L,
                                 /* clock out bit 0 */
                                 SEQ_DATA_OUT(0), SEQ_SET_VALUE(0),
                                 SEQ_SCL_H, SEQ_BARRIER, SEQ_SCL_L,
                                 /* ACK/NACK handling */
                                 SEQ_MODE_INPUT(0), SEQ_DATA_IN(0),
                                 SEQ_SCL_H, SEQ_BARRIER, SEQ_GET_VALUE(0),
                                 SEQ_BARRIER, SEQ_SCL_L, SEQ_BARRIER,
                                 SEQ_SDA_H, SEQ_MODE_OUTPUT(0),
                                 SEQ_BARRIER ), &data_out, &data_in);

  return data_in.data_in[0];
}

void i2c_trial(void)
{
  {
    volatile uint8_t *PINCTRL = (void *)0x473;
    *PINCTRL = 8; // Pull-up enabled
  }

  i2c_send_data(0x3c << 1);
  i2c_send_data(0x00);
}

#else
static inline void i2c_trial(void) {}
#endif

int main(void)
{
#if defined(PIXHAWK_6C_STM32H743)
  {
    volatile uint32_t *RCC_AHB4ENR = (void *)0x580244e0;
    *RCC_AHB4ENR = 0x7ff; /* enable GPIOA->GPIOK */
  }
  gpio_stm32h7_init();
#endif
#if defined(PIXHAWK_6C_STM32F103)
  {
    volatile uint32_t *RCC_AP24ENR = (void *)0x40021018;
    *RCC_AP24ENR = 0x1fd; /* enable AFIO and GPIOA->GPIOG */
  }
  gpio_stm32f1_init();
#endif

  led_setup();

  i2c_trial();

  while (1) {
    led_on_set_value();
    silly_delay(0x100000);
    led_off_set_value();
    silly_delay(0x100000);
    led_on_seq();
    silly_delay(0x100000);
    led_off_seq();
    silly_delay(0x100000);
    led_flash();
    silly_delay(0x100000);
  }

  return 0;
}
