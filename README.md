# Nginx + PHP For Docker

#### Run

    docker run -d -p 8080:80 kurotokiya/nginx-php:latest

#### Build

You can change the Nginx or PHP versions in `src/nginx-php.sh` and run:

    docker build -t kurotokiya/nginx-php:new .

to build your own image.

By Tokiya.
