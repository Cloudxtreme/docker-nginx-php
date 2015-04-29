#!/bin/bash

wget http://www.php.net/distributions/php-5.3.29.tar.gz

tar xzf php-5.3.29.tar.gz
wget -O fpm-race-condition.patch 'https://bugs.php.net/patch-display.php?bug_id=65398&patch=fpm-race-condition.patch&revision=1375772074&download=1'
patch -d php-5.3.29 -p0 < fpm-race-condition.patch
cd php-5.3.29
make clean
CFLAGS= CXXFLAGS= ./configure --prefix=/usr/local/php-5.3.29 --with-config-file-path=/usr/local/php-5.3.29/etc \
--with-fpm-user=www --with-fpm-group=www --enable-fpm --disable-fileinfo \
--with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
--with-iconv-dir=/usr/local --with-jpeg-dir --with-png-dir --with-zlib \
--with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-exif \
--enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-inline-optimization \
--enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl \
--with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-ftp \
--with-gettext --enable-zip --enable-soap --disable-ipv6 --disable-debug
make ZEND_EXTRA_LIBS='-liconv'
make install

[ -n "`cat /etc/profile | grep 'export PATH='`" -a -z "`cat /etc/profile | grep /usr/local/php-5.3.29`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=/usr/local/php-5.3.29/bin:\1@" /etc/profile
. /etc/profile

/bin/cp php.ini-production /usr/local/php-5.3.29/etc/php.ini

sed -i "s@^memory_limit.*@memory_limit = 64M@" /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^output_buffering =@output_buffering = On\noutput_buffering =@' /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^;cgi.fix_pathinfo.*@cgi.fix_pathinfo=0@' /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^short_open_tag = Off@short_open_tag = On@' /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^expose_php = On@expose_php = Off@' /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^request_order.*@request_order = "CGP"@' /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^;date.timezone.*@date.timezone = Asia/Shanghai@' /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^post_max_size.*@post_max_size = 64M@' /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^upload_max_filesize.*@upload_max_filesize = 64M@' /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^;upload_tmp_dir.*@upload_tmp_dir = /tmp@' /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^max_execution_time.*@max_execution_time = 30@' /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen@' /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^session.cookie_httponly.*@session.cookie_httponly = 1@' /usr/local/php-5.3.29/etc/php.ini
sed -i 's@^mysqlnd.collect_memory_statistics.*@mysqlnd.collect_memory_statistics = On@' /usr/local/php-5.3.29/etc/php.ini
[ -e /usr/sbin/sendmail ] && sed -i 's@^;sendmail_path.*@sendmail_path = /usr/sbin/sendmail -t -i@' /usr/local/php-5.3.29/etc/php.ini

# php-fpm Init Script
/bin/cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm-5.3.29
chmod +x /etc/init.d/php-fpm-5.3.29

cat > /usr/local/php-5.3.29/etc/php-fpm.conf <<EOF
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;
[global]
pid = run/php-fpm-5.3.29.pid
error_log = log/php-fpm-5.3.29.log
log_level = warning 
emergency_restart_threshold = 30
emergency_restart_interval = 60s 
process_control_timeout = 5s
daemonize = yes
;;;;;;;;;;;;;;;;;;;;
; Pool Definitions ;
;;;;;;;;;;;;;;;;;;;;
[www]
listen = /dev/shm/php-cgi-5.3.29.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 12 
pm.start_servers = 8 
pm.min_spare_servers = 6 
pm.max_spare_servers = 12
pm.max_requests = 2048
pm.process_idle_timeout = 10s
request_terminate_timeout = 120
request_slowlog_timeout = 0
slowlog = log/slow.log
rlimit_files = 51200
rlimit_core = 0
catch_workers_output = yes
env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
EOF

service php-fpm-5.3.29 start
