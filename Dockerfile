#//----------------------------------------------------------------------------
#// KUSANAGI RoD (kusanagi-nginx)
#//----------------------------------------------------------------------------
FROM alpine:3.10
MAINTAINER kusanagi@prime-strategy.co.jp

ENV PATH /bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin

# add user
RUN : \
        && apk update \
        && apk upgrade \
        && apk add --no-cache --virtual .user shadow \
        && groupadd -g 1001 www \
        && useradd -d /var/lib/www -s /bin/nologin -g www -M -u 1001 httpd \
        && groupadd -g 1000 kusanagi \
        && useradd -d /home/kusanagi -s /bin/nologin -g kusanagi -G www -u 1000 -m kusanagi \
        && chmod 755 /home/kusanagi \
        && apk del --purge .user \
        && mkdir /tmp/build \
        && : # END of RUN

COPY files/fast_cgiparams_CVE-2016-5387.patch /tmp/build
COPY files/add_dev.sh /usr/local/bin
COPY files/del_dev.sh /usr/local/bin

ENV NGINX_VERSION=1.16.0 
ENV NGINX_DEPS gnupg1 \
		gcc \
		g++ \
		make  \
		autoconf \
		automake \
		patch \
		ruby-rake \
		curl \
		curl-dev \
		musl-dev \
		perl-dev \
		libxslt-dev \
		openssl-dev \
		linux-headers \
		luajit-dev \
		libpng-dev \
		freetype-dev \
		libxpm-dev \
		expat-dev \
		tiff-dev \
		libxcb-dev \
		lua-dev \
		pcre-dev \
		geoip-dev \
		gd-dev \
		ruby-etc \
		ruby-dev \
		libxpm-dev \
		fontconfig-dev \
		libuuid \
		util-linux-dev \
		zlib-dev \
		go \
		gnupg \
		gettext


# prep
RUN : \
\
	# add build pkg
	&& nginx_ct_version=1.3.2 \
	&& ngx_cache_purge_version=2.3 \
	&& ngx_brotli_version=master \
	&& naxsi_version=0.56 \
	&& nps_version=1.13.35.2 \
	&& GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
	&& brotli_version=222564a95d9ab58865a096b8d9f7324ea5f2e03e \
	&& naxsi_tarball_name=naxsi \
	&& lua_nginx_module_name=lua-nginx-module \
	&& ngx_devel_kit_version=0.3.0 \
	&& LUAJIT_VERSION=2.1.0-beta3 \
	&& LUA_VERSION=2.1 \
	&& lua_nginx_module_version=0.10.13 \
	&& CT_SUBMIT_VERSION=1.1.2 \
	&& LUAJIT_LIB=/usr/lib \
	&& LUAJIT_INC=/usr/include/luajit-$LUA_VERSION \
	&& CC=/usr/bin/cc \
	&& CXX=/usr/bin/c++ \
	&& apk add --no-cache --virtual .builddep $NGINX_DEPS \
	&& cd /tmp/build \
	&& curl -fSL http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx.tar.gz \
	&& curl -fSL http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc -o nginx.tar.gz.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& found=''; \
	for server in \
		keys.gnupg.net \
		ha.pool.sks-keyservers.net \
		hkp://keyserver.ubuntu.com:80 \
		hkp://p80.pool.sks-keyservers.net:80 \
		pgp.mit.edu \
	; do \
		echo "Fetching GPG key $GPG_KEYS from $server"; \
		gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
	gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
	&& rm -rf "$GNUPGHOME" nginx.tar.gz.asc \
	&& tar xf nginx.tar.gz \
	&& mkdir nginx-${NGINX_VERSION}/extensions \
	&& cd ./nginx-${NGINX_VERSION}/extensions \
	&& curl -Lo nginx-ct-${nginx_ct_version}.tar.gz https://github.com/grahamedgecombe/nginx-ct/archive/v${nginx_ct_version}.tar.gz \
	&& curl -Lo ngx_cache_purge-${ngx_cache_purge_version}.tar.gz https://github.com/FRiCKLE/ngx_cache_purge/archive/${ngx_cache_purge_version}.tar.gz \
	&& curl -Lo ngx_brotli-${ngx_brotli_version}.tar.gz https://github.com/google/ngx_brotli/archive/${ngx_brotli_version}.tar.gz \
	&& curl -Lo brotli-${brotli_version}.tar.gz https://github.com/google/brotli/archive/${brotli_version}.tar.gz \
	&& curl -Lo ngx_devel_kit-${ngx_devel_kit_version}.tar.gz https://github.com/simplresty/ngx_devel_kit/archive/v${ngx_devel_kit_version}.tar.gz \
	&& curl -Lo ${lua_nginx_module_name}-${lua_nginx_module_version}.tar.gz https://github.com/openresty/${lua_nginx_module_name}/archive/v${lua_nginx_module_version}.tar.gz \
	&& curl -Lo ${naxsi_tarball_name}-${naxsi_version}.tar.gz https://github.com/nbs-system/naxsi/archive/${naxsi_version}.tar.gz \
\
	&& tar xf nginx-ct-${nginx_ct_version}.tar.gz \
	&& mv nginx-ct-${nginx_ct_version} nginx-ct \
	&& tar xf ngx_cache_purge-${ngx_cache_purge_version}.tar.gz \
	&& mv ngx_cache_purge-${ngx_cache_purge_version} ngx_cache_purge \
	&& tar xf ngx_brotli-${ngx_brotli_version}.tar.gz \
	&& mv ngx_brotli-${ngx_brotli_version} ngx_brotli \
	&& tar xf ngx_devel_kit-${ngx_devel_kit_version}.tar.gz \
	&& mv ngx_devel_kit-${ngx_devel_kit_version} ngx_devel_kit \
	&& tar xf ${lua_nginx_module_name}-${lua_nginx_module_version}.tar.gz \
	&& mv ${lua_nginx_module_name}-${lua_nginx_module_version} ${lua_nginx_module_name} \
	&& tar xf ${naxsi_tarball_name}-${naxsi_version}.tar.gz \
	&& mv ${naxsi_tarball_name}-${naxsi_version} ${naxsi_tarball_name} \
	&& tar xf brotli-${brotli_version}.tar.gz \
	&& (test -d ngx_brotli/deps/brotli && rmdir ngx_brotli/deps/brotli) \
	&& mv brotli-${brotli_version} ngx_brotli/deps/brotli \
	&& cd .. \
	&& patch -p1 < ../fast_cgiparams_CVE-2016-5387.patch \
\
# configure
	&& cd /tmp/build/nginx-${NGINX_VERSION} \  
	&& CONF="\
		--prefix=/etc/nginx \
		--conf-path=/etc/nginx/nginx.conf \
		--sbin-path=/usr/sbin/nginx \
		--modules-path=/usr/lib/nginx/modules \
		--error-log-path=/dev/stderr \
		--http-log-path=dev/stdout \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
		--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
		--user=httpd \
		--group=www \
		--with-http_ssl_module \
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_sub_module \
		--with-http_dav_module \
		--with-http_flv_module \
		--with-http_mp4_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_random_index_module \
		--with-http_secure_link_module \
		--with-http_stub_status_module \
		--with-http_auth_request_module \
		--with-http_xslt_module \
		--with-http_image_filter_module \
		--with-http_geoip_module \
		--with-threads \
		--with-stream \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-stream_realip_module \
		--with-stream_geoip_module \
		--with-http_slice_module \
		--with-mail \
		--with-mail_ssl_module \
		--with-compat \
		--with-file-aio \
		--with-http_v2_module \
	    	--with-http_image_filter_module \
		--with-http_geoip_module \
		--with-http_perl_module \
		--add-module=./extensions/ngx_devel_kit \
		--add-module=./extensions/${lua_nginx_module_name} \
		--add-module=./extensions/ngx_cache_purge \
		--add-module=./extensions/nginx-ct \
		--add-module=./extensions/ngx_brotli \
		--add-module=./extensions/${naxsi_tarball_name}/naxsi_src \
	" \
	&& CFLAGS='-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 \
		-fexceptions -fstack-protector \
		-m64 -mtune=generic \
		-Wno-deprecated-declarations \
		-Wno-cast-function-type \
		-Wno-unused-parameter \
		-Wno-stringop-truncation \
		-Wno-stringop-overflow' \
	&& ./configure $CONF --with-cc-opt="$CFLAGS" \
\
# build
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& (find . -type f -a -name 'nginx' -o -name '*.so*' | xargs strip ; true) \
	&& (find . -type f -a -name '*.so*' | xargs chmod 755 ; true) \
	&& make install \
	&& mkdir -p /usr/lib/nginx/modules /etc/nginx/naxsi.d \
	&& install -m644 extensions/${naxsi_tarball_name}/naxsi_config/naxsi_core.rules /etc/nginx/naxsi.d/naxsi_core.rules.conf \
	&& (for so in `find extensions -type f -name '*.so'`; do mv $so /usr/lib/nginx/modules ; done; true) \
	&& mv /usr/bin/envsubst /tmp/ \
\
# add ct-submit
	&& curl -LO https://raw.githubusercontent.com/grahamedgecombe/ct-submit/v${CT_SUBMIT_VERSION}/ct-submit.go \
	&& go build ct-submit.go \
	&& cp ct-submit /tmp \
\
# remove pkg
	&& runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst /tmp/ct-submit \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& apk add --no-cache --virtual .nginx-rundeps $runDeps \
	&& apk del --purge .builddep \
\
	&& mv /tmp/envsubst /usr/bin/envsubst \
	&& mv /tmp/ct-submit /usr/bin/ct-submit \
	&& chmod 700 /usr/bin/ct-submit \
	\
# setup configures
	&& mkdir -p -m755 /var/www/html \
		/etc/nginx/conf.d \
		/var/cache/nginx \
		/var/log/nginx  \
	&& chown -R httpd:www /etc/nginx \
		/var/www/html \
		/var/cache/nginx \
		/var/log/nginx \
		/etc/hosts \
	&& install -m644 /etc/nginx/html/50x.html /var/www/html \
	&& install -m644 /etc/nginx/html/index.html /var/www/html \
	&& mkdir -p -m755 /etc/nginx/scts /etc/nginx/naxsi.d /etc/nginx/conf.d/templates \
	&& rm -rf /tmp/build \
	&& : # END of RUN

COPY files/nginx.conf /etc/nginx/nginx.conf
COPY files/nginx_httpd.conf /etc/nginx/conf.d/_nginx.conf
COPY files/nginx_ssl.conf /etc/nginx/conf.d/_ssl.conf
COPY files/kusanagi_naxsi_core.conf /etc/nginx/conf.d/kusanagi_naxsi_core.conf
COPY files/naxsi.d/ /etc/nginx/naxsi.d/
COPY files/templates/ /etc/nginx/conf.d/
COPY files/security.conf /etc/nginx/conf.d/security.conf
COPY files/ct-submit.sh /usr/bin/ct-submit.sh

# forward request and error logs to docker log collector
RUN cd /etc/nginx/ \
	&& chmod 700 /usr/bin/ct-submit.sh \
	&& ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
	&& apk add --no-cache tzdata openssl certbot \
	&& mkdir /etc/letsencrypt /var/lib/letsencrypt /var/log/letsencrypt \
	&& chown -R httpd:www /etc/letsencrypt /var/lib/letsencrypt /var/log/letsencrypt \
	&& : # END of RUN

ARG MICROSCANNER_TOKEN
RUN if [ x${MICROSCANNER_TOKEN} != x ] ; then \
	apk add --no-cache --virtual .ca ca-certificates \
	&& update-ca-certificates\
	&& wget --no-check-certificate https://get.aquasec.com/microscanner \
	&& chmod +x microscanner \
	&& ./microscanner ${MICROSCANNER_TOKEN} || exit 1\
	&& rm ./microscanner \
	&& apk del --purge .ca ;\
    fi

EXPOSE 8080
EXPOSE 8443

VOLUME /home/kusanagi
VOLUME /etc/letsencrypt

USER httpd
COPY files/docker-entrypoint.sh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]
