########################################################################################################################
# CONFIGURE THE TENANT ID. Get the id with:
# psql -U qradar -c "select id,name,description from tenant ;"
##############################
TENANT_ID="100000"
GREP_INCLUDE='-e .'
GREP_EXCLUDE='-v -e 2099/'
##############################
TENANT_DIR=$(find /store/ariel/events/records/aux/$TENANT_ID/ -mindepth 0 -maxdepth 0 -type d -not -wholename "*//*")
[[ -d $TENANT_DIR ]] || exit 5 # do not remove this check
cd $TENANT_DIR || exit 5
find . -mindepth 3 -maxdepth 3 -type d -not -wholename "*//*" | grep --color=never $GREP_INCLUDE | grep --color=never $GREP_EXCLUDE | while read -r datadir ; do
  parentdir=$(dirname $datadir)
  daydir=$(basename $datadir)
  archive=$daydir.tar.gz
  echo "## $datadir -> $parentdir/$archive"
 
  cd $TENANT_DIR
  cd $parentdir || break
  
  tar czf $archive $daydir
  if [[ $? -eq 0 && -f $archive ]]; then
	  echo "cd $TENANT_DIR && rm -rf $datadir"
  else
    echo " -- FAILED"
	break
  fi
done
