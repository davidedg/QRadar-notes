#!/usr/bin/env bash

######################################################################
######################################################################
# Syslog packet generator - v20221226
# Author: Davide Del Grande
######################################################################
######################################################################

SYSLOG_SERVER=192.168.0.190
SYSLOG_PORT=514
REALSEND=false # Se to true to actually send the packet on the network
REALSEND=true

MAX_PACKETS=-1 # -1 is infinite
SLEEP=0.144 # 0 for no delay
SLEEP=0.16 # 0 for no delay
SUMMARY_INTERVAL=3

DST_ADDR_POOL="192.168.0.1 192.168.10.254"
SRC_ADDR_POOL="10.10.10.10 10.10.10.10"
LOCAL_PORTS=($(seq 49152 65535))
REMOTE_PORTS=(3389 5900 5901 5902 5903 5904 5905 5800 5801 5802 5803 5804 5805 22)


######################################################################

which prips >/dev/null || (
    echo "PRIPS utility not found!"
    exit 5
)

######################################################################
function __round() {
  printf "%.${2}f" "${1}"
}
function __add() {
    local precision=${3:-2}
    echo $(awk -v summand1="${1}" -v summand2="${2}" -v precision="${precision}" 'BEGIN {fmt="%."precision"f"; printf fmt, summand1+summand2; exit(0)}') #'
}
function __sub() {
    local precision=${3:-2}
    echo $(awk -v minuend="${1}" -v subtrahend="${2}" -v precision="${precision}" 'BEGIN {fmt="%."precision"f"; printf fmt, minuend-subtrahend; exit(0)}') #'
}
function __mul() {
    local precision=${3:-2}
    echo $(awk -v factor1="${1}" -v factor2="${2}" -v precision="${precision}" 'BEGIN {fmt="%."precision"f"; printf fmt, factor1*factor2; exit(0)}') #'
}
function __div() {
    local precision=${3:-2}
    echo $(awk -v dividend="${1}" -v divisor="${2}" -v precision="${precision}" 'BEGIN {fmt="%."precision"f"; printf fmt, dividend/divisor; exit(0)}') #'
}

######################################################################



######################################################################
# kill children on exit/interrupt
function exitf() {
    echo
    print_summary
    trap - SIGTERM && kill -- -$$
}
trap exitf SIGINT SIGTERM EXIT


######################################################################
######################################################################

# fill wth src/dst IP addresses, in random order, also shuffles remote ports
DSTADDRESSES=$(prips -e ...0,255 $DST_ADDR_POOL | shuf)
DSTADDRESSES=( $DSTADDRESSES ) ## bash splits on expansion
DSTADDRESSES_LEN=${#DSTADDRESSES[@]}

SRCADDRESSES=$(prips -e ...0,255 $SRC_ADDR_POOL | shuf)
SRCADDRESSES=( $SRCADDRESSES ) ## bash splits on expansion
SRCADDRESSES_LEN=${#SRCADDRESSES[@]}

REMOTE_PORTS=( $(shuf -e "${REMOTE_PORTS[@]}") )
REMOTEPORTS_LEN=${#REMOTE_PORTS[@]}

LOCAL_PORTS=( $(shuf -e "${LOCAL_PORTS[@]}") )
LOCALPORTS_LEN=${#LOCAL_PORTS[@]}



######################################################################
function print_summary() {
    [[ $counter -le 0 ]] && exit

    if [[ "$SLEEP" != "0" ]]; then
        elapsed_end=$(date +%s.%6N)
        elapsed=$(__sub $elapsed_end $elapsed_start 5)
        pps=$(__div $counter $elapsed)
        pph=$(__mul $pps 3600 0)
    fi

    echo "######################################################################"
    echo ">>>>> count=${counter} | ${pps}/sec [${pps_expected}/sec] | ${pph}/hour [${pph_expected}/hour] | target=$pph_delta"
    echo "######################################################################"
}


###########################################
# Calibration
###########################################

## Here we calibrate the expected delay due to overheads
##  using the same type of instructions used later during the while cycle
## Then we use this calculated delay as the new sleep value

if [[ "$SLEEP" != "0" ]]; then
    echo "Calibrating..."
    counter=0
    calibrated_start=$(date +%s.%6N)
    for i in {1..100}
    do
        [[ 1 -ge 2 && 0 -ne -1 ]] && break
        r_DSTADDRslot=$((counter % DSTADDRESSES_LEN))
        r_DSTADDR="${DSTADDRESSES[$DSTADDRslot]}"
        r_SRCADDRslot=$((counter % SRCADDRESSES_LEN))
        r_SRCADDR="${SRCADDRESSES[$SRCADDRslot]}"
        r_RPORTslot=$((counter % REMOTEPORTS_LEN))
        r_RPORT="${REMOTE_PORTS[$RPORTslot]}"
        r_LPORTslot=$((counter % LOCALPORTS_LEN))
        r_LPORT="${LOCAL_PORTS[$LPORTslot]}"

        r_SYSLOGPKT="$(date +"%b %d %H:%M:%S") xxxxxxxxxxxx[$((10000+RANDOM%89999))]: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

        echo "${r_SYSLOGPKT}" > /dev/null

        counter=$((counter+1-1))
        r_elapsed_end=$(date +%s.%6N)
        r_elapsed=$(__sub $r_elapsed_end $r_elapsed_start 5)
        r_pps=$(__div $counter $r_elapsed)
        r_pph=$(__mul $pps 3600 0)
        r_pph_delta=$(__div $r_pph $r_pph_expected 5)
        r_pph_delta=$(__sub $r_pph_delta 1 5)
        r_sleep_adjusted=$(__mul $sleep_calibrated $pph_delta 5)
        sleep 0.01
    done

    calibrated_end=$(date +%s.%6N)
    calibrated_elapsed=$(__sub $calibrated_end $calibrated_start 6)
    calibrated_delay=$(__div $calibrated_elapsed 100 5)
    sleep_calibrated=$(__sub $SLEEP $calibrated_delay 5)
    if [[ ${sleep_calibrated::1} == "-" ]]; then
        echo "Calculated Delay is too high for requested PPS goal"
        exit
    fi
    echo "Calibrated Delay: $calibrated_delay - original sleep value: $SLEEP - new sleep value: $sleep_calibrated"
else
    sleep_calibrated=0
    calibrated_delay=0
fi



###########################################
# generate fake traffic syslog events
###########################################

counter=0
elapsed=0
elapsed_start=$(date +%s.%6N)
elapsed_end=$elapsed_start

if [[ "$SLEEP" != "0" ]]; then
    pps_expected=$(__div 1 $SLEEP 2)
    pph_expected=$(__div 3600 $SLEEP 0)
    pps=$pps_expected
    pph=$pph_expected
    update_summary_interval=$(__mul $pps_expected $SUMMARY_INTERVAL 0)
else
    pps_expected="MAX"
    pph_expected="MAX"
    pps=0
    pph=0
    update_summary_interval=200
fi



echo "Generating packets..."
while true; do
    [[ $counter -ge $MAX_PACKETS && $MAX_PACKETS -ne -1 ]] && break
    DSTADDRslot=$((counter % DSTADDRESSES_LEN))
    DSTADDR="${DSTADDRESSES[$DSTADDRslot]}"
    SRCADDRslot=$((counter % SRCADDRESSES_LEN))
    SRCADDR="${SRCADDRESSES[$SRCADDRslot]}"
    RPORTslot=$((counter % REMOTEPORTS_LEN))
    RPORT="${REMOTE_PORTS[$RPORTslot]}"
    LPORTslot=$((counter % LOCALPORTS_LEN))
    LPORT="${LOCAL_PORTS[$LPORTslot]}"



    ## QRADAR: Excessive Firewall Denies Across Multiple Hosts From A Local Host containing Firewall - Deny
#    SYSLOGPKT="<134>$(date +"%b %d %H:%M:%S") filterlog[$((10000+RANDOM%89999))]: 255,,,0,vtnet0,match,block,in,4,0x0,,64,0,0,DF,6,tcp,100,$SRCADDR,$DSTADDR,$LPORT,$RPORT,80"

    ## QRADAR: Firewall Permit
    SYSLOGPKT="<134>$(date +"%b %d %H:%M:%S") filterlog[$((10000+RANDOM%89999))]: 255,,,0,vtnet0,match,pass,in,4,0x0,,64,0,0,DF,6,tcp,52,$SRCADDR,$DSTADDR,$LPORT,$RPORT,0,S,2172974099,,64240,,mss;nop;wscale;nop;nop;sackOK"

    $REALSEND && echo "$SYSLOGPKT" > /dev/udp/$SYSLOG_SERVER/$SYSLOG_PORT
    printf "${SYSLOGPKT}\n"


    counter=$((counter+1))
    if [[ "$SLEEP" != "0" ]]; then
        elapsed_end=$(date +%s.%6N)
        elapsed=$(__sub $elapsed_end $elapsed_start 5)
        pps=$(__div $counter $elapsed)
        pph=$(__mul $pps 3600 0)

        ## Adjust sleep timings, aiming at pph=pph_expected
        if [[ $counter -gt 10 ]]; then # start stats only after 10 rounds
            pph_delta=$(__div $pph $pph_expected 5)
        else
            pph_delta=1
        fi

        sleep_adjusted=$(__mul $sleep_calibrated $pph_delta 5)

        if [[ $counter -lt $MAX_PACKETS || $MAX_PACKETS -eq -1 ]]; then
            sleep $sleep_adjusted
        fi
    fi

    [[ $((counter % update_summary_interval)) -eq 0 ]] && print_summary

done

# PFSENSE RAW FILTER LOG FORMAT: REF: https://docs.netgate.com/pfsense/en/latest/monitoring/logs/raw-filter-format.html
