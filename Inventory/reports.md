Extract all Reports along with the Content Pack they were installed with:

	# Extract metadata from reports xml files
	# and prepare a SQLVALUES string to join it with the data in the postgres db
	xpath_title="/java/object/void[@property='title']/string"
	xpath_author="java/object/void[@property='author']"
	xpath_owner="java/object/void[@property='owner']"
	SQLVALUES=""
	for reportxmlfile in /store/reporting/templates/*.xml ; do
	  title=$(  xml sel --noblanks -t -v "$xpath_title"  "$reportxmlfile")
	  author=$( xml sel --noblanks -t -v "$xpath_author" "$reportxmlfile")
	  owner=$(  xml sel --noblanks -t -v "$xpath_owner"  "$reportxmlfile")
	  reportid=$(basename "$reportxmlfile" ".xml")
	  SQLVALUE="('$reportid','$author','$owner','$title'),"
	  SQLVALUES+="$SQLVALUE"$'\n'
	done
	SQLVALUES=$(echo -e "$SQLVALUES" | sed '/^$/d') # remove extra new line
	SQLVALUES=$(sed '$s/,$//' <<< "$SQLVALUES") # remove last comma
	#
	IFS='' read -d '' -r Q <<EOF
	WITH vtable AS ( SELECT * FROM ( VALUES
	$SQLVALUES
	) AS t(reportid,author,owner,title) )
	SELECT
	  CASE WHEN cl.localization_value <> '' THEN cl.localization_value ELSE cp.name END AS extension,
	  COALESCE(cp.version, NULL) as version,
	  COALESCE(cp.content_status, NULL) as content_status,
	  vtable.reportid AS reportid,
	  vtable.author AS author,
	  vtable.owner AS owner,
	  vtable.title AS title  
	FROM
	  vtable
	LEFT JOIN content_manifest cm ON (cm.content_type=10 AND cm.identifier=vtable.reportid)
	LEFT JOIN content_package cp ON (cm.content_package = cp.id)
	LEFT JOIN content_localization cl ON (cl.content_package = cp.id AND cl.localization_key='extension.name')
	EOF

	psql -U qradar -c "Copy ( $Q ) TO STDOUT WITH CSV HEADER DELIMITER ',';" > $HOSTNAME-Reports_with_extension.csv
