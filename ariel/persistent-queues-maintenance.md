

"RESYNCH ONLY"
 
    systemctl stop ecs-ec-ingress
    sleep 2
    sync
    systemctl status ecs-ec-ingress
    ls -lnrt /store/persistent_queue/ecs-ec-ingress.ecs-ec-ingress/ | grep -i '\.dat' | sort -t'_' -nk7 | sed -n '1p;$p' | awk '{if (NR == 1) {print "3"; print $9;  print $5}; if (NR == 2){print $9; print "99999999999999"; print $5; print "true"}}' | sed -r 's/^.*ecs-ec-ingress.*Parse_([0-9]+).dat/\1/' > /store/persistent_queue/ecs-ec-ingress.ecs-ec-ingress/ecs-ec-ingress_EC_Ingress_TCP_TO_ECParse.cfg
    systemctl start ecs-ec-ingress
 
 
"ZAP/DELETE"
 
    systemctl stop ecs-ec-ingress
    rm -f /store/persistent_queue/ecs-ec-ingress.ecs-ec-ingress/*.dat
    ls -lnrt /store/persistent_queue/ecs-ec-ingress.ecs-ec-ingress/ | grep -i '\.dat' | sort -t'_' -nk7 | sed -n '1p;$p' | awk '{if (NR == 1) {print "3"; print $9;  print $5}; if (NR == 2){print $9; print "99999999999999"; print $5; print "true"}}' | sed -r 's/^.*ecs-ec-ingress.*Parse_([0-9]+).dat/\1/' > /store/persistent_queue/ecs-ec-ingress.ecs-ec-ingress/ecs-ec-ingress_EC_Ingress_TCP_TO_ECParse.cfg
    systemctl start ecs-ec-ingress ecs-ec


