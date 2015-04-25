#!/bin/bash

apt-get -y remove --purge apache2 apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-doc apache2-mpm-worker mysql-client mysql-server mysql-common libmysqlclient18 php5 php5-common php5-cgi php5-mysql php5-curl php5-gd libmysql* mysql-*

apt-get -y update

apt-get -y install gcc g++ make cmake autoconf libjpeg8 libjpeg8-dev libpng12-0 libpng12-dev libpng3 libfreetype6 libfreetype6-dev libxml2 libxml2-dev zlib1g zlib1g-dev libc6 libc6-dev libglib2.0-0 libglib2.0-dev bzip2 libzip-dev libbz2-1.0 libncurses5 libncurses5-dev curl libcurl3 libcurl4-openssl-dev e2fsprogs libkrb5-3 libkrb5-dev libltdl-dev libidn11 libidn11-dev openssl libssl-dev libtool libevent-dev re2c libsasl2-dev libxslt1-dev patch vim zip unzip tmux htop wget bc expect rsync git sendmail

cd /usr/local/src

mkdir -p /home/wwwroot/default
mkdir -p /home/wwwlogs

wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
wget http://downloads.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
wget http://downloads.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz
wget http://downloads.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz
wget http://www.php.net/distributions/php-5.6.8.tar.gz
wget http://downloads.sourceforge.net/project/pcre/pcre/8.36/pcre-8.36.tar.gz
wget http://nginx.org/download/nginx-1.8.0.tar.gz

if [ -n "`cat /etc/issue | grep -E 14`" ];then
	apt-get -y install libcloog-ppl1
	apt-get -y remove bison
	wget http://ftp.gnu.org/gnu/bison/bison-2.7.1.tar.gz
	tar xzf bison-2.7.1.tar.gz
	cd bison-2.7.1
	./configure
	make && make install
	cd ..
	rm -rf bison-2.7.1
elif [ -n "`cat /etc/issue | grep -E 13`" ];then
	apt-get -y install bison libcloog-ppl1
elif [ -n "`cat /etc/issue | grep -E 12`" ];then
	apt-get -y install bison libcloog-ppl0
fi

# /etc/security/limits.conf
[ -z "`cat /etc/security/limits.conf | grep 'nproc 65535'`" ] && cat >> /etc/security/limits.conf <<EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
[ -z "`cat /etc/rc.local | grep 'ulimit -SH 65535'`" ] && echo "ulimit -SH 65535" >> /etc/rc.local

rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# Set DNS
#cat > /etc/resolv.conf << EOF
#nameserver 114.114.114.114
#nameserver 8.8.8.8
#EOF

# /etc/sysctl.conf
[ -z "`cat /etc/sysctl.conf | grep 'fs.file-max'`" ] && cat >> /etc/sysctl.conf << EOF
fs.file-max=65535
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30 
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_max_syn_backlog = 65536 
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 65535 
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 262144
EOF
sysctl -p

# Update time
ntpdate pool.ntp.org 
[ -z "`grep 'pool.ntp.org' /var/spool/cron/root`" ] && { echo "*/20 * * * * `which ntpdate` pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/crontabs/root;chmod 600 /var/spool/cron/crontabs/root; } 
service cron restart




tar xzf libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=/usr/local
[ -n "`cat /etc/issue | grep 'Ubuntu 13'`" ] && sed -i 's@_GL_WARN_ON_USE (gets@//_GL_WARN_ON_USE (gets@' srclib/stdio.h 
[ -n "`cat /etc/issue | grep 'Ubuntu 14'`" ] && sed -i 's@gets is a security@@' srclib/stdio.h 
make && make install
cd ../
/bin/rm -rf libiconv-1.14

tar xzf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8
./configure
make && make install
ldconfig
cd libltdl/
./configure --enable-ltdl-install
make && make install
cd ../../
/bin/rm -rf libmcrypt-2.5.8

tar xzf mhash-0.9.9.9.tar.gz
cd mhash-0.9.9.9
./configure
make && make install
cd ../
/bin/rm -rf mhash-0.9.9.9

tar xzf mcrypt-2.6.8.tar.gz
cd mcrypt-2.6.8
ldconfig
./configure
make && make install
cd ../
/bin/rm -rf mcrypt-2.6.8

tar xzf php-5.6.8.tar.gz
useradd -M -s /sbin/nologin www
wget -O fpm-race-condition.patch 'https://bugs.php.net/patch-display.php?bug_id=65398&patch=fpm-race-condition.patch&revision=1375772074&download=1'
patch -d php-5.6.8 -p0 < fpm-race-condition.patch
cd php-5.6.8
make clean
CFLAGS= CXXFLAGS= ./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc \
--with-fpm-user=www --with-fpm-group=www --enable-fpm --disable-fileinfo \
--with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd \
--with-iconv-dir=/usr/local --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib \
--with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-exif \
--enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-inline-optimization \
--enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl \
--with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-ftp \
--with-gettext --enable-zip --enable-soap --disable-ipv6 --disable-debug
make ZEND_EXTRA_LIBS='-liconv'
make install

[ -n "`cat /etc/profile | grep 'export PATH='`" -a -z "`cat /etc/profile | grep /usr/local/php`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=/usr/local/php/bin:\1@" /etc/profile
. /etc/profile

/bin/cp php.ini-production /usr/local/php/etc/php.ini

sed -i "s@^memory_limit.*@memory_limit = 64M@" /usr/local/php/etc/php.ini
sed -i 's@^output_buffering =@output_buffering = On\noutput_buffering =@' /usr/local/php/etc/php.ini
sed -i 's@^;cgi.fix_pathinfo.*@cgi.fix_pathinfo=0@' /usr/local/php/etc/php.ini
sed -i 's@^short_open_tag = Off@short_open_tag = On@' /usr/local/php/etc/php.ini
sed -i 's@^expose_php = On@expose_php = Off@' /usr/local/php/etc/php.ini
sed -i 's@^request_order.*@request_order = "CGP"@' /usr/local/php/etc/php.ini
sed -i 's@^;date.timezone.*@date.timezone = Asia/Shanghai@' /usr/local/php/etc/php.ini
sed -i 's@^post_max_size.*@post_max_size = 64M@' /usr/local/php/etc/php.ini
sed -i 's@^upload_max_filesize.*@upload_max_filesize = 64M@' /usr/local/php/etc/php.ini
sed -i 's@^;upload_tmp_dir.*@upload_tmp_dir = /tmp@' /usr/local/php/etc/php.ini
sed -i 's@^max_execution_time.*@max_execution_time = 30@' /usr/local/php/etc/php.ini
sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen@' /usr/local/php/etc/php.ini
sed -i 's@^session.cookie_httponly.*@session.cookie_httponly = 1@' /usr/local/php/etc/php.ini
sed -i 's@^mysqlnd.collect_memory_statistics.*@mysqlnd.collect_memory_statistics = On@' /usr/local/php/etc/php.ini
[ -e /usr/sbin/sendmail ] && sed -i 's@^;sendmail_path.*@sendmail_path = /usr/sbin/sendmail -t -i@' /usr/local/php/etc/php.ini

# php-fpm Init Script
/bin/cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
update-rc.d php-fpm defaults

cat > /usr/local/php/etc/php-fpm.conf <<EOF
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]
pid = run/php-fpm.pid
error_log = log/php-fpm.log
log_level = warning 

emergency_restart_threshold = 30
emergency_restart_interval = 60s 
process_control_timeout = 5s
daemonize = yes

;;;;;;;;;;;;;;;;;;;;
; Pool Definitions ;
;;;;;;;;;;;;;;;;;;;;

[www]
listen = /dev/shm/php-cgi.sock
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



tar xzf pcre-8.36.tar.gz
cd pcre-8.36
./configure
make && make install
cd ../

tar xzf nginx-1.8.0.tar.gz
useradd -M -s /sbin/nologin www
cd nginx-1.8.0

# close debug
sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc

./configure --prefix=/usr/local/nginx --user=www --group=www --with-http_stub_status_module --with-http_spdy_module --with-http_ssl_module --with-ipv6 --with-http_gzip_static_module --with-http_flv_module
make && make install

[ -n "`cat /etc/profile | grep 'export PATH='`" -a -z "`cat /etc/profile | grep /usr/local/nginx`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=/usr/local/nginx/sbin:\1@" /etc/profile
. /etc/profile

cd ../

/bin/cp Nginx-init /etc/init.d/nginx
update-rc.d nginx defaults

mv /usr/local/nginx/conf/nginx.conf{,_bk}
#/bin/cp conf/nginx.conf /usr/local/nginx/conf/nginx.conf
/bin/cp conf/*.conf /usr/local/nginx/conf/

# logrotate nginx log
cat > /etc/logrotate.d/nginx << EOF
/home/wwwlogs/*nginx.log {
daily
rotate 5
missingok
dateext
compress
notifempty
sharedscripts
postrotate
    [ -e /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
endscript
}
EOF

echo "<h1>It works!</h1>" > /home/wwwroot/default/index.html
cp tz.php /home/wwwroot/default/

cd /home/wwwroot/
rm -rf /usr/local/src/*

service php-fpm start
service nginx start
