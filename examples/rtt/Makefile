HL :=
$(if $(shell echo $(HL)),, $(error Unable to parse HL environment variable))

CROSS_COMPILE := $(shell $(HL) get-cross-compile)
CFLAGS := $(shell $(HL) get-cflags) $(shell $(HL) get-extra-flags)
ASMFLAGS := $(shell $(HL) get-asmflags)
OBJ := rtt/rtt0.o rtt/rtt1.o rtt/rtt2.o main.o

%.o: %.S
	$(CROSS_COMPILE)gcc $(CFLAGS) -E $< | $(CROSS_COMPILE)as $(ASMFLAGS) - -o $@
%.o: %.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -Wall -c $< -o $@

.PHONY: file.hex
default: file.hex
clean:
	rm -f $(OBJ) file.hex

file.hex: $(OBJ)
	$(HL) link $^ > $@
