# Find QRadar Postgres tables containing a particular string

Search for a string (in this example, the Sysmon package id) in the database directory:

    SEARCHSTRING="e41e758e2ab5786173438cd09219a9d0"

Search in all postgres db tables files.
For each match:
- get the table name from its oid.
- exclude huge tables.
- dump the table contents in extended format, grepping for the search string

        POSTGRES_DATA_GREP_RES=$(grep -R "$SEARCHSTRING" /store/postgres/)
        echo "$POSTGRES_DATA_GREP_RES" | grep "Binary file /store/postgres/data/base/" | cut -d/ -f7 | cut -d' ' -f1 | xargs -L1 echo | while read -r tableoid ; do
          tablename=$(psql -U qradar -t -A -c "SELECT pg_filenode_relation(0, $tableoid);")
          [[ $tablename == pg_* ]] && continue
          [[ $tablename == public_* ]] && continue
          [[ $tablename == *cvss* ]] && continue
          [[ $tablename == *vuln* ]] && continue
          [[ $tablename == qidmap ]] && continue
    
          echo "###### $tablename($tableoid) ######"
          psql -U qradar -xc "SELECT * from $tablename;" | grep -v -e " RECORD.*$SEARCHSTRING" | grep -A10 -B10 "$SEARCHSTRING"
          echo "########################################"
        done
