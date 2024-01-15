#!/bin/sh

export PATH=/usr/local/bin:/bin:/usr/bin:/usr/sbin

function env2cert {
    file=$1
    var="$2"
    (echo "$var" | sed 's/"//g' | grep '^-----' > /dev/null) && 
    (echo "$var" | sed -e 's/"//g' -e 's/\r//g' | sed -e 's/- /-\n/g' -e 's/ -/\n-/g' | sed -e '2s/ /\n/g' > $file) && 
    echo -n $file || echo -n
}

[ "x$SSL_CERT" != "x" -a ! -f "$SSL_CERT" ] && SSL_CERT=$(env2cert /etc/ssl/httpd/default.pem "$SSL_CERT")
[ "x$SSL_KEY" != "x" -a ! -f "$SSL_KEY" ] && SSL_KEY=$(env2cert /etc/ssl/httpd/default.key "$SSL_KEY")

#//---------------------------------------------------------------------------
#// Improv security
#//---------------------------------------------------------------------------
# Improv Sec
if [ ! -e /etc/ssl/httpd/ssl_sess_ticket.key ] ; then
    openssl rand 48 > /etc/ssl/httpd/ssl_sess_ticket.key
fi
if [ ! -e /etc/ssl/httpd/dhparam.key ] ; then
    env2cert /etc/ssl/httpd/dhparam.key "$SSL_DHPARAM" > /dev/null
    test -f /etc/ssl/httpd/dhparam.key || openssl dhparam 2048 > /etc/ssl/httpd/dhparam.key 2> /dev/null
fi

KUSANAGI_PROVISION=${KUSANAGI_PROVISION:-lamp}
#//---------------------------------------------------------------------------
#// generate nginx configuration file
#//---------------------------------------------------------------------------
cd /etc/nginx/conf.d \
&& env FQDN=${FQDN:-localhost.localdomain} \
    DOCUMENTROOT=${DOCUMENTROOT:-/var/www/html} \
    KUSANAGI_PROVISION=${KUSANAGI_PROVISION} \
    NO_SSL_REDIRECT=${NO_SSL_REDIRECT:+#} \
    NO_USE_FCACHE=${NO_USE_FCACHE:-0} \
    EXPIRE_DAYS=${EXPIRE_DAYS:-90} \
    USE_SSL_CT=${USE_SSL_CT:-off} \
    USE_SSL_OSCP=${USE_SSL_OSCP:-off} \
    OSCP_RESOLV=${OSCP_RESOLV} \
    SSL_CERT=${SSL_CERT:-/etc/ssl/httpd/default.pem} \
    SSL_KEY=${SSL_KEY:-/etc/ssl/httpd/default.key} \
    /usr/bin/envsubst '$$FQDN $$DOCUMENTROOT $$NO_SSL_REDIRECT
    $$NO_USE_FCACHE $$EXPIRE_DAYS $$USE_SSL_CT $$USE_SSL_OSCP
    $$SSL_CERT $$SSL_KEY $$OSCP_RESOLV $$KUSANAGI_PROVISION' \
    < default.conf.template > default.conf \
|| exit 1

env PHPHOST=${PHPHOST:-127.0.0.1} envsubst '$$PHPHOST' \
    < fastcgi.inc.template > fastcgi.inc || exit 1
env NO_USE_NAXSI=${NO_USE_NAXSI:+#} \
    NO_USE_SSLST=${NO_USE_SSLST:+#} \
    /usr/bin/envsubst '$$NO_USE_NAXSI $$NO_USE_SSLST' \
    < ${KUSANAGI_PROVISION}.inc.template > ${KUSANAGI_PROVISION}.inc || exit 1
#elif  [ "$KUSANAGI_PROVISION" == "rails" ] ; then
#    env ENV_SECRET_KEY_BASE=${ENV_SECRET_KEY_BASE?ENV_SECRET_KEY_BASE} \
#        RAILS_ENV=${RAILS_ENV:-development} \
#        NO_USE_NAXSI=${NO_USE_NAXSI:+#} \
#        NO_USE_SSLST=${NO_USE_SSLST:+#} \
#        /usr/bin/envsubst '$$ENV_SECRET_KEY_BASE $$ENV_SECRET_KEY_BASE
#        $$RAILS_ENV $$NO_USE_NAXSI $$NO_USE_SSLST' < rails.inc.template > rails.inc \
#   || exit 1

#//---------------------------------------------------------------------------
#// create self-signed cert
#//---------------------------------------------------------------------------
if [ -f /etc/ssl/httpd/default.key -o -f /etc/ssl/httpd/default.pem ]; then
    /bin/true
else
    keyfile=$(mktemp /tmp/k_ssl_key.XXXXXX)
    certfile=$(mktemp /tmp/k_ssl_cert.XXXXXX)
    trap "rm -f ${keyfile} ${certfile}" SIGINT
    (echo --; echo SomeState; echo SomeCity; echo SomeOrganization; \
     echo SomeOrganizationalUnit; echo localhost.localdomain; \
     echo root@localhost.localdomain) | \
    openssl req -newkey rsa:2048 -keyout "${keyfile}" -nodes -x509 \
                -days 365 -out "${certfile}" 2> /dev/null
    mv "${keyfile}" /etc/ssl/httpd/default.key
    chmod 0600 /etc/ssl/httpd/default.key
    mv "${certfile}" /etc/ssl/httpd/default.pem
    chmod 0644 /etc/ssl/httpd/default.pem
fi

#echo 127.0.0.1 $FQDN >> /etc/hosts

#//---------------------------------------------------------------------------
#// execute nginx
#//---------------------------------------------------------------------------
exec "$@"
