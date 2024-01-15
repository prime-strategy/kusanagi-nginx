# SSL
ssl_dhparam /etc/ssl/httpd/dhparam.key;

ssl_session_tickets     on;
ssl_session_ticket_key  /etc/ssl/httpd/ssl_sess_ticket.key;

ssl_session_cache shared:SSL:1m;
ssl_session_timeout  5m;

ssl_protocols TLSv1.3;
ssl_ciphers "AES128+ECDHE:AES256+ECDHE:AES128+EDH:AES256+EDH:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4!CAMELLIA!AES128-SHA!AES128-SHA256!AES128-GCM-SHA256:!AES256-GCM-SHA384:!AES256-SHA256:!AES256-SHA!AES256-CCM8!AES256-CCM!AES128-CCM!ARIA128-GCM-SHA256!AES128-CCM8!ARIA256-GCM-SHA384";
ssl_prefer_server_ciphers   on;

more_set_headers 'Alt-Svc: h3=":443"; ma=2592000';
