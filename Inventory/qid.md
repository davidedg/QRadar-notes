
Extract all QIDs together with the Content Pack from where they were installed:

    read -r -d '' Q << 'EOF'
    SELECT
     cl.localization_value AS extension,
     cp.version,
     cp.content_status,
     q.id AS qid_id,
     q.qid,
     q.qname
    FROM qidmap q
    LEFT OUTER JOIN content_manifest cm ON (q.qname = cm.identifier AND cm.content_type=27) 
    LEFT OUTER JOIN content_package cp ON (cm.content_package = cp.id)
    LEFT OUTER JOIN content_localization cl ON (cl.content_package = cp.id AND cl.localization_key='extension.name')
    ORDER BY extension, q.qid
    EOF
    
    psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-qid_with_extension.csv


Extract all QIDs only if they were installed by an Extension/Content Pack:

    read -r -d '' Q << 'EOF'
    SELECT
     cl.localization_value AS extension,
     cp.version,
     cp.content_status,
     q.id AS qid_id,
     q.qid,
     q.qname
    FROM qidmap q
    INNER JOIN content_manifest cm ON (q.qname = cm.identifier AND cm.content_type=27) 
    INNER JOIN content_package cp ON (cm.content_package = cp.id)
    INNER JOIN content_localization cl ON (cl.content_package = cp.id AND cl.localization_key='extension.name')
    ORDER BY extension, q.qid
    EOF
    
    psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-qid_extensions_only.csv

