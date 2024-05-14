
Event Collectors/Processors:

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


List MHs for Processors:

    SELECT DISTINCT
    mh.ip,
    mh.hostname,
    mh.isconsole,
    mh.appliancetype
    FROM
    managedhost mh,
    serverhost s,
    managedhostcapabilityxref mhcap,
    component c
    WHERE
         mh.status = 'Active'
    AND mh.id = s.managed_host_id
    AND s.status != '14'
    AND mhcap.managedhostid = mh.id
    AND mhcap.componentid = c.id
    AND c.type = 'eventprocessor'
    ORDER BY
    mh.appliancetype ;
    
