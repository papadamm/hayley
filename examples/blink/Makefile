HL :=
$(if $(shell echo $(HL)),, $(error Unable to parse HL environment variable))

CROSS_COMPILE := $(shell $(HL) get-cross-compile)
CFLAGS := $(shell $(HL) get-cflags) $(shell $(HL) get-extra-flags)
ASMFLAGS := $(shell $(HL) get-asmflags)
OBJ := main.o led-nordic-pca10059.o led-sparkfun-pro-micro.o \
 led-seeeduino-nano.o led-longan-nano.o led-gr-mango.o \
 led-ch32v003f4p6-r0-1v1.o led-ch32vx03c-r0-1v0.o led-arduino-nano-every.o

%.o: %.S
	$(CROSS_COMPILE)gcc $(CFLAGS) -E $< | $(CROSS_COMPILE)as $(ASMFLAGS) - -o $@
%.o: %.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -Wall -c $< -o $@

default: file.hex
clean:
	rm -f $(OBJ) file.hex

file.hex: $(OBJ)
	$(HL) link $^ > $@
