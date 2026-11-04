#include <stdint.h>

#include "gpio.h"
#include "occ-pack-flush.h"

#if defined(PIXHAWK_6C_STM32H743)

/* for each GPIO pin allow 3 sets of detail with index GPIO_MODE_xx */
typedef struct {
  uint8_t idx;
  gpio_stm32h7_mode_detail_t detail[3];
} gpio_stm32h7_unpacked_per_gpio_data_t;

typedef struct {
  struct occ_pack_flush_head head;
  gpio_stm32h7_port_t port;
  gpio_stm32h7_unpacked_per_gpio_data_t unpacked[16];
} gpio_stm32h7_cfg_unpacked_t;

typedef struct {
  uint32_t moder, otyper, ospeedr, pupdr, afrl, afrh;
} gpio_stm32h7_cfg_packed_t;

static gpio_stm32h7_cfg_unpacked_t gpio_stm32h7_occ[] = {
  [GPIOA_PORT] = {}, [GPIOB_PORT] = {}, [GPIOC_PORT] = {}, [GPIOD_PORT] = {},
  [GPIOE_PORT] = {}, [GPIOF_PORT] = {}, [GPIOG_PORT] = {}, [GPIOH_PORT] = {},
  [GPIOI_PORT] = {}, [GPIOJ_PORT] = {}, [GPIOK_PORT] = {},
};

#define head_to_unpacked(h) \
  (gpio_stm32h7_cfg_unpacked_t *) \
  ((void *)(h) - __builtin_offsetof(gpio_stm32h7_cfg_unpacked_t, head))

static void gpio_stm32h7_occ_init(struct occ_pack_flush_head *head)
{
  gpio_stm32h7_cfg_unpacked_t *cfg = head_to_unpacked(head);
  gpio_stm32h7_cfg_packed_t packed;
  gpio_stm32h7_mode_detail_t *detail;
  volatile uint32_t *base;
  int k;

  /* when building the unpacked data, clear per-pin unpacked data */
  for (k = 0; k < 16; k++) {
    memset(&cfg->unpacked[k], 0,
           sizeof(gpio_stm32h7_unpacked_per_gpio_data_t));
  }

  /* figure out base address of the GPIO controller */
  base = gpio_stm32h7_enum_to_port[cfg->port];

  /* read out GPIO hardware state into temporary local packed data */
  packed.moder = base[0]; /* 0x00: MODER */
  packed.otyper = base[1]; /* 0x04: OTYPER */
  packed.ospeedr = base[2]; /* 0x08: OSPEEDR */
  packed.pupdr = base[3]; /* 0x0c: PUPDR */
  packed.afrl = base[8]; /* 0x20: AFRL */
  packed.afrh = base[9]; /* 0x24: AFRH */

  /* for each pin, begin by shifting read out packed data into detail[0] */
  for (k = 0; k < 16; k++) {
    detail = &cfg->unpacked[k].detail[0];

    cfg->unpacked[k].idx = packed.moder & 0x3;
    /* ANALOG is treated as a kind of GPIO_MODE_FUNCTION */
    if (cfg->unpacked[k].idx >= 3) {
      cfg->unpacked[k].idx = 2;
    }

    detail->moder = packed.moder & 0x3;
    packed.moder >>= 2;

    detail->otyper = packed.otyper & 0x1;
    packed.otyper >>= 1;

    detail->ospeedr = packed.ospeedr & 0x3;
    packed.ospeedr >>= 2;

    detail->pupdr = packed.pupdr & 0x3;
    packed.pupdr >>= 2;

    if (k < 8) {
      detail->afr = packed.afrl & 0xf;
      packed.afrl >>= 4;
    } else {
      detail->afr = packed.afrh & 0xf;
      packed.afrh >>= 4;
    }
  }

  /* copy detail[0] to detail[1] and detail[2] */
  for (k = 0; k < 16; k++) {
    memcpy(&cfg->unpacked[k].detail[1], &cfg->unpacked[k].detail[0],
	   sizeof(*detail));
    memcpy(&cfg->unpacked[k].detail[2], &cfg->unpacked[k].detail[0],
	   sizeof(*detail));
  }
}

static void gpio_stm32h7_occ_pack(struct occ_pack_flush_head *head,
                                  void *pack_out)
{
  gpio_stm32h7_cfg_unpacked_t *cfg = head_to_unpacked(head);
  gpio_stm32h7_cfg_packed_t *packed = pack_out;
  gpio_stm32h7_mode_detail_t *detail;
  int k;

  /* when building the packed data, start from scratch and clear data */
  memset(packed, 0, sizeof(*packed));

  /* for each pin, shift unpacked input into packed copy of every register */
  for (k = 15; k >= 0; k--) {
    detail = &cfg->unpacked[k].detail[cfg->unpacked[k].idx];

    packed->moder <<= 2;
    packed->moder |= detail->moder;

    packed->otyper <<= 1;
    packed->otyper |= detail->otyper;

    packed->ospeedr <<= 2;
    packed->ospeedr |= detail->ospeedr;

    packed->pupdr <<= 2;
    packed->pupdr |= detail->pupdr;

    if (k >= 8) {
      packed->afrh <<= 4;
      packed->afrh |= detail->afr;
    } else {
      packed->afrl <<= 4;
      packed->afrl |= detail->afr;
    }
  }
}

static void gpio_stm32h7_occ_flush(struct occ_pack_flush_head *head,
                                   void *pack_in)
{
  gpio_stm32h7_cfg_unpacked_t *cfg = head_to_unpacked(head);
  gpio_stm32h7_cfg_packed_t *packed = pack_in;
  volatile uint32_t *base;

  /* figure out base address of the GPIO controller */
  base = gpio_stm32h7_enum_to_port[cfg->port];

  /* write packed data to GPIO hardware registers */
  base[0] = packed->moder; /* 0x00: MODER */
  base[1] = packed->otyper; /* 0x04: OTYPER */
  base[2] = packed->ospeedr; /* 0x08: OSPEEDR */
  base[3] = packed->pupdr; /* 0x0c: PUPDR */
  base[8] = packed->afrl; /* 0x20: AFRL */
  base[9] = packed->afrh; /* 0x24: AFRH */
}

static int gpio_stm32h7_occ_has_changed(struct occ_pack_flush_head *head,
                                        void *pack_a, void *pack_b)
{
  gpio_stm32h7_cfg_packed_t *packed_a = pack_a;
  gpio_stm32h7_cfg_packed_t *packed_b = pack_b;

  return memcmp(packed_a, packed_b, sizeof(*packed_a)) != 0;
}

static void gpio_stm32h7_set_mode_pack(const gpio_stm32h7_port_pin_t pp)
{
  gpio_stm32h7_cfg_packed_t packed_a, packed_b;

  occ_pack_flush(&gpio_stm32h7_occ[pp.port].head, &packed_a, &packed_b);
}

static void gpio_stm32h7_set_mode_idx(const gpio_stm32h7_port_pin_t pp,
                                      const gpio_mode_t mode)
{
  gpio_stm32h7_unpacked_per_gpio_data_t *unpacked;

  unpacked = &gpio_stm32h7_occ[pp.port].unpacked[pp.pin];

  switch(mode) {
  case GPIO_MODE_INPUT:
    unpacked->idx = 0;
    break;

  case GPIO_MODE_OUTPUT:
    unpacked->idx = 1;
    break;

  case GPIO_MODE_FUNCTION:
    unpacked->idx = 2;
    break;
  }
}

void gpio_stm32h7_set_mode_detail(const gpio_stm32h7_port_pin_t pp,
                                  const gpio_mode_t mode,
                                  const gpio_stm32h7_mode_detail_t detail)
{
  gpio_stm32h7_unpacked_per_gpio_data_t *unpacked;

  unpacked = &gpio_stm32h7_occ[pp.port].unpacked[pp.pin];

  /* use idx to determine which set of details to update */
  /* then simply copy the settings into the unpacked per-mode data area */

  gpio_stm32h7_set_mode_idx(pp, mode);
  unpacked->detail[unpacked->idx] = detail;
  gpio_stm32h7_set_mode_pack(pp);
}

static void gpio_stm32h7_set_mode_detail_ext(const gpio_stm32h7_port_pin_t pp,
                                             const gpio_mode_t mode,
                                             const gpio_mode_detail_t detail)
{
  gpio_stm32h7_set_mode_detail(pp, mode, detail.u.stm32h7);
}

void gpio_stm32h7_set_mode(const gpio_stm32h7_port_pin_t pp,
                           const gpio_mode_t mode)
{
  /* here we simply select fixed defaults with each mode to use */
  /* MODER[1:0] is set to 0x00, 0x01 or 0x02, the rest of the registers zero */

  switch(mode) {
  case GPIO_MODE_INPUT:
    gpio_stm32h7_set_mode_detail_ext(pp, mode, GPIO_MODE_DETAIL_STM32H7(0x00));
    break;

  case GPIO_MODE_OUTPUT:
    gpio_stm32h7_set_mode_detail_ext(pp, mode, GPIO_MODE_DETAIL_STM32H7(0x01));
    break;

  case GPIO_MODE_FUNCTION:
    gpio_stm32h7_set_mode_detail_ext(pp, mode, GPIO_MODE_DETAIL_STM32H7(0x02));
    break;
  }
}

struct occ_pack_flush_ops gpio_stm32h7_occ_pack_flush_ops = {
  .init = gpio_stm32h7_occ_init,
  .pack = gpio_stm32h7_occ_pack,
  .flush = gpio_stm32h7_occ_flush,
  .has_changed = gpio_stm32h7_occ_has_changed,
};

static void gpio_stm32h7_init_one(gpio_stm32h7_port_t port)
{
  gpio_stm32h7_cfg_unpacked_t *cfg = &gpio_stm32h7_occ[port];

  cfg->port = port;
  occ_pack_flush_init(&cfg->head, &gpio_stm32h7_occ_pack_flush_ops);
}

void gpio_stm32h7_init(void)
{
  gpio_stm32h7_init_one(GPIOA_PORT);
  gpio_stm32h7_init_one(GPIOB_PORT);
  gpio_stm32h7_init_one(GPIOC_PORT);
  gpio_stm32h7_init_one(GPIOD_PORT);
  gpio_stm32h7_init_one(GPIOE_PORT);
  gpio_stm32h7_init_one(GPIOF_PORT);
  gpio_stm32h7_init_one(GPIOG_PORT);
  gpio_stm32h7_init_one(GPIOH_PORT);
  gpio_stm32h7_init_one(GPIOI_PORT);
  gpio_stm32h7_init_one(GPIOJ_PORT);
  gpio_stm32h7_init_one(GPIOK_PORT);
}

#endif /* defined(PIXHAWK_6C_STM32H743) */
