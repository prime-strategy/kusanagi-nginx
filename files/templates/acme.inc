# ACME
location ~* /\.well-known {
    alias /etc/kusanagi.d/.well-known;
    allow all;
}
