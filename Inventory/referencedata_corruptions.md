# Spot potentially corrupted reference data

    psql -U qradar -t -c "SELECT SUM(current_count) AS count FROM reference_data;"
    psql -U qradar -t -c "SELECT SUM(count) AS count FROM reference_data_count;"
    psql -U qradar -t -c "SELECT COUNT(id) AS count FROM reference_data_element;"

\
If numbers are not equal, it may be due to legacy or corrupted ref data.
\
Generally, you'd want to trust data from the reference_data_element table, as this is the actual content.
\
Dig deeper:

Group counts from **reference_data**:

    read -r -d '' Q << 'EOF'
    SELECT name AS refdata_name, SUM(current_count) AS count FROM reference_data GROUP BY refdata_name ORDER BY refdata_name
    EOF
    psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-refdatacount_rd_$(date +"%Y-%m-%d_%H%M%z").csv

Group counts from **reference_data_count**:

    read -r -d '' Q << 'EOF'
    SELECT
      rd.name AS refdata_name,
      SUM(rdc.count) AS count
    FROM
      reference_data_count rdc
        LEFT JOIN reference_data rd ON rd.id = rdc.rd_id
    GROUP BY refdata_name ORDER BY refdata_name
    EOF
    
    psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-refdatacount_rdc_$(date +"%Y-%m-%d_%H%M%z").csv

Group counts from **reference_data_element**:

    read -r -d '' Q << 'EOF'
    SELECT
      rd.name AS refdata_name,
      COUNT(rde.id) AS count
    FROM
      reference_data rd,
      reference_data_key rdk
        LEFT JOIN domains d ON rdk.domain_info = d.id,
      reference_data_element rde
    WHERE
        rd.id = rdk.rd_id
    AND rdk.id = rde.rdk_id
    GROUP BY refdata_name
    ORDER BY refdata_name
    EOF
    
    psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-refdatacount_rde_$(date +"%Y-%m-%d_%H%M%z").csv

