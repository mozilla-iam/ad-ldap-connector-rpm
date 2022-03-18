Packaging and customizations for Auth0's [AD LDAP connector](https://github.com/auth0/ad-ldap-connector)

# Current state

The code in this repo
* creates checksums
* verifies that the package's checksum matches a known-good point in time checksum.
* patches the Auth0 code with Mozilla specific customizations
* packages everything into a single RPM and which has systemd init support added to it.

# Ideally

The upstream package would need modifications to properly install without 
prompting the user on first install. Additionally, all npm packages should be 
separate RPMs.

# Build the RPM

- Provision a CentOS 7 or CentOS 8 VM to work from
  - `sudo yum install -y git make`
  - `git clone https://github.com/mozilla-iam/ad-ldap-connector-rpm && cd ad-ldap-connector-rpm`
  - `make setup`
- `make clean`
  - Make sure you start from a clean state, otherwise dependencies will be missing
- Ensure that the version number you want to build is present in the `Makefile`
- `make fpm` to produce the RPM which calls in sequence
  1. `make download` which fetches the archive
  2. `make verify` which checks the hash of the archive
  3. `make extract` which extracts the archive
  4. `make npm_download` which fetches all the npm dependencies
  5. `make npm_verify` which checks the hashes of all the dependencies
  6. `make patch` which applies the Mozilla customizations to the `ad-ldap-connector`

If you changed npm dependencies, after verifying them, you can run `make regenerate_sums`
to produce a new `npm_modules.sha256sum` file

# Install the RPM

- Install the rpm (`yum` or `rpm -U ad-ldap-connector-1.2.3_mozilla-1.x86_64.rpm`)
  - This will show the following output during installation
    ```
    Preparing...                          ################################# [100%]
    You will need to run:
    $ cd /opt/ad-ldap-connector && sudo -u ad-ldap-connector node server.js
    Once manually the first time in order to setup the connector. Also ensure /opt/ad-ldap-connector/environ is set.
    Configure /opt/ad-ldap-connector/config.json afterwards and run the usual systemd commands:
    $ systemctl start ad-ldap-connector
    $ systemctl enable ad-ldap-connector
    Updating / installing...
       1:ad-ldap-connector-1.2.3_mozilla-################################# [100%]
    ```
- Change the file `/opt/ad-ldap-connector/environ` if you use a proxy
- Copy over your previous certs directory and `config.json`. If you have no 
  previous version you're done.

# Run the LDAP Connector

First time run is interactive in order to fetch the Auth0 ticket:

    $ sudo -u ad-ldap-connector node server.js
  
You can then modify `config.json` and start the daemon:

    $ systemctl start ad-ldap-connector
  
    $ systemctl enable ad-ldap-connector
  
Verify it works at https://manage.auth0.com/#/connections/enterprise
