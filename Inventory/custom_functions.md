List Custom Functions with Content Packs:

	read -r -d '' Q << 'EOF'
	SELECT
	CASE WHEN cl.localization_value <> '' THEN cl.localization_value ELSE cp.name END AS extension,
	cp.version AS cp_ver,
	cp.content_status AS cp_status,
	cf.id AS cf_id,
	cf.namespace AS cf_ns,
	cf.name AS cf_name,
	cf.execute_function_name AS cf_fname
	FROM custom_function cf
	LEFT OUTER JOIN content_manifest cm ON (cf.name = cm.identifier ) 
	LEFT OUTER JOIN content_package cp ON (cm.content_package = cp.id)
	LEFT OUTER JOIN content_localization cl ON (cl.content_package = cp.id AND cl.localization_key='extension.name')
	EOF
	 
	psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-customfunctions_with_extension.csv
