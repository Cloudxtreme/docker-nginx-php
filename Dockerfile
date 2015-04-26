FROM ubuntu:14.04
MAINTAINER kurotokiya <kurotokiya@gmail.com>
COPY run.sh /run.sh
COPY src/ /usr/local/src/
WORKDIR /usr/local/src
RUN chmod +x nginx-php.sh \
    && bash nginx-php.sh \
    && chmod +x /run.sh \
    && echo "\ndaemon off;" >> /usr/local/nginx/conf/nginx.conf
WORKDIR /home/wwwroot
EXPOSE 80
CMD ["/run.sh"]
