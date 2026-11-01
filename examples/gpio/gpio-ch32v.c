#include <stdint.h>

#include "gpio.h"
#include "occ-pack-flush.h"

#if defined(CH32V203C8T6_R0_1V0) || defined(CH32V003F4P6_R0_1V1)

typedef struct {
  struct occ_pack_flush_head head;
  uint8_t unpacked_cnf_mode[8]; /* 8 GPIOs per CFGxR register */
  gpio_ch32v_port_pin_t pp;
  volatile uint32_t *port;
} gpio_ch32v_cfg_unpacked_t;

typedef uint32_t gpio_ch32v_cfg_packed_t;

static gpio_ch32v_cfg_unpacked_t gpio_ch32v_cfglr_occ[] = {
  [GPIO_PORTA] = {},
  [GPIO_PORTB] = {},
  [GPIO_PORTC] = {},
  [GPIO_PORTD] = {},
  [GPIO_PORTE] = {},
  [GPIO_PORTF] = {},
};

static gpio_ch32v_cfg_unpacked_t gpio_ch32v_cfghr_occ[] = {
  [GPIO_PORTA] = {},
  [GPIO_PORTB] = {},
  [GPIO_PORTC] = {},
  [GPIO_PORTD] = {},
  [GPIO_PORTE] = {},
  [GPIO_PORTF] = {},
};

#define head_to_unpacked(h) \
  (gpio_ch32v_cfg_unpacked_t *) \
  ((void *)(h) - __builtin_offsetof(gpio_ch32v_cfg_unpacked_t, head))

static void gpio_ch32v_occ_init(struct occ_pack_flush_head *head)
{
  gpio_ch32v_cfg_unpacked_t *cfg = head_to_unpacked(head);
  uint32_t packed;
  int k;

  if (cfg->pp.pin <= 7) {
    cfg->port = gpio_ch32v_enum_to_port[cfg->pp.port] + 0x0; /* CFGLR */
  } else {
    cfg->port = gpio_ch32v_enum_to_port[cfg->pp.port] + 0x4; /* CFGHR */
  }

  /* read from hardware CFGxR register (a single 32-bit read access) */
  packed = *cfg->port;

  /* initialize unpacked data structure from hardware */
  for (k = 0; k < 8; k++) {
    cfg->unpacked_cnf_mode[k] = packed & 0x0f;
    packed >>= 4;
  }
}

static void gpio_ch32v_occ_pack(struct occ_pack_flush_head *head, void *pack_out)
{
  gpio_ch32v_cfg_unpacked_t *cfg = head_to_unpacked(head);
  uint32_t *packed_ptr = pack_out;
  uint32_t packed;
  int k;

  packed = 0;

  for (k = 7; k >= 0; k--) {
    packed <<= 4;
    packed |= cfg->unpacked_cnf_mode[k];
  }

  *packed_ptr = packed;
}

static void gpio_ch32v_occ_flush(struct occ_pack_flush_head *head, void *pack_in)
{
  gpio_ch32v_cfg_unpacked_t *cfg = head_to_unpacked(head);
  uint32_t *packed_ptr = pack_in;

  /* write to hardware CFGxR register (a single 32-bit write access) */
  *cfg->port = *packed_ptr;
}

static int gpio_ch32v_occ_has_changed(struct occ_pack_flush_head *head,
				      void *pack_a, void *pack_b)
{
  uint32_t *packed_ptr_a = (uint32_t *)pack_a;
  uint32_t *packed_ptr_b = (uint32_t *)pack_b;

  return *packed_ptr_a != *packed_ptr_b;
}


void gpio_ch32v_set_mode(const gpio_ch32v_port_pin_t pp,
			 const gpio_mode_t mode)
{
  gpio_ch32v_cfg_packed_t packed_a, packed_b;
  uint8_t value;

  if (mode == GPIO_MODE_OUTPUT) {
    value = 0x6;
  } else {
    value = 0x4;
  }

  if (pp.pin <= 7) {
    gpio_ch32v_cfglr_occ[pp.port].unpacked_cnf_mode[pp.pin] = value;
    occ_pack_flush(&gpio_ch32v_cfglr_occ[pp.port].head, &packed_a, &packed_b);
  } else {
    gpio_ch32v_cfghr_occ[pp.port].unpacked_cnf_mode[pp.pin - 8] = value;
    occ_pack_flush(&gpio_ch32v_cfghr_occ[pp.port].head, &packed_a, &packed_b);
  }
}

struct occ_pack_flush_ops gpio_ch32_occ_pack_flush_ops = {
  .init = gpio_ch32v_occ_init,
  .pack = gpio_ch32v_occ_pack,
  .flush = gpio_ch32v_occ_flush,
  .has_changed = gpio_ch32v_occ_has_changed,
};

static void gpio_ch32v_init_occ_one(gpio_ch32v_cfg_unpacked_t *cfg,
                                    gpio_ch32v_port_pin_t pp)
{
  cfg->pp = pp;
  occ_pack_flush_init(&cfg->head, &gpio_ch32_occ_pack_flush_ops);
}

static void gpio_ch32v_init_cfglr_cfghr(gpio_port_pin_t gpio_cfglr,
					gpio_port_pin_t gpio_cfghr)
{
  gpio_ch32v_init_occ_one(&gpio_ch32v_cfglr_occ[gpio_cfglr.u.ch32v.port],
                          gpio_cfglr.u.ch32v);
  gpio_ch32v_init_occ_one(&gpio_ch32v_cfghr_occ[gpio_cfghr.u.ch32v.port],
                          gpio_cfghr.u.ch32v);
}

void gpio_ch32v_init(void)
{
  gpio_ch32v_init_cfglr_cfghr(GPIO_CH32V(GPIO_PORTA, 0),
			      GPIO_CH32V(GPIO_PORTA, 8));
  gpio_ch32v_init_cfglr_cfghr(GPIO_CH32V(GPIO_PORTB, 0),
			      GPIO_CH32V(GPIO_PORTB, 8));
  gpio_ch32v_init_cfglr_cfghr(GPIO_CH32V(GPIO_PORTC, 0),
			      GPIO_CH32V(GPIO_PORTC, 8));
  gpio_ch32v_init_cfglr_cfghr(GPIO_CH32V(GPIO_PORTD, 0),
			      GPIO_CH32V(GPIO_PORTD, 8));
  gpio_ch32v_init_cfglr_cfghr(GPIO_CH32V(GPIO_PORTE, 0),
			      GPIO_CH32V(GPIO_PORTE, 8));
  gpio_ch32v_init_cfglr_cfghr(GPIO_CH32V(GPIO_PORTF, 0),
			      GPIO_CH32V(GPIO_PORTF, 8));
}

#endif /* defined(CH32V203C8T6_R0_1V0) || defined(CH32V003F4P6_R0_1V1) */
