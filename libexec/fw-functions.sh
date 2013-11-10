# Firewall functions
BACKUPDIR="/opt/pizon.org/firewall/var/backups"
BACKUPEXT="$(date +%F-%T)"
if [ ! -d "${BACKUPDIR}" ]
then
    mkdir -p "${BACKUPDIR}"
fi
function backup {
    echo "Backing up IPv4 rules to ${BACKUPDIR}/iptables.${BACKUPEXT}"
    "${IPTABLES}" -S > "${BACKUPDIR}/iptables.${BACKUPEXT}"
}

function ipv6_backup {
    echo "Backing up IPv6 rules to ${BACKUPDIR}/ip6tables.${BACKUPEXT}"
    "${IP6TABLES}" -S > "${BACKUPDIR}/ip6tables.${BACKUPEXT}"
}

function save {
    if [ -e "/etc/redhat-release" ]
    then
        IPTABLES_SAVE="/etc/sysconfig/iptables"
    elif [ -e "/etc/lsb-release" ]
    then
        IPTABLES_SAVE="/etc/default/iptables"
    else
        IPTABLES_SAVE="/var/cache/iptables"
    fi
    echo "Saving IPv4 rules and counters to ${IPTABLES_SAVE}"
    "${IPTABLES}-save" -c > "${IPTABLES_SAVE}"
}

function ipv6_save {
    if [ -e "/etc/redhat-release" ]
    then
        IP6TABLES_SAVE="/etc/sysconfig/ip6tables"
    elif [ -e "/etc/lsb-release" ]
    then
        IP6TABLES_SAVE="/etc/default/ip6tables"
    else
        IP6TABLES_SAVE="/var/cache/ip6tables"
    fi
    echo "Saving IPv6 rules and counters to ${IP6TABLES_SAVE}"
    "${IP6TABLES}-save" -c > "${IP6TABLES_SAVE}"
}
