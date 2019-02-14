# ACME
location ~* /\.well-known {
    alias /var/www/html/.well-known;
    allow all;
}
