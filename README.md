This is a wrapper for Auth0's LDAP connector.

# Current state

The code in this repo creates checksums and verifies that the package's checksum
matches a known-good point in time checksum. It then packages everything into a
single RPM and which has systemd init support added to it.

# Ideally

The upstream package would need modifications to properly install without 
prompting the user on first install. Additionally, all npm packages should be 
separate RPMs.

# Build the RPM

- Provision a CentOS 7 VM to work from
  - Update to newest : `sudo yum update`
  - Install nodejs repo : `curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -`
  - Install packages : `sudo yum install -y git unzip rpm-build nodejs`
  - Install ruby :
    ```
    sudo yum install gcc gcc-c++ patch autoconf automake bison libffi-devel libtool readline-devel sqlite-devel zlib-devel openssl-devel
    gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    curl -sSL https://get.rvm.io | bash -s stable
    source ~/.rvm/scripts/rvm
    rvm install 2.7.2
    rvm use 2.7.2 --default
    ```
  - Install fpm : `gem install --no-document fpm`
- Determine if the [Mozilla fork](https://github.com/mozilla-iam/ad-ldap-connector)
  of https://github.com/auth0/ad-ldap-connector is up to date and has the version
  released that's desired. If not, merge upstream changes into the Mozilla fork
  and produce a release
- `git clone https://github.com/mozilla-iam/ad-ldap-connector-rpm && cd ad-ldap-connector-rpm`
- `make clean`
  - Make sure you start from a clean state, otherwise dependencies will be missing
- Ensure that the version number you want to build is present in the `Makefile`
- `make download`
- `make fpm` to produce the RPM which calls in sequence
  1. `make verify` which checks the hash of the archive
  2. `make extract` which extracts the archive
  3. `make npm_download` which fetches all the npm dependencies
  4. `make npm_verify` which checks the hashes of all the dependencies

If you changed npm dependencies, after verifying them, you can run `make regenerate_sums`

# Install the RPM

- Install the rpm (`yum` or `rpm -U ad-ldap-connector-1.2.3_mozilla-1.x86_64.rpm`)
  - This will show the following output during installation
    ```
    Preparing...                          ################################# [100%]
    id: ad-ldap-connector: no such user
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
