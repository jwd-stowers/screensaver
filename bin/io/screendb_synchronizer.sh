# run bin/orchestra/ss-build first!
#
# run this proggie something like this:
#
# bsub /home/js163/screensaver/bin/screendbsynchronizer.sh
#
# TODO: improve placement of output and error files:
#   - some place secure?
#   - put a timestamp or something in the filenames so they dont overwrite
#   - check for existence of files before overwriting?

SCREENSAVER=`dirname $0`/../..
cd $SCREENSAVER
SCREENSAVER=`pwd -P`

LIBS=`for s in $SCREENSAVER/lib/*.jar ; do printf ":$s" ; done`
CLASSPATH="$SCREENSAVER/classes$LIBS"
JAVA=/opt/java/jdk1.5/bin/java

$JAVA -Xmx1500m -cp $CLASSPATH edu.harvard.med.screensaver.db.screendb.OrchestraStandaloneScreenDBSynchronizer -S pgsql.cl.med.harvard.edu -D screendb -U $USER 2>&1 | tee screendb_synchronizer.out

echo screendb_synchronizer.sh is complete
echo program output is in $SCREENSAVER/screendb_synchronizer.out
