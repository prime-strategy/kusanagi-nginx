# FASTCGI cache
fastcgi_split_path_info ^(.+?\.php)(/.*)$;
set $device "pc";

if ($request_method = POST) {
    set $do_not_cache 1;
}

if ($query_string != "") {
    set $do_not_cache 1;
}

if ($http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
    set $do_not_cache 1;
}

if ($http_user_agent ~* " Android |\(iPad|Android; Tablet; .+Firefox") {
    set $device "tablet";
}

if ($http_user_agent ~* " Android .+ Mobile |\(iPhone|\(iPod|IEMobile|Android; Mobile; .+Firefox|Windows Phone") {
    set $device "smart";
}

fastcgi_cache        wpcache;
fastcgi_cache_key    "$device:$request_method:$scheme://$host$request_uri";
fastcgi_cache_valid  200 10m;
fastcgi_no_cache     $do_not_cache;
fastcgi_cache_bypass $do_not_cache;

add_header X-F-Cache $upstream_cache_status;

