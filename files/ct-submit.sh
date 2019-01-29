#!
# /usr/bin/ct-submit.sh [SSL path]
# used certbot-auto renew --renew-hook /usr/bin/ct-submit.sh

SSLPATH=${1:-RENEWED_LINEAGE}

if [ -z "$SSLPATH" ] ; then
	exit 1
fi

if [ -d "$SSLPATH" -a -f "$SSLPATH/fullchain.pem" ] ; then
	SSLFILE="$SSLPATH/fullchain.pem"
else
	SSLFILE=$SSLPATH
	SSLPATH=${SSLFILE%/*}
fi

SUCCESS=
if [ -d $SSLPATH ] ; then
	[ -d "$SSLPATH/scts" ] || mkdir -p "$SSLPATH/scts" || exit 1
	for i in pilot rocketeer icarus skydiver
	do
		/usr/bin/ct-submit ct.googleapis.com/$i < ${SSLFILE} > ${SSLPATH}/scts/${i}.sct 2> /dev/null
		if [ $? -eq 0 ] ; then
			echo "Register to ct.googleapis.com/$i"
			SUCCESS=1
		else
			echo "Cannot Register to ct.googleapis.com/$i"
			[ -f ${SSLPATH}/scts/${i}.sct ] && rm ${SSLPATH}/scts/${i}.sct
		fi
	done
fi

[ -z "$SUCCESS" ] && exit 1
exit 0
