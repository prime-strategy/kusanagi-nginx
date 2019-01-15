# ACME
location ~* /\.well-known {
    alias /usr/share/html/.well-known;
    allow all;
}
