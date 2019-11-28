# Imagen a utilizar para el container
FROM ubuntu:16.04

MAINTAINER rubenromero.tk <ruromeroc@gmail.com>

#Actualizamos
RUN apt-get -y update && apt-get -y upgrade


#We install apache2 and php7 with all the usual libraries.
RUN apt-get -y install \
apache2 \
php7.0 \
libapache2-mod-php7.0 \
php7.0-mysql \
php7.0-curl \
php7.0-gd \
php7.0-intl \
php-pear \
php-imagick \
php7.0-imap \
php7.0-mcrypt \
php-memcache  \
php7.0-pspell \
php7.0-recode \
php7.0-sqlite3 \
php7.0-tidy \
php7.0-xmlrpc \
php7.0-xsl \
php7.0-mbstring \
php-gettext

RUN apt-get install -y unzip libaio-dev php5-dev

# Oracle instantclient
ADD instantclient-basic-linux.x64-12.1.0.2.0.zip /tmp/
ADD instantclient-sdk-linux.x64-12.1.0.2.0.zip /tmp/
ADD instantclient-sqlplus-linux.x64-12.1.0.2.0.zip /tmp/

RUN unzip /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /usr/local/
RUN unzip /tmp/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /usr/local/
RUN unzip /tmp/instantclient-sqlplus-linux.x64-12.1.0.2.0.zip -d /usr/local/
RUN ln -s /usr/local/instantclient_12_1 /usr/local/instantclient
RUN ln -s /usr/local/instantclient/libclntsh.so.12.1 /usr/local/instantclient/libclntsh.so
RUN ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus
RUN echo 'instantclient,/usr/local/instantclient' | pecl install oci8
RUN echo "extension=oci8.so" > /etc/php7/apache2/conf.d/30-oci8.ini

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
#ADD 001-default-ssl.conf /etc/apache2/sites-enabled/001-default-ssl.conf

#Cleaning a little bt=it the container to make it slimmer.
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#We open port 80 y port 443
EXPOSE 80
EXPOSE 443

#We start Apache2 at the moment of starting the server
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
