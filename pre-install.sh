#!/usr/bin/bash
id ad-ldap-connector >/dev/null 2>&1 || useradd ad-ldap-connector -r -d /opt/ad-ldap-connector || {
	echo "failed to create \"ad-ldap-connector\" user"
	exit 1
}
touch /var/log/ad-ldap-connector.log  || {
	echo "failed to create default log file"
	exit 1
}
chown ad-ldap-connector:ad-ldap-connector /var/log/ad-ldap-connector.log || {
	echo "failed to set ownership of default log file"
	exit 1
}

echo ""
echo "You will need to..."
echo ""
echo "* (if you have a proxy) Ensure you set up the proxy via a systemd dropin or unit file."
echo ""
echo "$ cd /opt/ad-ldap-connector && sudo -u ad-ldap-connector node server.js"
echo "once manually the first time in order to setup the connector."
echo ""
echo "Configure /opt/ad-ldap-connector/config.json afterwards and run the usual systemd commands:"
echo "$ systemctl start ad-ldap-connector"
echo "$ systemctl enable ad-ldap-connector"
echo ""
