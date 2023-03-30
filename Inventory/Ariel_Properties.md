Extract all Ariel Properties together with the Content Pack from where they were installed:


    read -r -d '' Q << 'EOF'
    SELECT
      cl.localization_value AS extension,
      cm.content_type,
      cp.content_status,
      ap.expressionid,
      ap.propertyid,
      ap.propertyname,
      ap.enabled,
      ap.deprecated,
      ap.forceparse,
      ap.description,
      ap.expressiontype,
      ap.patternstring,
      ap.capturegroup,
      ap.expression,
      ap.propertytype,
      ap.database,
      ap.qid,
      ap.devicetypeid,
      ap.devicetypedescription,
      ap.deviceid,
      ap.devicename,
      ap.category,
      ap.propertybase,
      EXTRACT(epoch FROM to_timestamp(ap.creationdate / 1000)) / 86400 + 25569 AS creationdate_ef, -- Excel datetime Format
      EXTRACT(epoch FROM to_timestamp(ap.editdate / 1000)) / 86400 + 25569 AS editdate_ef, -- Excel datetime Format
      ap.username,
      -- less useful fields
      ap.description_id,
      ap.languagetag,
      ap.datepattern,
      ap.sequenceid,
      ap.expressionsequenceid,
      ap.tenant_id,
      ap.regex,
      ap.delimiter,
      ap.delimiter_pair,
      ap.delimiter_name_value
    FROM ariel_property_view ap
    LEFT OUTER JOIN content_manifest cm ON (ap.expressionid = cm.identifier )
    LEFT OUTER JOIN content_package cp ON (cm.content_package = cp.id)
    LEFT OUTER JOIN content_localization cl ON (cl.content_package = cp.id AND cl.localization_key='extension.name')
    ORDER BY extension, ap.propertyname
    EOF

    psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-ArielProps_with_extension.csv
