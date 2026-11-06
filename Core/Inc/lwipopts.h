#ifndef BITBRIDGE_LWIPOPTS_H
#define BITBRIDGE_LWIPOPTS_H

/* Run lwIP from the foreground loop without an operating system. */
#define NO_SYS 1
#define SYS_LIGHTWEIGHT_PROT 0
#define LWIP_NETCONN         0
#define LWIP_SOCKET          0

#define MEM_ALIGNMENT 4

/* Initial connectivity: IPv4 Ethernet, DHCP and ping. */
#define LWIP_IPV4     1
#define LWIP_IPV6     0
#define LWIP_ETHERNET 1
#define LWIP_ARP      1
#define LWIP_UDP      1
#define LWIP_DHCP     1
#define LWIP_ICMP     1
#define LWIP_TCP      0

#endif

