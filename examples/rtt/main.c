#include "rtt/rtt.h"

// example sequence of OpenOCD commands to enable RTT on the host
// (after starting the RTT server use telnet in a separate terminal)
// > rtt server start 9090 0
// > rtt setup 0x24000000 0x60000 "XXXxxx xxxXXX"
// > rtt start
// (use hayley get-memory-base and get-memory-size for rtt setup parameters)

int main(void)
{
  SEGGER_RTT_Init();
  SEGGER_RTT_printf(0, "rtt debugging started: " __DATE__ " " __TIME__ "\n");

  while(1)
    ;

  return 0;
}
