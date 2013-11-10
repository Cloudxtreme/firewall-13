#!/bin/bash
# ipv6.sh
function ipv6_setup {
    # Load IPv6 configuration
    source "${MODULES_D}/ipv6.conf"
    # Allow 6to4 tunneling
    "${IPTABLES}" -A INPUT -i "${EXTIF}" -p 41 -j ACCEPT
    "${IPTABLES}" -A OUTPUT -o "${EXTIF}" -p 41 -j ACCEPT
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
    # Inbound and Outbound state policies
    echo "INGRESS IPv6 TCP connection state policy: ${IN_STATE6}"
    "${IP6TABLES}" -A INPUT -i "${IPV6_EXTIF}" -p tcp -m state --state "${IN_STATE6}" -j ACCEPT
    echo "EGRESS IPv6 TCP connection state policy: ${OUT_STATE}"
    "${IP6TABLES}" -A OUTPUT -o "${IPV6_EXTIF}" -p tcp -m state --state "${OUT_STATE6}" -j ACCEPT
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
    done
    unset tcp
    for icmpv6 in "${INGRESS_ICMP6[@]}"
    do
        "${IP6TABLES}" -A INPUT -p icmpv6 --icmpv6-type "${icmpv6}" -j ACCEPT
        "${IP6TABLES}" -A FORWARD -p icmpv6 --icmpv6-type "${icmpv6}" -j ACCEPT
    done
    unset icmpv6
    # Egress
    for udp in "${EGRESS_UDP6[@]}"
    do
        "${IP6TABLES}" -A OUTPUT -o "${IPV6_EXTIF}" -p udp -m multiport --dports "${udp}" -j ACCEPT
        "${IP6TABLES}" -I INPUT -i "${IPV6_EXTIF}" -p udp -m multiport --sports "${udp}" -j ACCEPT
    done
    unset udp
    for tcp in "${EGRESS_TCP6[@]}"
    do
        "${IP6TABLES}" -A OUTPUT -o "${IPV6_EXTIF}" -p tcp -m multiport --dports "${tcp}" -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    done
    unset tcp
    for icmpv6 in "${EGRESS_ICMP6[@]}"
    do
        "${IP6TABLES}" -A OUTPUT -p icmpv6 --icmpv6-type "${icmpv6}" -j ACCEPT
    done
    unset icmpv6
    # ICMP and UDP Traceroute
    "${IP6TABLES}" -A INPUT -p icmpv6 --icmpv6-type 11 -i "${IPV6_EXTIF}" -j ACCEPT
    "${IP6TABLES}" -A INPUT -p udp --sport 33434:33523 -i "${IPV6_EXTIF}" -j ACCEPT
    "${IP6TABLES}" -A OUTPUT -p icmpv6 --icmpv6-type 11 -o "${IPV6_EXTIF}" -j ACCEPT
    "${IP6TABLES}" -A OUTPUT -p udp --dport 33434:33523 -o "${IPV6_EXTIF}" -j ACCEPT
}
