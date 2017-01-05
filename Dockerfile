FROM alpine

ENV 	HTTPD_VERSION=2.2.15 \
	HTTPD_PREFIX=/etc/httpd \
	PATH=/etc/httpd/bin:$PATH


# Install Apache
RUN set -x \
        && runDeps=' \
                apr-dev \
                apr-util-dev \
                perl \
                ca-certificates \
        ' \
        && apk add --no-cache --virtual .build-deps \
                $runDeps \
		openssl \
                gnupg \
                gcc \
                libc-dev \
                make \
                openssl-dev \
                pcre-dev \
                tar \
        \
        && mkdir -p "$HTTPD_PREFIX" \
        && cd "$HTTPD_PREFIX" \
        && wget -q https://archive.apache.org/dist/httpd/httpd-2.2.15.tar.gz \
        && tar -zxvf httpd-2.2.15.tar.gz \
        && rm -fr httpd-2.2.15.tar.gz \
        && cd "httpd-${HTTPD_VERSION}"\
        \
        && ./configure \
                --prefix="$HTTPD_PREFIX" \
        	--disable-filter \
                --disable-userdir \
                --enable-auth-digest \
                --enable-authn-alias \
                --enable-authn-anon \
                --enable-authn-dbm \
                --enable-authnz-ldap \
                --enable-authz-dbm \
                --enable-authz-owner \
                --enable-cern-meta \
                --enable-deflate \
                --enable-expires \
                --enable-ext-filter \
                --enable-headers \
                --enable-ldap \
                --enable-logio \
                --enable-mime-magic \
                --enable-rewrite \
                --enable-speling \
		--enable-ssl \
                --enable-suexec \
                --enable-usertrack \
                --enable-vhost-alias \
	&& make -j"$(getconf _NPROCESSORS_ONLN)" \
        && make install \
        \
        && cd .. \
        && rm -r "httpd-${HTTPD_VERSION}" \
        \
        && runDeps="$runDeps $( \
                scanelf --needed --nobanner --recursive /usr/local \
                        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                        | sort -u \
                        | xargs -r apk info --installed \
                        | sort -u \
        )" \
        && apk add --virtual .httpd-rundeps $runDeps \
        && apk del .build-deps

ADD     httpd-foreground /usr/local/bin/
EXPOSE 80 443
CMD ["httpd-foreground"]
