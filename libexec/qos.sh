#!/bin/bash
# qos.sh
#
function qos_setup {
    # Reset existing QoS rules
    if [ "$(${TC} qdisc show dev ${EXTIF} | grep '^qdisc htb' | awk '{ print $1" "$2 }')" == "qdisc htb" ]
    then
	"${TC}" qdisc del dev "${EXTIF}" root
    fi
    "${IP}" link set dev "${EXTIF}" qlen 30
    # Add HTB root qdisc
    "${TC}" qdisc add dev "${EXTIF}" root handle 1: htb default "${DEFAULT_PRI}" r2q "${R2Q}"
    # Set default rate
    if [ "${CIR}" != "" ] && [ "${MIR}" != "" ]
    then
        "${TC}" class add dev "${EXTIF}" parent 1: classid 1:1 htb rate "${CIR}kbit" burst "${MIR}kbit"
    else
        echo "Upload rate not defined.  Can not continue."
        exit 1
    fi
    # "leaf" classes for each priority
    echo "Minimum upload rate set to ${MINRATE} kbps"
    "${TC}" class add dev "${EXTIF}" parent 1:1 classid 1:10 htb rate "${MINRATE}kbit" ceil "${MIR}kbit" prio 0
    "${TC}" class add dev "${EXTIF}" parent 1:1 classid 1:20 htb rate "${MINRATE}kbit" ceil "${MIR}kbit" prio 1
    "${TC}" class add dev "${EXTIF}" parent 1:1 classid 1:30 htb rate "${MINRATE}kbit" ceil "${MIR}kbit" prio 2
    "${TC}" class add dev "${EXTIF}" parent 1:1 classid 1:40 htb rate "${MINRATE}kbit" ceil "${MIR}kbit" prio 3
    "${TC}" class add dev "${EXTIF}" parent 1:1 classid 1:50 htb rate "${MINRATE}kbit" ceil "${MIR}kbit" prio 4
    "${TC}" class add dev "${EXTIF}" parent 1:1 classid 1:60 htb rate "${MINRATE}kbit" ceil "${MIR}kbit" prio 5
    "${TC}" class add dev "${EXTIF}" parent 1:1 classid 1:70 htb rate "${MINRATE}kbit" ceil "${MIR}kbit" prio 6
    "${TC}" class add dev "${EXTIF}" parent 1:1 classid 1:80 htb rate "${MINRATE}kbit" ceil "${MIR}kbit" prio 7
    "${TC}" class add dev "${EXTIF}" parent 1:1 classid 1:90 htb rate "${MINRATE}kbit" ceil "${MIR}kbit" prio 8
    "${TC}" class add dev "${EXTIF}" parent 1:1 classid 1:100 htb rate "${MINRATE}kbit" ceil "${MIR}kbit" prio 9
    # attach qdisc to leaf classes
    "${TC}" qdisc add dev "${EXTIF}" parent 1:10 handle 10: sfq perturb 10
    "${TC}" qdisc add dev "${EXTIF}" parent 1:20 handle 20: sfq perturb 10
    "${TC}" qdisc add dev "${EXTIF}" parent 1:30 handle 30: sfq perturb 10
    "${TC}" qdisc add dev "${EXTIF}" parent 1:40 handle 40: sfq perturb 10
    "${TC}" qdisc add dev "${EXTIF}" parent 1:50 handle 50: sfq perturb 10
    "${TC}" qdisc add dev "${EXTIF}" parent 1:60 handle 60: sfq perturb 10
    "${TC}" qdisc add dev "${EXTIF}" parent 1:70 handle 70: sfq perturb 10
    "${TC}" qdisc add dev "${EXTIF}" parent 1:80 handle 80: sfq perturb 10
    "${TC}" qdisc add dev "${EXTIF}" parent 1:90 handle 90: sfq perturb 10
    "${TC}" qdisc add dev "${EXTIF}" parent 1:100 handle 100: sfq perturb 10
    # # TOS Minimum Delay (ssh, NOT scp) in 1:10:
    tc filter add dev "${EXTIF}" parent 1:0 protocol ip prio 10 u32 match ip tos 0x10 0xff  flowid 1:10
    # ICMP (ip protocol 1) in the interactive class 1:10 so we
    # can do measurements & impress our friends:
    tc filter add dev "${EXTIF}" parent 1:0 protocol ip prio 10 u32 match ip protocol 1 0xff flowid 1:10
    # To speed up downloads while an upload is going on, put ACK packets in
    # the interactive class:
    tc filter add dev "${EXTIF}" parent 1: protocol ip prio 10 u32 match ip protocol 6 0xff match u8 0x05 0x0f at 0 match u16 0x0000 0xffc0 at 2 match u8 0x10 0xff at 33 flowid 1:10
}
# IPv4
function ipv4_qos {
    # Filter traffic based on MARKs
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ip handle 10 fw flowid 1:10
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ip handle 20 fw flowid 1:20
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ip handle 30 fw flowid 1:30
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ip handle 40 fw flowid 1:40
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ip handle 50 fw flowid 1:50
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ip handle 60 fw flowid 1:60
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ip handle 70 fw flowid 1:70
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ip handle 80 fw flowid 1:80
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ip handle 90 fw flowid 1:90
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ip handle 100 fw flowid 1:100
}
# IPv6
function ipv6_qos {
    # Filter traffic based on MARKs
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ipv6 handle 10 fw flowid 1:10
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ipv6 handle 20 fw flowid 1:20
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ipv6 handle 30 fw flowid 1:30
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ipv6 handle 40 fw flowid 1:40
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ipv6 handle 50 fw flowid 1:50
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ipv6 handle 60 fw flowid 1:60
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ipv6 handle 70 fw flowid 1:70
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ipv6 handle 80 fw flowid 1:80
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ipv6 handle 90 fw flowid 1:90
    "${TC}" filter add dev "${EXTIF}" parent 1:0 prio 0 protocol ipv6 handle 100 fw flowid 1:100
}
