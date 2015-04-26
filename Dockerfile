FROM ubuntu:14.04
MAINTAINER kurotokiya <kurotokiya@gmail.com>
COPY run.sh /run.sh
COPY src/ /usr/local/src/
WORKDIR /usr/local/src
RUN chmod +x nginx-php.docker.sh \
    && bash nginx-php.docker.sh \
    && chmod +x /run.sh \
    && echo "\ndaemon off;" >> /usr/local/nginx/conf/nginx.conf
EXPOSE 80
CMD ["/run.sh"]
