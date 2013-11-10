#!/bin/bash
# vlan.sh
# IPv4
function create_vlan {
    echo "${CHAIN}"
    "${IPTABLES}" -t nat -A POSTROUTING -o "${EXTIF}" -s "${VLAN_NET}" -j MASQUERADE --random
    # Create new chain
    "${IPTABLES}" -N "${CHAIN}"
    # Default Policy
    "${IPTABLES}" -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -s "${VLAN_NET}" -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
    "${IPTABLES}" -A "${CHAIN}" -o "${VLAN_IF}" -i "${EXTIF}" -d "${VLAN_NET}" -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
    # Egress
    # UDP
    for udp in "${VLAN_UDP_OUT[@]}"
    do
        "${IPTABLES}" -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -s "${VLAN_NET}" -p udp -m multiport --dports "${udp}" -j ACCEPT
        "${IPTABLES}" -A "${CHAIN}" -o "${VLAN_IF}" -i "${EXTIF}" -d "${VLAN_NET}" -p udp -m multiport --sports "${udp}" -j ACCEPT
    done
    unset udp
    # TCP
    for tcp in "${VLAN_TCP_OUT[@]}"
    do
        "${IPTABLES}" -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -s "${VLAN_NET}" -p tcp -m multiport --dports "${tcp}" -m state --state NEW -j ACCEPT
    done
    unset tcp
    # ICMP
    for icmp in "${VLAN_ICMP_OUT[@]}"
    do
        "${IPTABLES}" -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -s "${VLAN_NET}" -p icmp --icmp-type "${icmp}" -j ACCEPT
    done
    unset icmp
    # Ingress
    # UDP
    for udp in "${VLAN_UDP_OUT[@]}"
    do
        "${IPTABLES}" -A "${CHAIN}" -o "${VLAN_IF}" -i "${EXTIF}" -d "${VLAN_NET}" -p udp -m multiport --dports "${udp}" -j ACCEPT
        "${IPTABLES}" -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -s "${VLAN_NET}" -p udp -m multiport --sports "${udp}" -j ACCEPT
    done
    unset udp
    # TCP
    for tcp in "${VLAN_TCP_IN[@]}"
    do
        "${IPTABLES}" -A "${CHAIN}" -o "${VLAN_IF}" -i "${EXTIF}" -d "${VLAN_NET}" -p tcp -m multiport --dports "${tcp}" -m state --state NEW -j ACCEPT
    done
    unset tcp
    # ICMP
    for icmp in "${VLAN_ICMP_IN[@]}"
    do
        "${IPTABLES}" -A "${CHAIN}" -o "${VLAN_IF}" -i "${EXTIF}" -d "${VLAN_NET}" -p icmp --icmp-type "${icmp}" -j ACCEPT
    done
    unset icmp
    # QoS
    if [ "${QOS}" -eq 1 ]
    then
        "${IPTABLES}" -t mangle -N "${CHAIN}"
	"${IPTABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -m tcp -p tcp --sport 0:1024 -j MARK --set-mark "${DEFAULT_PRI}"
        "${IPTABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -m tcp -p tcp --dport 0:1024 -j MARK --set-mark "${DEFAULT_PRI}"
        "${IPTABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -m udp -p udp --sport 0:1024 -j MARK --set-mark "${DEFAULT_PRI}"
        "${IPTABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -m udp -p udp --dport 0:1024 -j MARK --set-mark "${DEFAULT_PRI}"
        # ICMP
        "${IPTABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -p icmp -j MARK --set-mark "${ICMP_PRI}"
        # Small packets
        "${IPTABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -m tcp -p tcp -m length --length :64 -j MARK --set-mark "${SMALL_PKT_PRI}"
	"${IPTABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -m udp -p udp -m length --length :64 -j MARK --set-mark "${SMALL_PKT_PRI}"
        # Return
        "${IPTABLES}" -t mangle -A "${CHAIN}" -j RETURN
    fi
    # Return to the default FORWARD chain
    "${IPTABLES}" -A "${CHAIN}" -j RETURN
    # Append VLAN chain to the FORWARD table
    "${IPTABLES}" -A FORWARD -j "${CHAIN}"
    # Unset variables
    unset CHAIN VLAN_IF VLAN_NET VLAN_UDP_IN VLAN_UDP_OUT VLAN_ICMP_IN VLAN_ICMP_OUT VLAN_TCP_IN VLAN_TCP_OUT
}
# IPv6
function create_vlan6 {
    # Create new chain
    "${IP6TABLES}" -N "${CHAIN}"
    # Default Policy
    "${IP6TABLES}" -A "${CHAIN}" -i "${VLAN_IF}" -o "${IPV6_EXTIF}" -s "${VLAN_NET6}" -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
    "${IP6TABLES}" -A "${CHAIN}" -o "${VLAN_IF}" -i "${IPV6_EXTIF}" -d "${VLAN_NET6}" -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
    # DNS
    for server in "${IPV6_DNS[@]}"
    do
        "${IP6TABLES}" -A "${CHAIN}" -i "${VLAN_IF}" -d "${server}" -p udp --dport 53 -j ACCEPT
        "${IP6TABLES}" -A "${CHAIN}" -o "${VLAN_IF}" -s "${server}" -p udp --sport 53 -j ACCEPT
    done
    unset server
    # Egress
    # UDP
    for udp in "${VLAN_UDP_OUT[@]}"
    do
        "${IP6TABLES}" -A "${CHAIN}" -i "${VLAN_IF}" -o "${IPV6_EXTIF}" -s "${VLAN_NET6}" -p udp -m multiport --dports "${udp}" -j ACCEPT
        "${IP6TABLES}" -A "${CHAIN}" -o "${VLAN_IF}" -s "${VLAN_NET6}" -p udp -m multiport --sports "${udp}" -j ACCEPT
    done
    unset udp
    # TCP
    for tcp in "${VLAN_TCP_OUT[@]}"
    do
        "${IP6TABLES}" -A "${CHAIN}" -i "${VLAN_IF}" -o "${IPV6_EXTIF}" -s "${VLAN_NET6}" -p tcp -m multiport --dports "${tcp}" -m state --state NEW -j ACCEPT
    done
    unset tcp
    # Ingress
    # UDP
    for udp in "${VLAN_UDP_IN[@]}"
    do
        "${IP6TABLES}" -A "${CHAIN}" -o "${VLAN_IF}" -d "${VLAN_NET6}" -p udp -m multiport --dports "${udp}" -j ACCEPT
        "${IP6TABLES}" -A "${CHAIN}" -i "${VLAN_IF}" -s "${VLAN_NET6}" -p udp -m multiport --sports "${udp}" -j ACCEPT
    done
    unset udp
    # TCP
    for tcp in "${VLAN_TCP_IN[@]}"
    do
        "${IP6TABLES}" -A "${CHAIN}" -o "${VLAN_IF}" -i "${IPV6_EXTIF}" -d "${VLAN_NET6}" -p tcp -m multiport --dports "${tcp}" -m state --state NEW -j ACCEPT
    done
    unset tcp
    # QoS
    if [ "${QOS}" -eq 1 ]
    then
        "${IP6TABLES}" -t mangle -N "${CHAIN}"
	"${IP6TABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -m tcp -p tcp --sport 0:1024 -j MARK --set-mark "${DEFAULT_PRI}"
        "${IP6TABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -m tcp -p tcp --dport 0:1024 -j MARK --set-mark "${DEFAULT_PRI}"
        "${IP6TABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -m udp -p udp --sport 0:1024 -j MARK --set-mark "${DEFAULT_PRI}"
        "${IP6TABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -m udp -p udp --dport 0:1024 -j MARK --set-mark "${DEFAULT_PRI}"
        # ICMP
        "${IP6TABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -p icmp -j MARK --set-mark "${ICMP_PRI}"
        # Small packets
        "${IP6TABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -m tcp -p tcp -m length --length :64 -j MARK --set-mark "${SMALL_PKT_PRI}"
	"${IP6TABLES}" -t mangle -A "${CHAIN}" -i "${VLAN_IF}" -o "${EXTIF}" -m udp -p udp -m length --length :64 -j MARK --set-mark "${SMALL_PKT_PRI}"
        # Return
        "${IP6TABLES}" -t mangle -A "${CHAIN}" -j RETURN
    fi
    # Link Local
    "${IP6TABLES}" -A "${CHAIN}" -i "${VLAN_IF}" -s "${LINK_LOCAL}" -j ACCEPT
    "${IP6TABLES}" -A "${CHAIN}" -o "${VLAN_IF}" -s "${LINK_LOCAL}" -j ACCEPT
    # Multicast
    "${IP6TABLES}" -A "${CHAIN}" -i "${VLAN_IF}" -s "${MULTICAST}" -j ACCEPT
    "${IP6TABLES}" -A "${CHAIN}" -o "${VLAN_IF}" -s "${MULTICAST}" -j ACCEPT
    # Return to the default FORWARD chain
    "${IP6TABLES}" -A "${CHAIN}" -j RETURN
    # Append VLAN chain to the FORWARD table
    "${IP6TABLES}" -A FORWARD -j "${CHAIN}"
    # Unset variables
    unset CHAIN VLAN_IF VLAN_NET6 VLAN_UDP_IN VLAN_UDP_OUT VLAN_ICMP6_IN VLAN_ICMP6_OUT VLAN_TCP_IN VLAN_TCP_OUT
}
