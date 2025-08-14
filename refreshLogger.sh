#!/bin/bash
# Script to remove logger server environment setup and refresh Ubuntu OS

# Exit on any error
set -e

# Stop and disable Apache if installed
echo "Stopping and disabling Apache..."
sudo systemctl stop apache2 || true
sudo systemctl disable apache2 || true

# Remove Apache and PHP packages
echo "Removing Apache and PHP..."
sudo apt purge -y apache2 apache2-bin apache2-data apache2-utils libapache2-mod-php php php-mysql || true
sudo apt autoremove -y
sudo apt autoclean

# Remove the cloned repository
echo "Removing syslog-logger-backend repository..."
sudo rm -rf /var/www/html/syslog-logger-backend

# Remove Apache virtual host configuration
echo "Removing Apache virtual host..."
if command -v a2dissite >/dev/null 2>&1; then
    sudo a2dissite syslog.conf || true
else
    echo "Warning: a2dissite not found, manually removing virtual host config..."
fi
sudo rm -f /etc/apache2/sites-available/syslog.conf
sudo rm -f /etc/apache2/sites-enabled/syslog.conf
sudo rm -f /var/log/apache2/syslog_error.log
sudo rm -f /var/log/apache2/syslog_access.log

# Remove cron job and log
echo "Removing cron job..."
sudo rm -f /etc/cron.d/syslog-sync
sudo rm -f /var/log/syslog_cron.log

# Remove firewall rules and reset UFW
echo "Removing firewall rules..."
sudo ufw delete allow 80/tcp || true
sudo ufw delete allow 443/tcp || true
sudo ufw --force reset || true
sudo ufw --force disable || true

# Verify cleanup
echo "Verifying cleanup..."
ERRORS=0

if [ -d "/var/www/html/syslog-logger-backend" ]; then
    echo "Error: Repository directory still exists!"
    ERRORS=1
fi
if [ -f "/etc/apache2/sites-available/syslog.conf" ] || [ -f "/etc/apache2/sites-enabled/syslog.conf" ]; then
    echo "Error: Apache virtual host configuration still exists!"
    ERRORS=1
fi
if [ -f "/etc/cron.d/syslog-sync" ]; then
    echo "Error: Cron job still exists!"
    ERRORS=1
fi
if [ -f "/var/log/syslog_cron.log" ]; then
    echo "Error: Cron log file still exists!"
    ERRORS=1
fi
if dpkg -l | grep -E 'apache2|php' | grep -v grep; then
    echo "Error: Apache or PHP packages still installed! Listing packages..."
    dpkg -l | grep -E 'apache2|php'
    ERRORS=1
fi
if sudo ufw status | grep -q "80/tcp"; then
    echo "Error: Firewall rule for port 80 still exists!"
    ERRORS=1
fi
if sudo ufw status | grep -q "443/tcp"; then
    echo "Error: Firewall rule for port 443 still exists!"
    ERRORS=1
fi

if [ $ERRORS -eq 0 ]; then
    echo "Cleanup and refresh completed successfully!"
else
    echo "Cleanup completed with errors. Please review the above messages."
    exit 1
fi