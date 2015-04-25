FROM ubuntu:14.04
MAINTAINER kurotokiya <kurotokiya@gmail.com>
COPY run.sh /run.sh
RUN chmod 777 /run.sh
COPY src/ /usr/local/src/
WORKDIR /usr/local/src
RUN chmod +x nginx-php.docker.sh && bash nginx-php.docker.sh
EXPOSE 80
CMD ["/run.sh"]
