#!/bin/bash
# Script to remove logger server environment setup and refresh Ubuntu OS

# Exit on any error
set -e

# Stop and disable Apache
echo "Stopping and disabling Apache..."
sudo systemctl stop apache2 || true
sudo systemctl disable apache2 || true

# Remove Apache and PHP packages
echo "Removing Apache and PHP..."
sudo apt purge -y apache2 libapache2-mod-php php php-mysql
sudo apt autoremove -y
sudo apt autoclean

# Remove the cloned repository
echo "Removing syslog-logger-backend repository..."
sudo rm -rf /var/www/html/syslog-logger-backend

# Remove Apache virtual host configuration
echo "Removing Apache virtual host..."
sudo a2dissite syslog.conf || true
sudo rm -f /etc/apache2/sites-available/syslog.conf
sudo rm -f /var/log/apache2/syslog_error.log
sudo rm -f /var/log/apache2/syslog_access.log

# Remove cron job
echo "Removing cron job..."
sudo rm -f /etc/cron.d/syslog-sync
sudo rm -f /var/log/syslog_cron.log

# Remove firewall rules
echo "Removing firewall rules..."
sudo ufw delete allow 80/tcp || true
sudo ufw delete allow 443/tcp || true
sudo ufw --force reset
sudo ufw --force disable

# Verify cleanup
echo "Verifying cleanup..."
if [ -d "/var/www/html/syslog-logger-backend" ]; then
    echo "Error: Repository directory still exists!"
    exit 1
fi
if [ -f "/etc/apache2/sites-available/syslog.conf" ]; then
    echo "Error: Apache virtual host configuration still exists!"
    exit 1
fi
if [ -f "/etc/cron.d/syslog-sync" ]; then
    echo "Error: Cron job still exists!"
    exit 1
fi
if [ -f "/var/log/syslog_cron.log" ]; then
    echo "Error: Cron log file still exists!"
    exit 1
fi
if dpkg -l | grep -q apache2; then
    echo "Error: Apache package still installed!"
    exit 1
fi
if dpkg -l | grep -q php; then
    echo "Error: PHP package still installed!"
    exit 1
fi
if sudo ufw status | grep -q "80/tcp"; then
    echo "Error: Firewall rule for port 80 still exists!"
    exit 1
fi
if sudo ufw status | grep -q "443/tcp"; then
    echo "Error: Firewall rule for port 443 still exists!"
    exit 1
fi

echo "Cleanup and refresh completed successfully!"