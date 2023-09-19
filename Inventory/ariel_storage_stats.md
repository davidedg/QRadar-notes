Misc Ariel Storage stats
--------------------------

Day-by-Day storage usage (last 30 days) - Single Tenant:

    for ((d=1;d<=30;d++)); do
    ionice -t -c3 nice -n +19 find /store/ariel/{events,flows}/{records,payloads}/{aux/*,}/$(date --date "-$d day" +"%Y/%-m/%-d") -maxdepth 0 -print0 2>/dev/null | du -xsc -BM --files0-from=- | grep total | cut -dt -f1|xargs -0 printf "$HOSTNAME;$(date --date "-$d day" +"%Y/%-m/%-d");%s"| sed -e 's/M\t$//'
    done


Day-by-Day storage usage (last 30 days) - Multi-Tenant:

    ionice -t -c3 nice -n +19 find /store/ariel/{events,flows}/{records,payloads}/aux/* -type d -maxdepth 0 2>/dev/null | sed -e "s:/store/ariel/.*/\(.*\)$:\1:g" | sort -u | xargs -L1 echo | while read -r TID ; do
    for ((d=1;d<=30;d++)); do
      ionice -t -c3 nice -n +19 find /store/ariel/{events,flows}/{records,payloads}/aux/$TID/$(date --date "-$d day" +"%Y/%-m/%-d") -maxdepth 0 -print0 2>/dev/null | du -xsc -BM --files0-from=- | grep total | cut -dt -f1|xargs -0 printf "$HOSTNAME;$TID;$(date --date "-$d day" +"%Y/%-m/%-d");%s"| sed -e 's/M\t$//'
      done
    done


Bucket Usage - Single Tenant:

    for B in {0..9}; do
      echo "####################################################################" | tee -a store-usage-global.log
      echo "B=$B" | tee -a store-usage-global.log
      ionice -t -c3 nice -n +19 find /store/ariel/events/*/2* -type f -name "*~$B" -print0 | du -xsch --files0-from=- | grep total | tee -a store-usage-global.log
    done


Bucket Usage - Multi-Tenant:

    for d in /store/ariel/events/records/aux/* ; do
      T=${d##*/}
      for B in {0..9}; do
        Z=$((256 * T + B))
        echo "####################################################################" | tee -a store-usage-tenants.log
        echo "T=$T B=$B - Z=$Z" | tee -a store-usage-tenants.log
        ionice -t -c3 nice -n +19 find /store/ariel/events/*/aux/$T/ -type f -name "*~$Z" -print0 | du -xsch --files0-from=- | grep total | tee -a store-usage-tenants.log
      done
    done


Includes Global Views:

    for ((d=1;d<=30;d++)); do
      ionice -t -c3 nice -n +19 find /store/ariel/{events,flows,gv,statistics}/{records,payloads,}/{aux/*,GV*,}/$(date --date "-$d day" +"%Y/%-m/%-d") -maxdepth 0 -print0 2>/dev/null | du -xsch --files0-from=- | grep total | cut -dt -f1|xargs -0 printf "$d;%s"
    done


