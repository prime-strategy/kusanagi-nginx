# USE_SSL_ST
if ( $use_ssl_st ) {
    add_header Strict-Transport-Security 'max-age=31536000; includeSubDomains;preload;' always;
}
