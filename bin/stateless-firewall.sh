#!/bin/bash
#
# firewall.sh
#
# Configuration directories
CONF_D="/opt/pizon.org/firewall/etc"
# Load master configuration file
source "${CONF_D}/stateless-firewall.conf"
# Script must run as root
if [ "${EUID}" != "0" ] || [ "${USER}" != "root" ]
then
    echo "You must be root to run this script."
    exit 1
fi
# Load general functions
if [ -e "${LIBEXEC}/functions.sh" ]
then
	source "${LIBEXEC}/functions.sh"
fi
# Load firewall functions
if [ -e "${LIBEXEC}/fw-functions.sh" ]
then
	source "${LIBEXEC}/fw-functions.sh"
fi
# Localhost rules
function ipv4_setup {
    # Back up IPv4 rules
    backup
    # Unload connection tracking and state modules
    for module in "${IPV4_MODULES[@]}"
    do
        modprobe -r "${module}"
    done
    unset module
    # Temporarily set filter table default policies to ACCEPT
    echo "Setting initial IPv4 filter chain policies to ACCEPT"
    for chain in INPUT OUTPUT FORWARD
    do
        "${IPTABLES}" -P "${chain}" ACCEPT
    done
    unset chain
    # Flush rules, delete custom chains and zero counters
    echo "Flushing tables and zeroing counters"
    for table in filter mangle raw nat
    do
        "${IPTABLES}" -t "${table}" -F
        "${IPTABLES}" -t "${table}" -X
        "${IPTABLES}" -t "${table}" -Z
    done
    unset table
    # Allow localhost
    "${IPTABLES}" -A INPUT -i "${LBIF}" -j ACCEPT
    "${IPTABLES}" -A OUTPUT -o "${LBIF}" -j ACCEPT
    # Rules for firewall host external interface
    # Ingress
    for udp in "${INGRESS_UDP[@]}"
    do
        "${IPTABLES}" -A INPUT -i "${EXTIF}" -p udp -m multiport --dports "${udp}" -j ACCEPT
        "${IPTABLES}" -A OUTPUT -o "${EXTIF}" -p udp -m multiport --sports "${udp}" -j ACCEPT
    done
    unset udp
    for tcp in "${INGRESS_TCP[@]}"
    do
        "${IPTABLES}" -A INPUT -i "${EXTIF}" -p tcp -m multiport --dports "${tcp}" -j ACCEPT
        "${IPTABLES}" -A OUTPUT -o "${EXTIF}" -p tcp -m multiport --sports "${tcp}" -j ACCEPT
    done
    unset tcp
    for icmp in "${INGRESS_ICMP[@]}"
    do
        "${IPTABLES}" -A INPUT -i "${EXTIF}" -p icmp --icmp-type "${icmp}" -j ACCEPT
    done
    unset icmp
    # Egress
    for udp in "${EGRESS_UDP[@]}"
    do
        "${IPTABLES}" -A INPUT -i "${EXTIF}" -p udp -m multiport --sports "${udp}" -j ACCEPT
        "${IPTABLES}" -A OUTPUT -o "${EXTIF}" -p udp -m multiport --dports "${udp}" -j ACCEPT
    done
    unset udp
    for tcp in "${EGRESS_TCP[@]}"
    do
        "${IPTABLES}" -A INPUT -i "${EXTIF}" -p tcp -m multiport --sports "${tcp}" -j ACCEPT
        "${IPTABLES}" -A OUTPUT -o "${EXTIF}" -p tcp -m multiport --dports "${tcp}" -j ACCEPT
    done
    unset tcp
    for icmp in "${EGRESS_ICMP[@]}"
    do
        "${IPTABLES}" -A OUTPUT -o "${EXTIF}" -p icmp --icmp-type "${icmp}" -j ACCEPT
    done
    unset icmp
    # Custom rules
    if [ "${CUSTOM_RULES}" -eq 1 ] && [ -f "${CUSTOM_D}/${FWHOST}_custom_v4.conf" ]
    then
        source "${CUSTOM_D}/${FWHOST}_custom_v4.conf"
    fi
}
# ipv6
function ipv6_setup {
    # Allow 6to4 tunneling
    "${IPTABLES}" -A INPUT -p 41 -j ACCEPT
    "${IPTABLES}" -A OUTPUT -p 41 -j ACCEPT
    # Unload connection tracking and state modules
    for module in "${IPV6_MODULES[@]}"
    do
        modprobe -r "${module}"
    done
    unset module
    # Temporarily set filter table default policies to ACCEPT
    echo "Setting initial IPv6 filter chain policies to ACCEPT"
    for chain in INPUT OUTPUT FORWARD
    do
        "${IP6TABLES}" -P "${chain}" ACCEPT
    done
    unset chain
    # Flush rules, delete custom chains and zero counters
    echo "Flushing tables and zeroing counters"
    for table in filter mangle raw
    do
        "${IP6TABLES}" -t "${table}" -F
        "${IP6TABLES}" -t "${table}" -X
        "${IP6TABLES}" -t "${table}" -Z
    done
    unset table
    # Everything on the loopback interface is ok
    "${IP6TABLES}" -A INPUT -i "${LBIF}" -j ACCEPT
    "${IP6TABLES}" -A OUTPUT -o "${LBIF}" -j ACCEPT
    # Link-Local
    "${IP6TABLES}" -A INPUT -s "${LINK_LOCAL}" -j ACCEPT
    "${IP6TABLES}" -A OUTPUT -d "${LINK_LOCAL}" -j ACCEPT
    # IPv6 Multicast
    "${IP6TABLES}" -A INPUT -s "${MULTICAST}" -j ACCEPT
    "${IP6TABLES}" -A OUTPUT -d "${MULTICAST}" -j ACCEPT
    # Rules for localhost external interface
    # Ingress
    for udp in "${INGRESS_UDP6[@]}"
    do
        "${IP6TABLES}" -A INPUT -i "${IPV6_EXTIF}" -p udp -m multiport --dports "${udp}" -j ACCEPT
        "${IP6TABLES}" -A OUTPUT -o "${IPV6_EXTIF}" -p udp -m multiport --sports "${udp}" -j ACCEPT
    done
    unset udp
    for tcp in "${INGRESS_TCP6[@]}"
    do
        "${IP6TABLES}" -A INPUT -i "${IPV6_EXTIF}" -p tcp -m multiport --dports "${tcp}" -j ACCEPT
        "${IP6TABLES}" -A OUTPUT -o "${IPV6_EXTIF}" -p tcp -m multiport --sports "${tcp}" -j ACCEPT
    done
    unset tcp
    for icmpv6 in "${INGRESS_ICMP6[@]}"
    do
        "${IP6TABLES}" -A INPUT -i "${IPV6_EXTIF}" -p icmpv6 --icmpv6-type "${icmpv6}" -j ACCEPT
    done
    unset icmpv6
    # Egress
    for udp in "${EGRESS_UDP6[@]}"
    do
        "${IP6TABLES}" -A OUTPUT -o "${IPV6_EXTIF}" -p udp -m multiport --dports "${udp}" -j ACCEPT
        "${IP6TABLES}" -A INPUT -i "${IPV6_EXTIF}" -p udp -m multiport --sports "${udp}" -j ACCEPT
    done
    unset udp
    for tcp in "${EGRESS_TCP6[@]}"
    do
        "${IP6TABLES}" -A OUTPUT -o "${IPV6_EXTIF}" -p tcp -m multiport --dports "${tcp}" -j ACCEPT
        "${IP6TABLES}" -A INPUT -i "${IPV6_EXTIF}" -p tcp -m multiport --sports "${tcp}" -j ACCEPT
    done
    unset tcp
    for icmpv6 in "${EGRESS_ICMP6[@]}"
    do
        "${IP6TABLES}" -A OUTPUT -o "${IPV6_EXTIF}" -p icmpv6 --icmpv6-type "${icmpv6}" -j ACCEPT
    done
    unset icmpv6
    if [ "${CUSTOM_RULES}" -eq 1 ] && [ -f "${CUSTOM_D}/${FWHOST}_custom_v6.conf" ]
    then
        source "${CUSTOM_D}/${FWHOST}_custom_v6.conf"
    fi
}
ipv4_setup
if [ "${IPV6}" -eq 1 ]
then
    ipv6_setup
fi
# Github
if [ "${GITHUB}" -eq 1 ]
then
    source "${MODULES_D}/github.conf"
    github_v4_allow
fi
# Default IPv4 policy
echo "Default IPv4 filter policy: ${POLICY}"
for chain in INPUT OUTPUT FORWARD
do
    "${IPTABLES}" -P "${chain}" "${POLICY}"
done
unset chain
save
if [ "${IPV6}" -eq 1 ]
then
    # Default policy
    echo "Default IPv6 filter policy: ${POLICY6}"
    for chain in INPUT OUTPUT FORWARD
    do
        "${IP6TABLES}" -P "${chain}" "${POLICY6}"
    done
    unset chain
    ipv6_save
fi
