This is a wrapper for auth0's LDAP connector.

Current state
============
It checksums and verifies packages checksum match a known-good point in time checksum,
packages everything into a single RPM and has systemd init support.

Ideally
=======
The upstream package would need modifications to properly install without prompting the user on first install.
Additionally, all npm packages should be separate RPMs.

What you have to do to use this
===============================

- Make sure you start from a clean state, or else `make clean` otherwise dependencies will be missing
- If you changed deps, after verifying them, you can run `make regenerate-sums`
- Create ('make fpm') or download the rpm from releases
- Install the rpm (yum or rpm -U blah.rpm)
- Change the file /opt/ad-ldap-connector/environ if you use a proxy
- Copy over your previous certs directory and config.json. If you have no previous version you're done.

To run it
=========
First time run requires you to run it interactively to fetch the auth0 ticket: 
  $ sudo -u ad-ldap-connector node server.js
  
You can then modify config.json and start the daemon:

  $ systemctl start ad-ldap-connector
  
  $ systemctl enable ad-ldap-connector
  
Verify it works in https://manage.auth0.com/#/connections/enterprise
