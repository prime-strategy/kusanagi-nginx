# kusanagi-nginx

Nginx Web Server( for KUSANAGI Runs on Docker )

# Versions (tags)

- latest
- 1.10.0-1

# Image Content

- centos:7
- Kusanagi-7.8.2-2
- kusanagi-nginx-1.10.0-1

# Example `docker-compose.yml` for KUSANAGI Runs on Docker

```yaml
version: '2'

services:
  kusanagi-data:
    container_name: kusanagi-data
    image: busybox
    restart: always
    stdin_open: true
    tty: true
    volumes:
      - /var/lib/mysql
      - /etc/nginx/conf.d
      - /etc/httpd/conf.d
      - /etc/kusanagi.d
      - /home/kusanagi
    command: /bin/sh

  kusanagi-nginx:
    container_name: kusanagi-nginx
    image: primestrategy/kusanagi-nginx:1.10.0-1
    environment:
      PROFILE: kusanagi
      FQDN: kusanagi.example.jp
      WPLANG: ja
      BCACHE: "off"
      FCACHE: "off"
    volumes_from:
      - kusanagi-data
    links:
      - kusanagi-php7:php
      - kusanagi-mariadb:mysql
    ports:
      - "80:80"
      - "443:443"

  kusanagi-mariadb:
    container_name: kusanagi-mariadb
    image: mariadb:10.0.24
    environment:
      MYSQL_ROOT_PASSWORD: my-secret-pw
      MYSQL_USER:     user
      MYSQL_PASSWORD: password
      MYSQL_DATABASE: wordpress
    volumes_from:
      - kusanagi-data

  kusanagi-php7:
    container_name: kusanagi-php7
    image: primestrategy/kusanagi-php7:7.0.6-1
    links:
      - kusanagi-mariadb:mysql
    volumes_from:
      - kusanagi-data
```
