int rtt_strlen(const char *str)
{
  int k;

  for (k = 0; str[k] != '\0'; k++) {
  }

  return k;
}

#include "rtt-pristine/SEGGER_RTT_printf.c"

void *memset(void *b, int c, int len)
{
  char *dst = b;
  int k;

  for (k = 0; k < len; k++) {
    dst[k] = c;
  }

  return b;
}

void *memcpy(void *dst, void *src, int n)
{
  char *dst8 = dst;
  char *src8 = src;
  int k;

  for (k = 0; k < n; k++) {
    dst8[k] = src8[k];
  }

  return dst;
}
