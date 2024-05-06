########################################################################################################################
# CONFIGURE THE TENANT ID. Get the id with:
# psql -U qradar -c "select id,name,description from tenant ;"
##############################
TENANT_ID="100000"
GREP_INCLUDE="-e ."
GREP_EXCLUDE="-v -e 2099"
##############################
TENANT_DIR=$(find /store/ariel/events/records/aux/$TENANT_ID/ -mindepth 0 -maxdepth 0 -type d -not -wholename "*//*")
[[ -d $TENANT_DIR ]] || exit 5 # do not remove this check
cd $TENANT_DIR || exit 5
ionice -t -c3 nice -n +19 find . -mindepth 2 -maxdepth 2 -type d -not -wholename "*//*" | while read monthdir ; do
 cd $TENANT_DIR
 cd $monthdir || break
 ionice -t -c3 nice -n +19 find . -mindepth 1 -maxdepth 1 -type f -name "*.tar.gz" | grep --color=never $GREP_INCLUDE | grep --color=never $GREP_EXCLUDE | while read archive ; do
    daydir=$(basename $archive | sed -e 's/\.tar\.gz//')
    echo "## $monthdir -> $archive -> $daydir"
	if [[ ! -d $daydir ]]; then
      ionice -t -c3 nice -n +19 tar xzf $archive
      if [[ $? -eq 0 && -d $daydir ]]; then
        echo "cd $TENANT_DIR && cd $monthdir && ionice -t -c3 nice -n +19 rm -f $daydir.tar.gz"
      else
        echo " -- FAILED"
        break
      fi
	else
	  echo "# $daydir exists - skipping"
	fi
 done
done
cd $TENANT_DIR
##############################
