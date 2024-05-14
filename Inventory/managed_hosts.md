


    echo "
    SELECT
    mh.id AS mhid,
    mh.hostname AS mh,
    mh.ip AS ip,
    dc.id AS dcid,
    dc.name AS dc
    FROM
    deployed_component dc
    LEFT OUTER JOIN managedhost mh ON (mh.id = dc.managed_host_id)
    WHERE
    dc.name like 'event%'
    ORDER BY mh.id,dc.name ;
    " | psql -U qradar

