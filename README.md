Packaging and customizations for Auth0's [AD LDAP connector](https://github.com/auth0/ad-ldap-connector)

# Current state

The code in this repo:
* verifies that the package's checksum matches a known-good point in time checksum.
* creates nodejs / npm checksums
* patches the Auth0 code with Mozilla specific customizations
* packages everything into a single RPM which has systemd init support added to it.

# Impossible Ideal World
The [docs from Auth0](https://auth0.com/docs/customize/extensions/ad-ldap-connector/install-configure-ad-ldap-connector) are mostly what we have done here.  There are improvements that are possible, but that we are not undertaking.  I am calling these out because, when you look at this package fresh, it can get confusing as a sysadmin.

* The upstream package would need modifications to properly install without prompting the user on first install.
  * That makes us need to manually tweak the build-from-scratch on any rebuild.  Sorry.

* "All npm packages should be separate RPMs."
  * This will probably never happen.  The ad-ldap-connector package has a long laundry-list of requirements, which have their own requirements.  The install instructions from auth0 have us do a simple `npm install` command.  To break out into RPMs means chasing down recursive (sometimes conflicting) NPM packages, from `packages.json`.  Then building one-off packages that install modules into `/opt/ad-ldap-connector`, where they are /requirements of/ ad-ldap-connector yet also /require/ ad-ldap-connector to be installed in order for the directory to be there to exist in.  All of which is to say, while it looks ugly to build one massive package, it's actually expedient, cleaner, and more doc-compliant.


# Build the RPM

- Provision a CentOS 7 or CentOS 8 VM to work from.
  - Considering the amount of changes / installs, you probably want to do this rather than reuse a build host.
  - `sudo yum install -y git make`
  - `git clone https://github.com/mozilla-iam/ad-ldap-connector-rpm && cd ad-ldap-connector-rpm`
  - `make fpm-setup` if you need to install FPM.  Skip this if your server already has fpm.
- `make clean`
  - Make sure you start from a clean state, otherwise dependencies will be missing
- Ensure that the version number and build release number you want to create are set in the `Makefile`
  1. `make download` which fetches the archive
  2. `make verify` which checks the hash of the archive
    * You will need to edit the Makefile with the new checksum, if you changed versions.
  3. `make extract` which extracts the archive
  4. `make npm_download` which fetches all the npm dependencies
    * If you changed versions, you almost certainly changed NPM dependencies.  Run `make regenerate_sums` to produce a new `npm_modules.sha256sum` file, or you will fail verification.
  5. `make npm_verify` which checks the hashes of all the dependencies
  6. `make patch` which applies the Mozilla customizations to the `ad-ldap-connector`
- `make rpm` to produce the RPM (which calls the above in sequence)


# Install the RPM

- Install the rpm (`yum` or `rpm -U ad-ldap-connector-1.2.3_mozilla-1.x86_64.rpm`)
  - This will show the following output during installation
    ```
    Preparing...                          ################################# [100%]

    You will need to...

    * (if you have a proxy) Ensure you set up the proxy via a systemd dropin or unit file.

    $ cd /opt/ad-ldap-connector && sudo -u ad-ldap-connector node server.js
    once manually the first time in order to setup the connector.

    Configure /opt/ad-ldap-connector/config.json afterwards and run the usual systemd commands:
    $ systemctl start ad-ldap-connector
    $ systemctl enable ad-ldap-connector

    Updating / installing...
       1:ad-ldap-connector-1.2.3_mozilla-################################# [100%]
    ```
- As noted, create a dropin or unit file for ad-ldap-connector.service in systemd, ala:
  ```
  # mkdir /etc/systemd/system/ad-ldap-connector.service.d
  # cat << EOHEREDOC > /etc/systemd/system/ad-ldap-connector.service.d/use-proxy.conf
  [Service]
  Environment=http_proxy=proxy.example.com:3128
  Environment=https_proxy=proxy.example.com:3128
  EOHEREDOC
  ```
- Copy over your previous certs directory and `config.json`. If you have no 
  previous version you're done.

# Run the LDAP Connector

First time run is interactive in order to fetch the Auth0 ticket:

    $ sudo -u ad-ldap-connector node server.js
  
You can then modify `config.json` and start the daemon:

    $ systemctl start ad-ldap-connector
  
    $ systemctl enable ad-ldap-connector
  
Verify it works at https://manage.auth0.com/#/connections/enterprise
