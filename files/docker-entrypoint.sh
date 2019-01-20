#!/bin/sh

function env2cert {
    file=$1
    var="$2"
    (echo "$var" | sed 's/"//g' | grep '^-----' > /dev/null) && 
    (echo "$var" | sed -e 's/"//g' -e 's/\r//g' | sed -e 's/- /-\n/' -e 's/ -/\n-/' | sed -e '2s/ /\n/g' > $file) && 
    echo -n $file || echo -n
}

[ "x$SSL_CERT" != "x" -a ! -f "$SSL_CERT" ] && SSL_CERT=$(env2cert /etc/nginx/default.pem "$SSL_CERT")
[ "x$SSL_KEY" != "x" -a ! -f "$SSL_KEY" ] && SSL_KEY=$(env2cert /etc/nginx/default.key "$SSL_KEY")

#//---------------------------------------------------------------------------
#// Improv security
#//---------------------------------------------------------------------------
# Improv Sec
if [ ! -e /etc/nginx/ssl_sess_ticket.key ] ; then
	openssl rand 48 > /etc/nginx/ssl_sess_ticket.key
fi
if [ ! -e /etc/nginx/dhparam.key ] ; then
    env2cert /etc/nginx/dhparam.key "$SSL_DHPARAM" > /dev/null
    test -f /etc/nginx/dhparam.key || openssl dhparam 2048 > /etc/nginx/dhparam.key 2> /dev/null
fi

#//---------------------------------------------------------------------------
#// generate nginx configuration file
#//---------------------------------------------------------------------------
cd /etc/nginx/conf.d \
&& env FQDN=${FQDN?FQDN} \
    DOCUMENTROOT=${DOCUMENTROOT?DOCUMENTROOT} \
    KUSANAGI_PROVISION=${KUSANAGI_PROVISION?KUSANGI_PROVISION} \
    NO_SSL_REDIRECT=${NO_SSL_REDIRECT:+#} \
    DONOT_USE_FCACHE=${DONOT_USE_FCACHE:-0} \
    EXPIRE_DAYS=${EXPIRE_DAYS:-90} \
    USE_SSL_CT=${USE_SSL_CT:-off} \
    USE_SSL_ST=${USE_SSL_ST:-off} \
    USE_SSL_OSCP=${USE_SSL_OSCP:-off} \
    SSL_CERT=${SSL_CERT:-/etc/nginx/localhost.crt} \
    SSL_KEY=${SSL_KEY:-/etc/nginx/localhost.key} \
    envsubst '$$FQDN $$DOCUMENTROOT $$NO_SSL_REDIRECT $$DONOT_USE_FCACHE
    $$EXPIRE_DAYS $$USE_SSL_CT $$USE_SSL_ST $$USE_SSL_OSCP
    $$SSL_CERT $$SSL_KEY $$OSCP_RESOLV $$KUSANAGI_PROVISION' \
    < default.conf.template > default.conf \
|| exit 1

env PHPHOST=${PHPHOST:-127.0.0.1} envsubst '$$PHPHOST' \
    < fastcgi.inc.template > fastcgi.inc
if [ "$KUSANAGI_PROVISION" == "wp" ] ; then
    env NO_USE_NAXSI=${NO_USE_NAXSI:+#} envsubst '$$NO_USE_NAXSI' \
    < wp.inc.template > wp.inc 
elif  [ "$KUSANAGI_PROVISION" == "lamp" ] ; then
    env NO_USE_NAXSI=${NO_USE_NAXSI:+#} envsubst '$$NO_USE_NAXSI' \
    < lamp.inc.template > lamp.inc 
elif  [ "$KUSANAGI_PROVISION" == "rails" ] ; then
    env ENV_SECRET_KEY_BASE=${ENV_SECRET_KEY_BASE?ENV_SECRET_KEY_BASE} \
    RAILS_ENV=${RAILS_ENV:-development} \
    NO_USE_NAXSI=${NO_USE_NAXSI:+#} \
    envsubst '$$ENV_SECRET_KEY_BASE $$ENV_SECRET_KEY_BASE
    $$RAILS_ENV $$NO_USE_NAXSI' < rails.inc.template > rails.inc \
   || exit 1
fi

#//---------------------------------------------------------------------------
#// create self-signed cert
#//---------------------------------------------------------------------------
if [ -f /etc/nginx/localhost.key -o -f /etc/nginx/localhost.crt ]; then
	/bin/true
else
	/usr/bin/openssl genrsa -rand /proc/cpuinfo:/proc/dma:/proc/filesystems:/proc/interrupts:/proc/ioports:/proc/uptime 2048 > /etc/nginx/localhost.key 2> /dev/null

	cat <<-EOF | /usr/bin/openssl req -new -key /etc/nginx/localhost.key \
		-x509 -sha256 -days 365 -set_serial 1 -extensions v3_req \
		-out /etc/nginx/localhost.crt 2>/dev/null
--
SomeState
SomeCity
SomeOrganization
SomeOrganizationalUnit
${FQDN}
root@${FQDN}
	EOF
fi

echo 127.0.0.1 $FQDN >> /etc/hosts

#//---------------------------------------------------------------------------
#// execute nginx
#//---------------------------------------------------------------------------
exec "$@"
