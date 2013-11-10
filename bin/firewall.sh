#!/bin/bash
#
# firewall.sh
#
# Configuration directories
CONF_D="/opt/pizon.org/firewall/etc"
# Load master configuration file
source "${CONF_D}/firewall.conf"
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
# Type of firewall being configured
case "${FWTYPE}" in
    standalone)
    ;;
    gateway)
    ;;
esac
# Firewall modules
# localhost rules
source "${MODULES_D}/localhost.conf"
source "${LIBEXEC}/localhost.sh"
localhost_setup
# IPv6
if [ "${IPV6}" -eq 1 ]
then
    source "${MODULES_D}/ipv6.conf"
    source "${LIBEXEC}/ipv6.sh"
    ipv6_backup
    ipv6_setup
fi
# Monitoring
if [ -f "${MODULES_D}/monitoring.conf" ]
then
    echo "Applying exceptions for monitoring from ${MODULES_D}/monitoring.conf"
    source "${MODULES_D}/monitoring.conf"
fi
# Monit
if [ -f "${MODULES_D}/monit.conf" ]
then
    source "${MODULES_D}/monit.conf"
    local_monit
fi
# OSSEC
if [ "${OSSEC}" -eq 1 ] && [ -f "${MODULES_D}/ossec.conf" ]
then
    source "${MODULES_D}/ossec.conf"
    ossec_setup
fi
# Syslog and netconsole
if [ "${SYSLOG}" -eq 1 ]
then
    source "${MODULES_D}/syslog_server.conf"
    syslog_server
fi
# IPSEC
if [ "${IPSEC}" -eq 1 ]
then
    source "${MODULES_D}/ipsec.conf"
    ipsec_setup
fi
# Squid Proxy
if [ "${SQUID}" -eq 1 ]
then
    echo "Enabling squid proxy access"
    source "${MODULES_D}/squid-proxy.conf"
    squid_setup
fi
# QoS
if [ "${QOS}" -eq 1 ] && [ -e "${MODULES_D/qos.conf}" ]
then
    source "${MODULES_D}/qos.conf"
    source "${LIBEXEC}/qos.sh"
    # Set up QoS policies
    qos_setup
    ipv4_qos
    if [ "${IPV6}" -eq 1 ]
    then
        ipv6_qos
    fi
fi
# VLANs
if [ "${VLAN}" -eq 1 ]
then
    echo "Applying VLAN rules"
    for vlan in ${VLAN_D}/*.conf
    do
        source "${LIBEXEC}/vlan.sh"
        source "${vlan}"
        create_vlan
    done
    unset vlan
    if [ "${IPV6}" -eq 1 ]
    then
        for vlan6 in ${VLAN_D}/*.conf
        do
            source "${vlan6}"
            create_vlan6
        done
        unset vlan6
    fi
fi
# VServer
if [ "${VSERVER}" -eq 1 ]
then
    for vserver in ${VSERVER_D}/*.conf
    do
        echo "Applying virtual server rules from ${vserver}"
        source "${vserver}"
    done
fi
# RADIUS
if [ "${RADIUS}" -eq 1 ]
then
    echo "Applying RADIUS server rules"
    source "${MODULES_D}/radius.conf"
    radius_server
fi
# PS3
if [ "${PS3}" -eq 1 ]
then
    echo "Enabling Playstation 3 rules"
    source "${MODULES_D}/playstation3.conf"
    ps3
fi
# Github
if [ "${GITHUB}" -eq 1 ]
then
    echo "Allow outbound access to Github"
    source "${MODULES_D}/github.conf"
    github_v4_allow
fi
# NFS Servers
if [ "${NFS_SERVER}" -eq 1 ]
then
    echo "Allowing access to NFS servers"
    source "${MODULES_D}/nfs_server.conf"
    nfs_server
    if [ "${IPV6}" -eq 1 ]
    then
        ipv6_nfs_server
    fi
fi
# Custom rules
if [ "${CUSTOM_RULES}" -eq 1 ]
then
    for custom in ${CUSTOM_D}/*.conf
    do
        echo "Applying custom rules from ${custom}"
        source "${custom}"
    done
    unset custom
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
