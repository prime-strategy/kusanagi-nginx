#!/bin/sh
# add build pkg
apk add --no-cache --virtual .builddep \
		gnupg1 \
		gcc \
		g++ \
		make \
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
		go \
		gettext
