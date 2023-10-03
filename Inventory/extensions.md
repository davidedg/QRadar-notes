Get all apps and content packs:

    read -r -d '' Q << 'EOF'
    SELECT DISTINCT
      CASE WHEN cl.localization_value <> '' THEN cl.localization_value ELSE cp.name END AS extension,
      cp.version,
      to_timestamp(cp.install_time / 1000)::date AS install_time,
      to_timestamp(cp.uninstall_time / 1000)::date AS uninstall_time,
      to_timestamp(cp.add_time / 1000)::date AS add_time,
      to_timestamp(cp.modification_time / 1000)::date AS modification_time
    FROM
      content_manifest cm
      LEFT OUTER JOIN content_package cp ON (cm.content_package = cp.id)
      LEFT OUTER JOIN content_localization cl ON (cl.content_package = cp.id AND cl.localization_key='extension.name')
    WHERE cp.content_status <> 6
    ORDER BY extension
    EOF

    psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-extensions.csv
