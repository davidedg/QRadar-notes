
Search for a string (in this example, the Sysmon package id) in the database directory:

    cd /store/postgres
    grep -iR e41e758e2ab5786173438cd09219a9d0 *

    Binary file data/pg_wal/0000000100000006000000EE matches
    Binary file data/base/22677095/22677379 matches
    Binary file data/pg_stat_tmp/pgss_query_texts.stat matches

Now get the relation name from the filename:

    psql -U qradar -t -A -c "SELECT pg_filenode_relation(0, 22677379);"
    content_package

Now explore the structure:

    psql -U qradar -xc "SELECT * from content_package;" | grep -A10 -B10 "e41e758e2ab5786173438cd09219a9d0"
