FROM ubuntu:bionic

ARG www_data_uid=2001
RUN \
  groupmod -g $www_data_uid www-data && \
  usermod -u $www_data_uid www-data

ENV DEBIAN_FRONTEND=noninteractive
RUN \
  apt update && apt install -y \
    autoconf gcc libc6 make wget unzip apache2 php libapache2-mod-php7.2 \
    libgd-dev libmcrypt-dev libssl-dev bc gawk dc build-essential snmp \
    libnet-snmp-perl gettext iputils-ping msmtp msmtp-mta mailutils vim && \
  a2enmod rewrite cgi

ARG nagios_uid=2000
RUN \
  groupadd -r -g $nagios_uid nagios && \
  useradd -r -m -s /bin/sh -u $nagios_uid -g $nagios_uid -G www-data nagios

ARG nagios_source_url=https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.4.3/nagios-4.4.3.tar.gz
ARG plugins_source_url=https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
ARG clean=1

WORKDIR /build/nagios
RUN wget -O- $nagios_source_url | tar --strip-components=1 -zxf -
RUN \
  ./configure --with-httpd-conf=/etc/apache2/sites-enabled && \
  make all && \
  make install && \
  make install-daemoninit && \
  make install-commandmode && \
  make install-config && \
  make install-webconf

WORKDIR /build/plugins
RUN wget -O- $plugins_source_url | tar --strip-components=1 -zxf -
RUN \
  ./tools/setup && \
  ./configure && \
  make && make install

RUN \
  ( [ $clean -ne 0 ] && rm -rf /build ) && \
  mkdir -p /home/nagios/.config/msmtp && \
  mkdir -p /home/nagios/msmtp && \
  ln -s /home/nagios/.config/msmtp/config /home/nagios/.msmtprc && \
  chown -R nagios:nagios /home/nagios && \
  chmod 700 /home/nagios && \
  ln -s /usr/bin/mail /bin/mail

WORKDIR /
COPY container-init /
ENTRYPOINT ["/container-init"]
