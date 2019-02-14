# static files
location ~* \.(jpg|jpeg|gif|png|webp|css|js|swf|ico|pdf|svg|eot|ttf|woff|woff2)$ {
    expires $expire_days;
    access_log off;
}
