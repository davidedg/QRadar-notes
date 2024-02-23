# Run the low-level geoipupdate tool to test downloading to a temp directory:
/usr/bin/geoipupdate -v -f /opt/qradar/conf/GeoIP.conf -d /storetmp

# Get saved credentials
MAXMIND_USER=$(grep -e ^UserId /opt/qradar/conf/GeoIP.conf | cut -d' ' -f2)
MAXMIND_PWD=$(grep -e ^LicenseKey /opt/qradar/conf/GeoIP.conf | cut -d' ' -f2 | java -jar /opt/qradar/jars/ibm-si-mks.jar decrypt_command_line)

# Test with cURL, optionally with http proxy
curl -u "$MAXMIND_USER:$MAXMIND_PWD" --proxy "https://proxy.local:3128" "https://updates.maxmind.com/app/update_getfilename?product_id=GeoLite2-City"
curl -o /storetmp/geodatadownload.gz -u "$MAXMIND_USER:$MAXMIND_PWD" --proxy "https://proxy.local:3128" "https://updates.maxmind.com/geoip/databases/GeoLite2-City/update?db_md5=00000000000000000000000000000000"
