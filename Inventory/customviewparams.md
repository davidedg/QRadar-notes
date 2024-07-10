List Custom Views with Content Packs:

	read -r -d '' Q << 'EOF'
	SELECT
	  CASE WHEN cl.localization_value <> '' THEN cl.localization_value ELSE cp.name END AS extension,
	  cp.version,
	  cm.content_type,
	  cp.content_status,
	  cvp.id,cvp.cv_id,cvp.itemname,cvp.database,cvp.username,cvp.refcount,cvp.shared,cvp.itemname_id,cvp.queryparams
	FROM
	  customviewparams cvp
	  LEFT OUTER JOIN content_manifest cm ON (cvp.itemname = cm.identifier )
	  LEFT OUTER JOIN content_package cp ON (cm.content_package = cp.id)
	  LEFT OUTER JOIN content_localization cl ON (cl.content_package = cp.id AND cl.localization_key='extension.name')
	  ORDER BY extension, cvp.itemname
	EOF
	 
	psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-customviewparams.csv
