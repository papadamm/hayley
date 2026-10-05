HL :=
$(if $(shell echo $(HL)),, $(error Unable to parse HL environment variable))

CROSS_COMPILE := $(shell $(HL) get-cross-compile)
CFLAGS := $(shell $(HL) get-cflags) $(shell $(HL) get-extra-flags)
ASMFLAGS := $(shell $(HL) get-asmflags)
LED_OBJ := led-nordic-pca10059.o led-sparkfun-pro-micro.o \
 led-seeeduino-nano.o led-longan-nano.o

%.o: %.S
	$(CROSS_COMPILE)gcc $(CFLAGS) -E $< | $(CROSS_COMPILE)as $(ASMFLAGS) - -o $@
%.o: %.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -Wall -c $< -o $@

default: file.hex
clean:
	rm -f main.o $(LED_OBJ) file.hex

file.hex: main.o $(LED_OBJ)
	$(HL) link $^ > $@
