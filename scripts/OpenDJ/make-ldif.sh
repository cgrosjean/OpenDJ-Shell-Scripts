#!/bin/sh
if [ ! -f ./env.properties ] ; then
 echo ./env.properties file missing, exiting ..
 exit 1
else
 source ./env.properties
fi

if [ $# -ne 2 ] ;
 then
 echo "Usage: $0 output_file M, where M is the number of entries to create (in millions)"
 echo "Example: $0 outfile 10 to generate a 10 millions entries LDIF file"
 exit 2
fi

# create LDIF file
./generate-template.sh "$1" $2
sudo su - opendj -c "LANG=C && $INSTALL_DIR/bin/make-ldif --ldifFile $IMPORT_FILE --randomSeed 1 --templateFile \"$1\" >/dev/null"
sudo chmod +r $IMPORT_FILE
