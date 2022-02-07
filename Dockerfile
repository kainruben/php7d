# Imagen a utilizar para el container
FROM ubuntu:20.04

MAINTAINER rubenromero.tk <ruromeroc@gmail.com>

ENV TZ=Europe/Minsk
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


#Actualizamos
RUN apt-get -y update && apt-get -y upgrade

#We install apache2 and php7 with all the usual libraries.
RUN apt-get -y install \
apache2 \
php7.4 \
libapache2-mod-php7.4 \
php7.4-mysql \
php7.4-curl \
php7.4-gd \
php7.4-intl \
php-pear \
php-imagick \
php7.4-imap \
php-memcache  \
php7.4-pspell \
php7.4-sqlite3 \
php7.4-tidy \
php7.4-xmlrpc \
php7.4-xsl \
php7.4-mbstring

# install GIT
RUN apt-get install -y git

# install CURL
RUN apt-get install -y curl

#  install Python PIP for EBS-CLI Si queremos python-pip
# RUN apt-get install -y python-pip
# RUN pip install --upgrade pip

# install EBS-CLI para trabajar con EBS de AWS
# RUN pip install --upgrade --user awsebcli

# Install Composer and make it available in the PATH
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# install npm
RUN apt-get install -y npm


 ## Creamos el usuario 
RUN useradd -ms /bin/bash  usuario
RUN mkdir /home/usuario/logs
RUN mkdir /home/usuario/www
RUN echo "<?php phpinfo(); ?>" >/home/usuario/www/__info.php
RUN echo "" > /home/usuario/logs/error.apache.log
RUN echo "" > /home/usuario/logs/access.apache.log
RUN echo "" > /home/usuario/logs/php.error.log
RUN chown -R usuario:usuario /home/usuario
RUN chmod 777 /home/usuario/logs/*

# Agregamos la configuracion de apache para limpiar todo
RUN a2dismod mpm_event && \
    a2enmod mpm_prefork \
            ssl \
            rewrite && \
    a2ensite default-ssl && \
    ln -sf /home/usuario/logs/acceso-apache /var/log/apache2/access.log && \
    ln -sf /home/usuario/logs/error-apache /var/log/apache2/error.log

# Manually set up the apache environment variables
ENV APACHE_RUN_USER usuario
ENV APACHE_RUN_GROUP usuario

WORKDIR /home/usuario

#upload
RUN echo "file_uploads = On\n" \
         "memory_limit = 500M\n" \
         "upload_max_filesize = 500M\n" \
         "post_max_size = 500M\n" \
         "max_execution_time = 600\n" \
         > /etc/php/7.0/cli/conf.d/uploads.ini

##php errors log
RUN echo "error_reporting = E_ALL\n" \
         "logs_errors = On\n" \
         "error_log = /home/usuario/logs/php.error.log\n" \
         > /etc/php/7.0/cli/conf.d/logerrors.ini


RUN sed -i 's/^ServerSignature/#ServerSignature/g' /etc/apache2/conf-enabled/security.conf; \
    sed -i 's/^ServerTokens/#ServerTokens/g' /etc/apache2/conf-enabled/security.conf; \
    echo "ServerSignature Off" >> /etc/apache2/conf-enabled/security.conf; \
    echo "ServerTokens Prod" >> /etc/apache2/conf-enabled/security.conf; \
    a2enmod headers; \
    echo "SSLProtocol ALL -SSLv2 -SSLv3" >> /etc/apache2/apache2.conf

ADD 000-default.conf /etc/apache2/sites-enabled/000-default.conf
ADD 001-default-ssl.conf /etc/apache2/sites-enabled/001-default-ssl.conf

#Cleaning a little bt=it the container to make it slimmer.
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#We open port 80 y port 443
EXPOSE 80
EXPOSE 443

#We start Apache2 at the moment of starting the server
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
