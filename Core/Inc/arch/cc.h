#ifndef BITBRIDGE_LWIP_ARCH_CC_H
#define BITBRIDGE_LWIP_ARCH_CC_H

#include "main.h"

/* Keep diagnostic text out of the UART payload stream. */
#define LWIP_PLATFORM_DIAG(message) do { } while (0)

/* Stop at the project's existing error handler on assertion failure. */
#define LWIP_PLATFORM_ASSERT(message) do { Error_Handler(); } while (0)

#endif