# ACME
location ~* /\.well-known {
    alias /usr/share/nginx/html/.well-known;
    allow all;
}
