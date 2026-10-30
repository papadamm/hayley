#include <stdint.h>

#define GPIO_SEQ_MAX_OPC 8
#define GPIO_SEQ_MAX_PINS 4
#define GPIO_SEQ_MAX_DATA_IN 8
#define GPIO_SEQ_MAX_DATA_OUT 8

/* optimized constant gpio access using the lowest 32 bytes I/O space */
static inline void vport_sbi(volatile void *addr, uint8_t bit)
{
  asm volatile("sbi %0, %1" : : "I" (addr), "I" (bit));
}

static inline void vport_cbi(volatile void *addr, uint8_t bit)
{
  asm volatile("cbi %0, %1" : : "I" (addr), "I" (bit));
}

static inline uint8_t vport_in(volatile void *addr)
{
  uint8_t value = 0;
  asm volatile("in %0, %1" : "=r" (value) : "I" (addr));
  return value;
}

typedef enum { GPIO_PORTA, GPIO_PORTB, GPIO_PORTC, GPIO_PORTD,
	       GPIO_PORTE, GPIO_PORTF } gpio_port_t;

typedef uint8_t gpio_pin_t;

typedef struct {
  gpio_port_t port;
  gpio_pin_t pin;
} gpio_seq_port_pin_t;

typedef struct {
  gpio_seq_port_pin_t pp[GPIO_SEQ_MAX_PINS];
  int len;
} gpio_sequence_pins_t;

#define GPIO_SEQ_PINS(...) \
  (gpio_sequence_pins_t) \
  { .pp = { __VA_ARGS__ }, \
    .len = sizeof((gpio_seq_port_pin_t[]){ __VA_ARGS__ }) \
      / sizeof(gpio_seq_port_pin_t) \
  }

#define ATMEGA4809_GPIO(addr) (volatile void *)(addr)

static volatile void *gpio_enum_to_port[] = {
  [GPIO_PORTA] = ATMEGA4809_GPIO(0x0400), /* PORTA */
  [GPIO_PORTB] = ATMEGA4809_GPIO(0x0420), /* PORTB */
  [GPIO_PORTC] = ATMEGA4809_GPIO(0x0440), /* PORTC */
  [GPIO_PORTD] = ATMEGA4809_GPIO(0x0460), /* PORTD */
  [GPIO_PORTE] = ATMEGA4809_GPIO(0x0480), /* PORTE */
  [GPIO_PORTF] = ATMEGA4809_GPIO(0x04a0), /* PORTF */
};

static volatile void *gpio_enum_to_vport[] = {
  [GPIO_PORTA] = ATMEGA4809_GPIO(0x00), /* VPORTA */
  [GPIO_PORTB] = ATMEGA4809_GPIO(0x04), /* VPORTB */
  [GPIO_PORTC] = ATMEGA4809_GPIO(0x08), /* VPORTC */
  [GPIO_PORTD] = ATMEGA4809_GPIO(0x0c), /* VPORTD */
  [GPIO_PORTE] = ATMEGA4809_GPIO(0x10), /* VPORTE */
  [GPIO_PORTF] = ATMEGA4809_GPIO(0x14), /* VPORTF */
};

static inline void gpio_set_value(const gpio_seq_port_pin_t pp,
                                  const uint8_t value)
{
  /* use atomic bitops on VPORT.OUT whenever possible */
  if (__builtin_constant_p(pp.port) && __builtin_constant_p(pp.pin)) {
    if (value) {
      vport_sbi(gpio_enum_to_vport[pp.port] + 0x01, pp.pin);
    } else {
      vport_cbi(gpio_enum_to_vport[pp.port] + 0x01, pp.pin);
    }
  } else {
    /* use slightly more costly access using PORT (still atomic) */
    volatile uint8_t *port = gpio_enum_to_port[pp.port];

    if (value) {
      port += 0x05; /* PORT.OUTSET */
    } else {
      port += 0x06; /* PORT.OUTCLR */
    }

    *port = 1 << pp.pin;
  }
}

static inline uint8_t gpio_get_value(const gpio_seq_port_pin_t pp)
{
  uint8_t value = 0;

  /* use VPORT.IN whenever possible */
  if (__builtin_constant_p(pp.port)) {
    value = vport_in(gpio_enum_to_vport[pp.port] + 0x02);
  } else {
    /* use slightly more costly access using PORT.IN */
    volatile uint8_t *reg = gpio_enum_to_port[pp.port] + 0x08;
    value = *reg;
  }

  return (value >> pp.pin) & 0x01;
}

typedef enum { SEQ_OP_DATA_IN, SEQ_OP_DATA_OUT,
	       SEQ_OP_SET, SEQ_OP_CLEAR,
	       SEQ_OP_SET_VALUE, SEQ_OP_GET_VALUE  } gpio_seq_t;

typedef struct {
  gpio_seq_t opc[GPIO_SEQ_MAX_OPC];
  int len;
} gpio_sequence_opcodes_t;

#define GPIO_SEQ_OPCODES(...) \
  (gpio_sequence_opcodes_t) \
  { .opc = { __VA_ARGS__ }, \
    .len = sizeof((gpio_seq_t[]){ __VA_ARGS__ }) \
      / sizeof(gpio_seq_t) \
  }

#define SEQ_ARG_MASK  0xf0
#define SEQ_ARG_SHIFT 4
#define SEQ_MASK      0x0f

#define SEQ_SET(n)       (SEQ_OP_SET | ((n) << SEQ_ARG_SHIFT))
#define SEQ_CLEAR(n)     (SEQ_OP_CLEAR | ((n) << SEQ_ARG_SHIFT))
#define SEQ_DATA_IN(n)   (SEQ_OP_DATA_IN | ((n) << SEQ_ARG_SHIFT))
#define SEQ_DATA_OUT(n)  (SEQ_OP_DATA_OUT | ((n) << SEQ_ARG_SHIFT))
#define SEQ_SET_VALUE(n) (SEQ_OP_SET_VALUE | ((n) << SEQ_ARG_SHIFT))
#define SEQ_GET_VALUE(n) (SEQ_OP_GET_VALUE | ((n) << SEQ_ARG_SHIFT))

typedef struct {
  uint8_t data_in[GPIO_SEQ_MAX_DATA_IN];
  int len;
} gpio_sequence_data_in_t;

#define GPIO_SEQ_DATA_IN(...) \
  (gpio_sequence_data_in_t) \
  { .data_in = { __VA_ARGS__ }, \
    .len = sizeof((uint8_t[]){ __VA_ARGS__ }) \
      / sizeof(uint8_t) \
  }

typedef struct {
  uint8_t data_out[GPIO_SEQ_MAX_DATA_OUT];
  int len;
} gpio_sequence_data_out_t;

#define GPIO_SEQ_DATA_OUT(...) \
  (gpio_sequence_data_out_t) \
  { .data_out = { __VA_ARGS__ }, \
    .len = sizeof((uint8_t[]){ __VA_ARGS__ }) \
      / sizeof(uint8_t) \
  }

static inline void gpio_seq_run(gpio_sequence_pins_t seq_pins,
                                gpio_sequence_opcodes_t seq_opcodes,
                                gpio_sequence_data_out_t *seq_data_out,
                                gpio_sequence_data_in_t *seq_data_in)
{
  int k, m;
  uint8_t data_out_idx = 0;
  uint8_t data_in_idx = 0;

  for (k = 0; k < seq_opcodes.len; k++) {
    m = (seq_opcodes.opc[k] & SEQ_ARG_MASK) >> SEQ_ARG_SHIFT;

    if (seq_data_out && (seq_data_out->len > 0)) {
      switch (seq_opcodes.opc[k] & SEQ_MASK) {
      case SEQ_OP_DATA_OUT:
        data_out_idx = m;
        break;
      case SEQ_OP_SET_VALUE:
        gpio_set_value(seq_pins.pp[m % GPIO_SEQ_MAX_PINS],
                       seq_data_out->data_out[data_out_idx] != 0);
        break;
      }
    }
    if (seq_data_in && (seq_data_in->len > 0)) {
      switch (seq_opcodes.opc[k] & SEQ_MASK) {
      case SEQ_OP_DATA_IN:
        data_in_idx = m;
        break;
      case SEQ_OP_GET_VALUE:
        seq_data_in->data_in[data_in_idx] = \
          gpio_get_value(seq_pins.pp[m % GPIO_SEQ_MAX_PINS]);
        break;
      }
    }

    switch (seq_opcodes.opc[k] & SEQ_MASK) {
    case SEQ_OP_SET:
      gpio_set_value(seq_pins.pp[m % GPIO_SEQ_MAX_PINS], 1);
      break;
    case SEQ_OP_CLEAR:
      gpio_set_value(seq_pins.pp[m % GPIO_SEQ_MAX_PINS], 0);
      break;
    }
  }
}

const gpio_sequence_pins_t seq_led_pins = \
  GPIO_SEQ_PINS( { .port = GPIO_PORTE, .pin = 2 } );

static void led_flash(void)
{
  gpio_seq_run(seq_led_pins,
               GPIO_SEQ_OPCODES( SEQ_CLEAR(0), SEQ_SET(0),
                                 SEQ_CLEAR(0), SEQ_SET(0),
                                 SEQ_CLEAR(0), SEQ_SET(0),
                                 SEQ_CLEAR(0), SEQ_SET(0) ), 0, 0);
}

extern void led_setup(void);

void led_on_sbi(void)
{
  vport_sbi(gpio_enum_to_vport[GPIO_PORTE] + 0x01, 2);
}

void led_on_set_value(void)
{
  gpio_set_value(seq_led_pins.pp[0], 1);
}

void led_on_seq(void)
{
  gpio_seq_run(seq_led_pins, GPIO_SEQ_OPCODES(SEQ_SET(0)), 0, 0);
}

void led_off_cbi(void)
{
  vport_cbi(gpio_enum_to_vport[GPIO_PORTE] + 0x01, 2);
}

void led_off_set_value(void)
{
  gpio_set_value(seq_led_pins.pp[0], 0);
}

void led_off_seq(void)
{
  gpio_seq_run(seq_led_pins, GPIO_SEQ_OPCODES(SEQ_CLEAR(0)), 0, 0);
}

static void silly_delay(uint32_t value)
{
  uint32_t i;

  for (i = 0; i < value; i++) {
    asm volatile ("nop");
  }
}

int main(void)
{
  led_setup();

  while (1) {
    led_on_sbi();
    silly_delay(0x100000);
    led_off_cbi();
    silly_delay(0x100000);
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
