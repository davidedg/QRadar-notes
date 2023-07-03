# QRadar: Recover Authorized Service Tokens (from postgres db)

Run the following commands:

    psql -U qradar -t -c "select sessiontoken, servicename from authorized_service;" | sed -e 's/^ //' | xargs -L1 echo | while read -r line ; do
    token_desc=$(echo "$line" |cut -d'|' -f2 | tr -d [:space:] )
    token_enc=$(echo "$line" |cut -d'|' -f1 | tr -d [:space:] )
    token=$(java -jar /opt/qradar/jars/ibm-si-mks.jar decrypt $token_enc)
    printf "%s <--> %s\n" "$token" "$token_desc"
    done


In QRadar 7.5 U5+:

    psql -U qradar -t -c "select sessiontoken, servicename from authorized_service;" | sed -e 's/^ //' | xargs -L1 echo | while read -r line ; do
    token_desc=$(echo "$line" |cut -d'|' -f2 | tr -d [:space:] )
    token_enc=$(echo "$line" |cut -d'|' -f1 | tr -d [:space:] )
    token=$(echo $token_enc | java -jar /opt/qradar/jars/ibm-si-mks.jar decrypt_command_line)
    printf "%s <--> %s\n" "$token" "$token_desc"
    done

