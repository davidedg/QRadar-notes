#!/bin/bash

######################################################################
######################################################################
# Syslog packet generator - v0.1-20221222.001
# Emulation for: PFSense firewall denies over multiple src/dst
# Author: Davide Del Grande
######################################################################
######################################################################

SYSLOG_SERVER=192.168.0.190
SYSLOG_PORT=514
MAX_PACKETS=-1 # -1 is infinite
SLEEP=0.144
DST_ADDR_POOL="192.168.0.1 192.168.10.254"
SRC_ADDR_POOL="10.10.10.10 10.10.10.10"
LOCAL_PORTS=($(seq 49152 65535))
REMOTE_PORTS=(3389 5900 5901 5902 5903 5904 5905 5800 5801 5802 5803 5804 5805 22)

######################################################################
# kill children (tail/netcat) on exit
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

_self="${0##*/}"
FIFO=~/${_self}.fifo
######################################################################


which prips >/dev/null || (
    echo "PRIPS utility not found!"
    exit 5
)

which stdbuf >/dev/null || (
    echo "STDBUF utility not found!"
    exit 5
)

which netcat >/dev/null || (
    echo "NETCAT utility not found!"
    exit 5
)


######################################################################
######################################################################

echo "Creating listening FIFO tunneled to $SYSLOG_SERVER:$SYSLOG_PORT"
if [[ ! -p $FIFO ]]; then
    mkfifo -m 600 $FIFO || exit 10
fi
tail -f $FIFO | stdbuf -i0 -o0 netcat $SYSLOG_SERVER $SYSLOG_PORT &

######################################################################
######################################################################

# fill wth src/dst IP addresses, in random order, also shuffles remote ports
DSTADDRESSES=$(prips $DST_ADDR_POOL -e ...0,255 | shuf)
DSTADDRESSES=( $DSTADDRESSES ) ## bash splits on expansion
DSTADDRESSES_LEN=${#DSTADDRESSES[@]}

SRCADDRESSES=$(prips $SRC_ADDR_POOL -e ...0,255 | shuf)
SRCADDRESSES=( $SRCADDRESSES ) ## bash splits on expansion
SRCADDRESSES_LEN=${#SRCADDRESSES[@]}

REMOTE_PORTS=( $(shuf -e "${REMOTE_PORTS[@]}") )
REMOTEPORTS_LEN=${#REMOTE_PORTS[@]}

LOCAL_PORTS=( $(shuf -e "${LOCAL_PORTS[@]}") )
LOCALPORTS_LEN=${#LOCAL_PORTS[@]}


###########################################
# generate fake traffic syslog events
###########################################

counter=-1
while true; do
    counter=$((counter+1))
    if [[ $counter -lt $MAX_PACKETS || $MAX_PACKETS -eq -1  ]]; then
        DSTADDRslot=$((counter % DSTADDRESSES_LEN))
        DSTADDR="${DSTADDRESSES[$DSTADDRslot]}"
        SRCADDRslot=$((counter % SRCADDRESSES_LEN))
        SRCADDR="${SRCADDRESSES[$SRCADDRslot]}"
        RPORTslot=$((counter % REMOTEPORTS_LEN))
        RPORT="${REMOTE_PORTS[$RPORTslot]}"
        LPORTslot=$((counter % LOCALPORTS_LEN))
        LPORT="${LOCAL_PORTS[$LPORTslot]}"

        SYSLOGPKT="<134>$(date +"%b %d %H:%M:%S") filterlog[22362]: 255,,,0,vtnet0,match,block,in,4,0x0,,64,0,0,DF,17,tcp,100,$SRCADDR,$DSTADDR,$LPORT,$RPORT,80"
        printf '%-6s' "$counter"
        printf "${SYSLOGPKT}\n"

#        echo "$SYSLOGPKT" > $FIFO
    else
        break
    fi
    sleep $SLEEP
done

