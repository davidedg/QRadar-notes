Extract all rules together with Extensions

    read -r -d '' Q << 'EOF'
    SELECT
     cr.uuid,
     cr.id,
     CASE WHEN cl.localization_value <> '' THEN cl.localization_value ELSE cp.name END AS extension,
     cm.content_type,
     cp.content_status,
     cp.version,
     cr.crname AS rule_name,
     cr.enabled,
     cr.bb, 
     cr.rule_type,
     cr.origin,
     cr.link_uuid,
     cr.create_date,
     cr.mod_date,
     cr.average_capacity,
     EXTRACT(epoch FROM to_timestamp(cr.capacity_timestamp / 1000)) / 86400 + 25569 AS capacity_timestamp_ef, -- Excel datetime Format
     cr.base_host_id,
     cr.flags,
     cr.rule_data
    FROM
    ( SELECT *,
       array_to_string(REGEXP_MATCHES(convert_from(crx.rule_data, 'UTF8'), '><name>(.*)</name><notes>'), '') AS crname,
       CASE WHEN (
        crx.rule_data LIKE '% enabled="true" %'
     ) THEN TRUE ELSE FALSE END AS enabled, 
     CASE WHEN (
       crx.rule_data LIKE '% buildingBlock="true" %'
     ) THEN TRUE ELSE FALSE END AS bb
    FROM custom_rule crx) cr
    LEFT OUTER JOIN content_manifest cm ON (cr.uuid = cm.identifier AND cm.content_type=3)
    LEFT OUTER JOIN content_package cp ON (cm.content_package = cp.id)
    LEFT OUTER JOIN content_localization cl ON (cl.content_package = cp.id AND cl.localization_key='extension.name')
    ORDER BY extension, cr.bb, cr.crname
    EOF

    psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-rules_with_extension.csv
