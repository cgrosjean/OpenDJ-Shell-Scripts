#!/bin/sh
if [ $# -ne 2 ] ;
 then
 echo "Usage: $0 output_file M, where M is the number of entries to create (in millions)"
 echo "Example: $0 outfile 10 to generate a 10 millions entries template"
 exit 1
fi

if [ ! -f ./env.properties ] ;
 then
 echo ./env.properties file missing, exiting ..
 exit 2
else
 source ./env.properties
fi

echo "
define suffix=$BASE_DN
define maildomain=$BASE_DN
define numusers=$2"000000"

branch: [suffix]

branch: ou=People,[suffix]
subordinateTemplate: person:[numusers]

template: person
rdnAttr: uid
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
givenName: <first>
sn: <last>
cn: {givenName} {sn}
initials: {givenName:1}<random:chars:ABCDEFGHIJKLMNOPQRSTUVWXYZ:1>{sn:1}
employeeNumber: <sequential:0>
uid: user.{employeeNumber}
mail: {uid}@[maildomain]
userPassword: password
telephoneNumber: <random:telephone>
homePhone: <random:telephone>
pager: <random:telephone>
mobile: <random:telephone>
street: <random:numeric:5> <file:streets> Street
l: <file:cities>
st: <file:states>
postalCode: <random:numeric:5>
postalAddress: {cn}${street}${l}, {st}  {postalCode}
description: This is the description for {cn}.
" >$1
