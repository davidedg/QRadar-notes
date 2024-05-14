#!/bin/bash

SCRIPTDIR=$(readlink -f $(dirname -- "$0"))
cd $SCRIPTDIR || exit 5

psql -U qradar -c "\COPY (SELECT * FROM license_key) TO 'license_key_current.csv'  WITH DELIMITER ';' CSV HEADER;"

cat license_key_current.csv | while read -r inputline ; do
	license_pattern="expiration.*=2"
    [[ ${inputline,,} =~ $license_pattern ]]
    if [[ $? -eq 0 ]]; then
      CURRENT=$( echo "$inputline" | sed -e "s/.*=\([0-9]\{8\}\).*/\1/g" )
      NEW=$(date -d "$CURRENT +7 days" +'%Y%m%d')
	  inputline=${inputline/$CURRENT/$NEW}
	fi
	printf "%s\n" "$inputline"
done > license_key_new.csv


echo "
CREATE temporary TABLE license_key_extended AS SELECT * FROM license_key LIMIT  0;

\COPY license_key_extended FROM 'license_key_new.csv' with DELIMITER ';' CSV HEADER;

UPDATE license_key
  SET    license_deployed = t.license_deployed, license_staging = t.license_staging
  FROM   license_key_extended AS t
  WHERE  license_key.id = t.id;
" | psql -U qradar


/opt/qradar/upgrade/util/setup/upgrades/do_deploy.pl
