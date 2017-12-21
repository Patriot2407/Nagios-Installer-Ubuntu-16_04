#!/bin/bash
IPADD=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d'/')
NAGIOSVER=nagios-4.3.4
PLUGVER=release-2.2.1
# Prerequisites
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y autoconf gcc libc6 make wget unzip apache2 php libapache2-mod-php7.0 libgd2-xpm-dev -y
# Downloading the Source
cd /tmp
wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/$NAGIOSVER.tar.gz
tar xzf nagioscore.tar.gz
#Compile
cd /tmp/nagioscore-$NAGIOSVER/
sudo ./configure --with-httpd-conf=/etc/apache2/sites-enabled
sudo make all
# Create User And Group
sudo useradd nagios
sudo usermod -a -G nagios www-data
# Install Binaries
sudo make install
# Install Service / Daemon
sudo make install-init
sudo update-rc.d nagios defaults
# Install Command Mode
sudo make install-commandmode
# Install Configuration Files
sudo make install-config
# Install Apache Config Files 
sudo make install-webconf
sudo a2enmod rewrite
sudo a2enmod cgi
# Configure Firewall
sudo ufw allow Apache
sudo ufw reload
# Create nagiosadmin User Account
sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
# Start Apache Web Server
sudo systemctl restart apache2.service
# Start Service / Daemon
sudo systemctl start nagios.service
# Test Nagios
clear
echo "
Nagios is now running, to confirm this you need to log into the Nagios Web Interface.

Point your web browser to the ip address or FQDN of your Nagios Core server, for example:

http://$IPADD/nagios

You will be prompted for a username and password. The username is nagiosadmin (you created it in a previous step) and the password is what you provided earlier.

Once you have logged in you are presented with the Nagios interface. Congratulations you have installed Nagios Core.
"
echo -n "press enter to continue..." 
read
# ------------------ Installing The Nagios Plugins ------------------
# Prerequisites
sudo apt-get install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext -y
# Downloading The Source
cd /tmp
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/$PLUGVER.tar.gz
tar zxf nagios-plugins.tar.gz
# Compile + Install
cd /tmp/nagios-plugins-$PLUGVER/
sudo ./tools/setup
sudo ./configure
sudo make
sudo make install
# Test Plugins
clear
echo "
Point your web browser to the ip address or FQDN of your Nagios Core server, for example:

http://$IPADD/nagios

Go to a host or service object and "Re-schedule the next check" under the Commands menu. The error you previously saw should now disappear and the correct output will be shown on the screen.
"
# Service / Daemon Commands
sudo systemctl start nagios.service
sudo systemctl stop nagios.service
sudo systemctl restart nagios.service
# sudo systemctl status nagios.service
echo ""
echo "This concludes the Nagios Core installation  script. Enjoy!"
exit 0
