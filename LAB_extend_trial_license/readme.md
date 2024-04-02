# Trial license extension

Quick and dirty way to extend trial license for lab use

\
**!!! DISCLAIMER !!!**
------------------------
Needless to say, this is just for **lab environments** - use at your own risk !!!
------------------------
\
Export current license data into a csv file:

	mkdir license
	cd license
	psql -U qradar -c "\COPY (SELECT * FROM license_key) TO 'license_key_original.csv'  WITH DELIMITER ';' CSV HEADER;"

\
Extract the current expiration date and extend it:

    OLD_EXPIRATION_DAY=$(cat license_key_original.csv | grep -i "Expiration=" | head -n1 | sed -e "s/.*=\([0-9]\{8\}\).*/\1/g")
    NEW_EXPIRATION_DAY=$(date -d "$OLD_EXPIRATION_DAY +10 days" +'%Y%m%d')
    cat license_key_original.csv | sed -e "s/^\(.*xpiration=\)\($OLD_EXPIRATION_DAY\)/\1$NEW_EXPIRATION_DAY/g" > license_key_extended.csv

\
Verify extended license:

    diff license_key_original.csv license_key_extended.csv

\
If everything looks good, update the license:

    echo "
    CREATE temporary TABLE license_key_extended AS SELECT * FROM license_key LIMIT  0;

    \COPY license_key_extended FROM 'license_key_extended.csv' with DELIMITER ';' CSV HEADER; 

    UPDATE license_key
      SET    license_deployed = t.license_deployed, license_staging = t.license_staging
      FROM   license_key_extended AS t
      WHERE  license_key.id = t.id;
    " | psql -U qradar

\
Now do a full deploy (cmdline or gui):

	/opt/qradar/upgrade/util/setup/upgrades/do_deploy.pl
