# localhost.sh
# Localhost rules
function localhost_setup {
    # Back up IPv4 rules
    backup
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
        "${IPTABLES}" -t "${table}" -Z
        "${IPTABLES}" -t "${table}" -F
        "${IPTABLES}" -t "${table}" -X
    done
    unset table
    # Inbound and Outbound state policies
    echo "INGRESS IPv4 TCP connection state policy: ${IN_STATE}"
    "${IPTABLES}" -A INPUT -i "${EXTIF}" -p tcp -m state --state "${IN_STATE}" -j ACCEPT
    echo "EGRESS IPv4 TCP connection state policy: ${OUT_STATE}"
    "${IPTABLES}" -A OUTPUT -o "${EXTIF}" -p tcp -m state --state "${OUT_STATE}" -j ACCEPT
    # Everything on the loopback interface is ok
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
        "${IPTABLES}" -A INPUT -i "${EXTIF}" -p tcp -m multiport --dports "${tcp}" -m state --state NEW -j ACCEPT
    done
    unset tcp
    for icmp in "${INGRESS_ICMP[@]}"
    do
        "${IPTABLES}" -A INPUT -i "${EXTIF}" -p icmp --icmp-type "${icmp}" -j ACCEPT
        "${IPTABLES}" -A INPUT -i eth1+ -p icmp --icmp-type "${icmp}" -j ACCEPT
    done
    unset icmp
    # Egress
    for udp in "${EGRESS_UDP[@]}"
    do
        "${IPTABLES}" -A OUTPUT -o "${EXTIF}" -p udp -m multiport --dports "${udp}" -j ACCEPT
        "${IPTABLES}" -I INPUT -i "${EXTIF}" -p udp -m multiport --sports "${udp}" -j ACCEPT
    done
    unset udp
    for tcp in "${EGRESS_TCP[@]}"
    do
        "${IPTABLES}" -A OUTPUT -o "${EXTIF}" -p tcp -m multiport --dports "${tcp}" -m state --state NEW -j ACCEPT
    done
    unset tcp
    for icmp in "${EGRESS_ICMP[@]}"
    do
        "${IPTABLES}" -A OUTPUT -o "${EXTIF}" -p icmp --icmp-type "${icmp}" -j ACCEPT
        "${IPTABLES}" -A OUTPUT -o eth1+ -p icmp --icmp-type "${icmp}" -j ACCEPT
    done
    unset icmp
    # Allow ICMP and UDP traceroute
    if [ "${TRACEROUTE}" -eq 1 ]
    then
        "${IPTABLES}" -A INPUT -p icmp --icmp-type 11 -i "${EXTIF}" -j ACCEPT
        "${IPTABLES}" -A INPUT -p udp --sport 33434:33523 -i "${EXTIF}" -j ACCEPT
        "${IPTABLES}" -A OUTPUT -p icmp --icmp-type 11 -o "${EXTIF}" -j ACCEPT
        "${IPTABLES}" -A OUTPUT -p udp --dport 33434:33523 -o "${EXTIF}" -j ACCEPT
    fi
}
