#//----------------------------------------------------------------------------
#// KUSANAGI C2D (kusanagi-nginx)
#//----------------------------------------------------------------------------
#FROM alpine:3.8
FROM alpine:edge
MAINTAINER s-miyaza@myzkstr.com

ENV KUSANAGI_NGINX_VERSION	1.15.7
ENV KUSANAGI_LIBBROTLI_VERSION	1.0pre1-2
ENV KUSANAGI_OPENSSL_VERSION	1.1.1a-r0
ENV KUSANAGI_SSLCONIG_VERSION	master
ENV nginx_ct_version 1.3.2
ENV ngx_cache_purge_version 2.3
ENV ngx_brotli_version master
ENV brotli_version 222564a95d9ab58865a096b8d9f7324ea5f2e03e
ENV passenger_version 6.0.0
ENV passenger_tarball_name passenger
ENV naxsi_tarball_name naxsi
ENV naxsi_version 0.56
ENV PATH /bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin
ENV CC /usr/bin/cc
ENV CXX /usr/bin/c++
ENV ngx_devel_kit_version 0.3.0
ENV LUAJIT_VERSION 2.1.0-beta3
ENV LUA_VERSION 2.1
ENV lua_nginx_module_name lua-nginx-module
ENV lua_nginx_module_version 0.10.13

# prep
RUN : \
	&& apk update && apk upgrade \
	&& apk add --force \
		musl \
		openssl \
		libaio \
		curl \
		perl \
		libstdc++ \
		ruby \
		ruby-etc \
		ruby-rails \
		ruby-rake \
		luajit \
		pcre \
		bz2 \
		libpng \
		freetype \
		libxpm \
		expat \
		tiff \
		libxcb \
		lua \
		curl \
	&& addgroup -g 1001 www \
	&& addgroup -g 1000 kusanagi \
	&& adduser -h /home/httpd -s /bin/false -g www -D -H  httpd \
	&& adduser -h /home/kusanagi -s /bin/bash -G kusanagi -G www -u 1000 -D kusanagi \
	&& chmod 755 /home/kusanagi \
	&& mkdir -p /tmp/build \
	&& cd /tmp/build \
	&& wget http://nginx.org/download/nginx-${KUSANAGI_NGINX_VERSION}.tar.gz \
	&& tar xf nginx-${KUSANAGI_NGINX_VERSION}.tar.gz \
	&& mkdir nginx-${KUSANAGI_NGINX_VERSION}/extensions 

COPY files/nginx.service /tmp/build/
COPY files/nginx.conf /tmp/build/
COPY files/logrotate.d_nginx /tmp/build/
COPY files/nginx_httpd.conf /tmp/build/
COPY files/nginx_ssl.conf /tmp/build/
COPY files/naxsi.d.tar.gz /tmp/build/
COPY files/kusanagi_naxsi_core.conf /tmp/build/
COPY files/fast_cgiparams_CVE-2016-5387.patch /tmp/build/
COPY files/naxsi-stringop-overflow.patch /tmp/build/
COPY files/security.conf /tmp/build/

# build
RUN : \
	&& DEP="gcc \
		g++ \
		make \
		elfutils \
		autoconf \
		automake \
		patch \
		curl-dev \
		musl-dev \
		perl-dev \
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
		libaio-dev \
		pcre-dev \
		geoip-dev \
		gd-dev \
		ruby-dev \
		bz2-dev \
	" \
	&& apk add --force --no-cache $DEP 
	RUN cd /tmp/build/nginx-${KUSANAGI_NGINX_VERSION}/extensions \
	&& curl -Lo nginx-ct-${nginx_ct_version}.tar.gz https://github.com/grahamedgecombe/nginx-ct/archive/v${nginx_ct_version}.tar.gz \
	&& curl -Lo ngx_cache_purge-${ngx_cache_purge_version}.tar.gz https://github.com/FRiCKLE/ngx_cache_purge/archive/${ngx_cache_purge_version}.tar.gz \
	&& curl -Lo ngx_brotli-${ngx_brotli_version}.tar.gz https://github.com/google/ngx_brotli/archive/${ngx_brotli_version}.tar.gz \
	&& curl -Lo brotli-${brotli_version}.tar.gz https://github.com/google/brotli/archive/${brotli_version}.tar.gz \
	&& curl -Lo ngx_devel_kit-${ngx_devel_kit_version}.tar.gz https://github.com/simplresty/ngx_devel_kit/archive/v${ngx_devel_kit_version}.tar.gz \
	&& curl -Lo ${lua_nginx_module_name}-${lua_nginx_module_version}.tar.gz https://github.com/openresty/${lua_nginx_module_name}/archive/v${lua_nginx_module_version}.tar.gz \
	&& curl -LO http://s3.amazonaws.com/phusion-passenger/releases/${passenger_tarball_name}-${passenger_version}.tar.gz \
	&& curl -Lo ${naxsi_tarball_name}-${naxsi_version}.tar.gz https://github.com/nbs-system/naxsi/archive/${naxsi_version}.tar.gz \
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
	&& tar xf ${passenger_tarball_name}-${passenger_version}.tar.gz \
	&& mv ${passenger_tarball_name}-${passenger_version} ${passenger_tarball_name} \
	&& tar xf ${naxsi_tarball_name}-${naxsi_version}.tar.gz \
	&& mv ${naxsi_tarball_name}-${naxsi_version} ${naxsi_tarball_name} \
	&& tar xf brotli-${brotli_version}.tar.gz \
	&& (test -d ngx_brotli/deps/brotli && rmdir ngx_brotli/deps/brotli) \
	&& mv brotli-${brotli_version} ngx_brotli/deps/brotli \
	&& cd .. \
	&& patch -p1 < ../fast_cgiparams_CVE-2016-5387.patch 

ENV LUAJIT_LIB /usr/lib
ENV LUAJIT_INC /usr/include/luajit-$LUA_VERSION

	RUN cd /tmp/build/nginx-${KUSANAGI_NGINX_VERSION} \  
	&& ./configure \
		--conf-path=/etc/nginx/nginx.conf \
		--add-module=./extensions/${naxsi_tarball_name}/naxsi_src \
		--sbin-path=/usr/sbin/nginx \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
		--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
		--user=nginx \
		--group=nginx \
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
		--with-mail \
		--with-threads \
		--with-stream \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-stream_realip_module \
		--with-stream_geoip_module=dynamic \
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
		--add-module=./extensions/${passenger_tarball_name}/src/nginx_module \
		--with-cc-opt='-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic  -Wno-deprecated-declarations -Wno-cast-function-type -Wno-unused-parameter -Wno-stringop-truncation -Wno-stringop-overflow ' \
		--with-ld-opt='-Wl,-rpath,$LUAJITLIB' \
	    --prefix=/etc/nginx \
	&& make 
	&& find . -type f -a -name 'nginx' -o -name '*.so*' | xargs strip \
	&& make install \
	&& mkdir -p /usr/lib/systemd/system  \
		/etc/nginx/conf.d \
		/var/cache/nginx  \
		/var/log/nginx  \
		/usr/share/nginx/html \
	&& cd /tmp/build/nginx-${KUSANAGI_NGINX_VERSION}/ \
	&& cp /tmp/build/nginx.conf /etc/nginx/nginx.conf \
	&& cp /tmp/build/nginx_httpd.conf /etc/nginx/conf.d/_http.conf \
	&& cp /tmp/build/nginx_ssl.conf /etc/nginx/conf.d/_ssl.conf \
	&& cp /etc/nginx/html/50x.html /usr/share/nginx/html \
	&& cp /etc/nginx/html/index.html /usr/share/nginx/html \
	&& mkdir -p /etc/nginx/naxsi.d \
	&& cp extensions/${naxsi_tarball_name}/naxsi_config/naxsi_core.rules /etc/nginx/naxsi.d/naxsi_core.rules.conf \
	&& (cd /etc/nginx/; tar xf /tmp/build/naxsi.d.tar.gz) \
	&& cp /tmp/build/kusanagi_naxsi_core.conf /etc/nginx/conf.d/kusanagi_naxsi_core.conf \
	&& cp /tmp/build/security.conf /etc/nginx/conf.d/security.conf \
	&& cd / \
	&& : # END OF RUN
	#&& rm -rf /tmp/build \
	#&& apk del --purge $DEP \

CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]
