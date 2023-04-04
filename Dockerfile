#//----------------------------------------------------------------------------
#// KUSANAGI RoD (kusanagi-nginx)
#//----------------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM golang:1.20.0-bullseye as build-go
RUN : \
    && CT_SUBMIT_VERSION=1.1.2 \
    && go install github.com/grahamedgecombe/ct-submit@v${CT_SUBMIT_VERSION}

FROM --platform=$BUILDPLATFORM alpine:3.17.3
LABEL maintainer="kusanagi@prime-strategy.co.jp"

ENV PATH /bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin

#COPY files/add_dev.sh /usr/local/bin
#COPY files/del_dev.sh /usr/local/bin

ENV NGINX_VERSION=1.22.1
ENV NGINX_DEPS gnupg \
        ca-certificates \
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
        openssl=3.0.8-r3 \
        openssl-dev=3.0.8-r3 \
        linux-headers \
        libpng-dev \
        freetype-dev \
        libxpm-dev \
        expat-dev \
        tiff-dev \
        libxcb-dev \
        pcre-dev \
        geoip-dev \
        gd-dev \
        brotli-dev \
        ruby-etc \
        ruby-dev \
        fontconfig-dev \
        libuuid \
        util-linux-dev \
        zlib-dev \
        gettext

COPY files/ct-submit.sh /usr/bin/ct-submit.sh
COPY --from=build-go /go/bin/ct-submit /usr/bin/ct-submit

COPY files/docker-entrypoint.sh /

# add user
RUN : \
    # prep
    && apk update \
    && apk add --no-cache --virtual .user shadow \
    && groupadd -g 1001 www \
    && useradd -d /var/lib/www -s /bin/nologin -g www -M -u 1001 httpd \
    && groupadd -g 1000 kusanagi \
    && useradd -d /home/kusanagi -s /bin/nologin -g kusanagi -G www -u 1000 -m kusanagi \
    && chmod 755 /home/kusanagi \
    && apk del --purge .user \
    # add build pkg
    && nginx_ct_version=1.3.2 \
    && ngx_cache_purge_version=2.3 \
    && ngx_brotli_version=1.0.0rc \
    && naxsi_tarball_name=naxsi \
    && naxsi_version=1.3 \
    && nps_version=1.13.35.2 \
    && headers_more_module_version=0.34 \
    && lua_nginx_module_name=lua-nginx-module \
    && lua_nginx_module_version=0.10.24 \
    && ngx_devel_kit_version=0.3.2 \
    && lua_resty_core_version=0.1.26 \
    && lua_resty_lrucache_version=0.13 \
    && luajit_fork_version=2.1-20230119 \
    && stream_lua_nginx_version=0.0.13 \
    && apk add --no-cache --virtual .builddep $NGINX_DEPS \
    && mkdir /tmp/build \
    && cd /tmp/build \
# lua resty config
\
    && export PREFIX=/usr \
    && export LUA_LIB_DIR=/usr/share/lua/5.1 \
    && curl -fSLO https://github.com/openresty/lua-resty-core/archive/v${lua_resty_core_version}.tar.gz \
    && tar xf v${lua_resty_core_version}.tar.gz \
    && (cd lua-resty-core-${lua_resty_core_version} \
        && make install && ls -lR /usr/local/share ) \
    && curl -fSLO https://github.com/openresty/lua-resty-lrucache/archive/v${lua_resty_lrucache_version}.tar.gz \
    && tar xf v${lua_resty_lrucache_version}.tar.gz \
    && (cd lua-resty-lrucache-${lua_resty_lrucache_version} && make install && ls -lR /usr/local/share ) \
\
# luafork
    && curl -fSLO https://github.com/openresty/luajit2/archive/v${luajit_fork_version}.tar.gz \
    && tar xf v${luajit_fork_version}.tar.gz \
    && (cd luajit2-${luajit_fork_version} \
        && sed -i -e 's,/usr/local,/usr,' Makefile \
        && sed -i -e 's,/usr/local,/usr,' -e 's,LUA_LMULTILIB\t"lib",LUA_LMULTILIB "lib64",' src/luaconf.h \
        && make install DESTDIR=/tmp/build \
        && rm /tmp/build/usr/lib/*.so ) \
    && curl -fSL http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx.tar.gz \
    && tar xf nginx.tar.gz \
    && mkdir nginx-${NGINX_VERSION}/extensions \
    && cd ./nginx-${NGINX_VERSION}/extensions \
    && curl -fSLo nginx-ct-${nginx_ct_version}.tar.gz \
        https://github.com/grahamedgecombe/nginx-ct/archive/v${nginx_ct_version}.tar.gz \
    && curl -fSLo ngx_cache_purge-${ngx_cache_purge_version}.tar.gz  \
        https://github.com/FRiCKLE/ngx_cache_purge/archive/${ngx_cache_purge_version}.tar.gz \
    && curl -fSLo ngx_brotli-${ngx_brotli_version}.tar.gz \
        https://github.com/google/ngx_brotli/archive/v${ngx_brotli_version}.tar.gz \
    && curl -fSLo ngx_devel_kit-${ngx_devel_kit_version}.tar.gz \
        https://github.com/simplresty/ngx_devel_kit/archive/v${ngx_devel_kit_version}.tar.gz \
    && curl -fSLo headers-more-nginx-module-${headers_more_module_version}.tar.gz \
        https://github.com/openresty/headers-more-nginx-module/archive/v${headers_more_module_version}.tar.gz \
    && curl -fSLo ${lua_nginx_module_name}-${lua_nginx_module_version}.tar.gz \
        https://github.com/openresty/${lua_nginx_module_name}/archive/v${lua_nginx_module_version}.tar.gz \
    && curl -fSLo ${naxsi_tarball_name}-${naxsi_version}.tar.gz \
        https://github.com/nbs-system/naxsi/archive/${naxsi_version}.tar.gz \
    && curl -fSLo stream_lua_nginx-${stream_lua_nginx_version}.tar.gz \
        https://github.com/openresty/stream-lua-nginx-module/archive/v${stream_lua_nginx_version}.tar.gz \
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
    && tar xf headers-more-nginx-module-${headers_more_module_version}.tar.gz \
    && mv headers-more-nginx-module-${headers_more_module_version} headers-more-nginx-module \
    && tar xf stream_lua_nginx-${stream_lua_nginx_version}.tar.gz \
    && mv stream-lua-nginx-module-${stream_lua_nginx_version} stream-lua-nginx-module \
    && cd .. \
\
# configure
    && export LUAJIT_INC=/tmp/build/usr/include/luajit-2.1 \
    && export LUAJIT_LIB=/tmp/build/usr/lib \
    && CC=/usr/bin/cc \
    && CXX=/usr/bin/c++ \
    && CONF="\
        --prefix=/etc/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --error-log-path=/dev/stderr \
        --http-log-path=/dev/stdout \
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
        --with-pcre-jit \
        --with-stream \
        --with-stream_ssl_module \
        --add-module=./extensions/ngx_devel_kit \
        --add-module=./extensions/${lua_nginx_module_name} \
        --add-module=./extensions/ngx_cache_purge \
        --add-module=./extensions/nginx-ct \
        --add-module=./extensions/ngx_brotli \
        --add-module=./extensions/${naxsi_tarball_name}/naxsi_src \
        --add-module=./extensions/headers-more-nginx-module \
        --add-module=./extensions/stream-lua-nginx-module \
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
# remove pkg
    && runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" \
    && apk add --no-cache --virtual .nginx-rundeps $runDeps tzdata openssl \
    && apk del --purge .builddep \
\
    && mv /tmp/envsubst /usr/bin/envsubst \
# setup configures
    && mkdir -p -m755 /var/www/html \
        /etc/nginx/conf.d \
        /var/cache/nginx \
        /var/log/nginx  \
    && chown -R httpd:www /etc/nginx \
        /var/www/html \
        /var/cache/nginx \
        /var/log/nginx \
    && install -m644 /etc/nginx/html/50x.html /var/www/html \
    && install -m644 /etc/nginx/html/index.html /var/www/html \
    && mkdir -p -m755 /etc/nginx/scts /etc/nginx/naxsi.d /etc/nginx/conf.d/templates \
    && rm -rf /tmp/build \
    && chmod 700 /usr/bin/ct-submit /usr/bin/ct-submit.sh \
    && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
    && chmod 755 /docker-entrypoint.sh \
    && : # END of RUN


COPY files/nginx.conf /etc/nginx/nginx.conf
COPY files/kusanagi_naxsi_core.conf /etc/nginx/conf.d/kusanagi_naxsi_core.conf
COPY files/fastcgi_params /etc/nginx/fastcgi_params
COPY files/naxsi.d/ /etc/nginx/naxsi.d/
COPY files/templates/ /etc/nginx/conf.d/
COPY files/security.conf /etc/nginx/conf.d/security.conf

RUN apk add --no-cache --virtual .curl curl \
    && curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/master/contrib/install.sh | sh -s -- -b /tmp \
    && /tmp/trivy filesystem --skip-files /tmp/trivy --exit-code 1 --no-progress / \
    && apk del .curl \
    && rm /tmp/trivy \
    && :

EXPOSE 8080
EXPOSE 8443

VOLUME /home/kusanagi

USER httpd
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "/usr/sbin/nginx", "-g", "daemon off;" ]
