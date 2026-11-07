#include <stdint.h>
#include "gpio.h"

/* I2C sequencer */
#define SEQ_SDA_L SEQ_CLEAR(0)
#define SEQ_SDA_H SEQ_SET(0)
#define SEQ_SCL_L SEQ_CLEAR(1)
#define SEQ_SCL_H SEQ_SET(1)

static void i2c_seq_start(const gpio_port_pin_t scl, const gpio_port_pin_t sda)
{
  /* generate start condition */
  gpio_seq_run(GPIO_SEQ_PINS( sda, scl ),
               GPIO_SEQ_OPCODES( SEQ_SET(0), SEQ_SET(1),
                                 SEQ_MODE_OUTPUT(0), SEQ_MODE_OUTPUT(1),
                                 /* generate start condition */
                                 SEQ_SDA_L, SEQ_BARRIER,
                                 SEQ_SCL_L, SEQ_BARRIER, ), 0, 0);
}

static int i2c_seq_out8(const gpio_port_pin_t scl, const gpio_port_pin_t sda,
			uint8_t data)
{
  gpio_sequence_data_out_t data_out;
  gpio_sequence_data_in_t data_in;
  int k;

  data_in = GPIO_SEQ_DATA_IN(0);
  data_out = GPIO_SEQ_DATA_OUT(0, 0, 0, 0, 0, 0, 0, 0);

  for (k = 0; k < 8; k++) {
    data_out.data_out[k] = data & 0x01;
    data >>= 1;
  }

  /* output 8 bits and read ack */
  gpio_seq_run(GPIO_SEQ_PINS( sda, scl ),
               GPIO_SEQ_OPCODES( /* clock out bit 7 */
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

static void i2c_seq_stop(const gpio_port_pin_t scl, const gpio_port_pin_t sda)
{
  /* generate stop condition */
  gpio_seq_run(GPIO_SEQ_PINS( sda, scl ),
               GPIO_SEQ_OPCODES( SEQ_SDA_L, SEQ_BARRIER,
                                 SEQ_SCL_L, SEQ_BARRIER,
                                 /* generate stop condition */
                                 SEQ_SCL_H, SEQ_BARRIER,
                                 SEQ_SDA_H, SEQ_BARRIER, ), 0, 0);
}

void i2c_write(const gpio_port_pin_t scl, const gpio_port_pin_t sda,
	       uint8_t device_address, uint8_t *tx_buf, unsigned int tx_len)
{
  int k;

  i2c_seq_start(scl, sda);
  i2c_seq_out8(scl, sda, device_address << 1);

  for (k = 0; k < tx_len; k++) {
    i2c_seq_out8(scl, sda, tx_buf[k]);
  }

  i2c_seq_stop(scl, sda);
}
