Extract Reference Data objects with the Extensions they are coming from:

    read -r -d '' Q << 'EOF'
    SELECT
      rd.id AS rdid,
      rd.uuid AS rduuid,
      CASE WHEN cl.localization_value <> '' THEN cl.localization_value ELSE cp.name END AS extension,
      rd.name AS refdata_name,
      cp.content_status AS cp_status,
      cp.version AS cp_ver, 
      CASE
        WHEN rd.collection_type=0 THEN '0-RefSet'
        WHEN rd.collection_type=1 THEN '1-RefMap'
        WHEN rd.collection_type=2 THEN '2-RefMapSets'
        WHEN rd.collection_type=3 THEN '3-RefTable'
        ELSE rd.collection_type::TEXT
      END AS rd_type, 
      CASE
        WHEN rd.element_type=0 THEN '0-AlphaNumeric'
        WHEN rd.element_type=1 THEN '1-Numeric'
        WHEN rd.element_type=2 THEN '2-IP'
        WHEN rd.element_type=3 THEN '3-Port'
        WHEN rd.element_type=4 THEN '4-AlphaNumericIgnoreCase'
        ELSE rd.element_type::TEXT
      END AS e_type,
      EXTRACT(epoch FROM to_timestamp(rd.created_time / 1000)) / 86400 + 25569 AS created_time_ef, -- Excel datetime Format
      rd.timeout_type,
      rd.time_to_live,
      rd.current_count,
      rd.key1_label,
      rd.value_label,
      rd.is_table,
      rd.bulk_update_timestamp,
      rd.tenant_info,
      rd.log_separately,
      rd.description
    FROM
      reference_data rd
      LEFT OUTER JOIN content_manifest cm ON (cm.content_type=28 AND rd.name = cm.identifier)
      LEFT OUTER JOIN content_package cp ON (cm.content_package = cp.id)
      LEFT OUTER JOIN content_localization cl ON (cl.content_package = cp.id AND cl.localization_key='extension.name')
      ORDER BY rd.name, extension
    EOF
     
    psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-refdata_with_extensions_$(date +"%Y-%m-%d_%H%M%z").csv

\
Extract Reference Data Elements:

    read -r -d '' Q << 'EOF'
    
    SELECT
      rde.id AS EId,
      rd.name AS refdata_name,
      rd.collection_type AS rd_type,
      rd.element_type AS e_type,
      rde.data AS data,
      rde.source AS source,
      rde.first_seen AS firstseen,
      rde.last_seen AS lastseen,
      CASE
        WHEN rdk.domain_info = 2147483647 THEN '00-Shareddata'
        WHEN rdk.domain_info = 0 THEN '0-DefaultDomain'
        ELSE d.name
      END AS domain
    FROM
      reference_data rd,
      reference_data_key rdk
        LEFT JOIN domains d ON rdk.domain_info = d.id,
      reference_data_element rde
    WHERE
        rd.id = rdk.rd_id
    AND rdk.id = rde.rdk_id
    EOF
     
    psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-refdata_elements_$(date +"%Y-%m-%d_%H%M%z").csv
