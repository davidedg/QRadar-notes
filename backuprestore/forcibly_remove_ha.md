# Forcibly remove HA (when QRadar GUI won't let you)

**!!! DISCLAIMER !!!**
------------------------
Needless to say, this is just for **lab environments** - use at your own risk !!!
------------------------



- Login to QRadar, press F12 to open DevTools, go to Application -> Storage -> Cookies.
- Grab values of JSESSIONID and QRadarCSRF, do not logout.

- Identify the id of the host to be deleted:

`psql -U qradar -c "SELECT id,ip,hostname,status,appliancetype FROM managedhost ORDER BY hostname;"`

- Remove HA (fill in values for QRadarCSRF, JSESSIONID and HOSTID):
  
      QRadarCSRF="..."
      JSESSIONID="..."
      HOSTID="70"
      curl -sk \
        -b "JSESSIONID=$JSESSIONID; QRadarCSRF=$QRadarCSRF" \
        -X POST \
        -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
        --data-urlencode "{method:\"QRadar.removeHost\",params:{hostId:\"$HOSTID\"},QRadarCSRF:\"$QRadarCSRF\",id:\"1\"}" \
        "https://localhost/console/JSON-RPC/QRadar.removeHost"

- The output should be similar to:

      {"id":"1","result":[{"hostIp":null,"text":"HA has been removed from host 192.168.0.190.","valid":true,"confirmText":null,"licenseId":null,"errorText":null}],"error":null}

- Now it should be possible to remove the remaining (non-HA) host using the GUI.
