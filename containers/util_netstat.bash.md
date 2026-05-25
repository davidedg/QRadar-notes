        
```        
cat > netstat.bash << 'EOF'
#!/bin/bash

printf "%-20s %-10s %-10s\n" "Local Address" "Port" "State"

while read -r line; do
    # salta l'header
    [[ "$line" =~ local_address ]] && continue

    local_hex=$(echo "$line" | awk '{print $2}')
    state_hex=$(echo "$line" | awk '{print $4}')

    ip_hex=${local_hex%:*}
    port_hex=${local_hex#*:}

    # converti IP hex → dotted
    ip=$(printf "%d.%d.%d.%d" \
        0x${ip_hex:6:2} \
        0x${ip_hex:4:2} \
        0x${ip_hex:2:2} \
        0x${ip_hex:0:2})

    # converti porta hex → decimale
    port=$((16#$port_hex))

    # stato 0A = LISTEN
    if [[ "$state_hex" == "0A" ]]; then
        printf "%-20s %-10s %-10s\n" "$ip" "$port" "LISTEN"
    fi

done < /proc/net/tcp
EOF
```
