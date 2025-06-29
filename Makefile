#@maintainer gene@mozilla.com
#@update 2020-11-09

SOURCE_URL:=https://github.com/auth0/ad-ldap-connector.git
# The source version is the tag or commit we'll use from ^
SOURCE_VERSION:=0d2267c73ba96edbe420f30033233042bee5da67

# This is the ad-ldap-connector version for RPM purposes.  This doesn't
# necessarily match the source version because auth0 stopped tagging packages.
PKGVER:= 6.2.0
# This is the RPM's sub-release version ('iteration' in `fpm` parlance)
# Bump this when you repackage the same version of software differently.
# Reset to 1 when you upgrade.
PKGREL:= 1
PKGSUFFIX:= _mozilla

###########################################################################
# You -shouldn't- need to modify below this point.  But reading can't hurt.
###########################################################################

# The package that we build.  Notice that we also have other uses of this common name.
# Use the right variable in recipes!
PKGNAME:=ad-ldap-connector
PKG_USER:=ad-ldap-connector
PKG_GROUP:=ad-ldap-connector

# A directory that we will use as we build the package.
BUILDDIR=buildroot

PKGDIRNAME:=$(PKGNAME)-$(PKGVER)

# Required for the fancy checksumming
# with GNU Make we'd reach foreach's and patterns limits
SHELL:=/bin/bash

# And here's the magic recipes:

# Make sure our build directory exists:
$(BUILDDIR):
	mkdir -p $@

download: $(BUILDDIR)/$(PKGDIRNAME)
$(BUILDDIR)/$(PKGDIRNAME): | $(BUILDDIR)
	git clone $(SOURCE_URL) $(BUILDDIR)/$(PKGDIRNAME)

extract: $(BUILDDIR)/$(PKGDIRNAME)
	git -C $(BUILDDIR)/$(PKGDIRNAME) checkout --detach $(SOURCE_VERSION)

npm_download: | $(BUILDDIR)/$(PKGDIRNAME)
	@cd $(BUILDDIR)/$(PKGDIRNAME) && npm install --omit=dev

all: rpm

rpm: npm_download | $(BUILDDIR)/$(PKGDIRNAME)
	# Creating package
	mkdir -p $(BUILDDIR)/target/opt
	cp -vr $(BUILDDIR)/$(PKGDIRNAME) $(BUILDDIR)/target/opt/$(PKGNAME)
	mkdir -p $(BUILDDIR)/target/usr/lib/systemd/system
	cp -v sources/ad-ldap-connector.service $(BUILDDIR)/target/usr/lib/systemd/system/
	fpm -s dir -t rpm \
		--rpm-user $(PKG_USER) --rpm-group $(PKG_GROUP) \
		--rpm-digest sha256 \
		--before-install sources/pre-install.sh \
		--depends nodejs --depends npm \
		--iteration $(PKGREL) \
		--exclude opt/$(PKGNAME)/$(PKGNAME)-$(PKGVER)$(PKGSUFFIX) \
		--name $(PKGNAME) --version $(PKGVER)$(PKGSUFFIX) -C $(BUILDDIR)/target

.PHONY: all rpm clean download extract npm_download
clean:
	-rm -rvf $(BUILDDIR)
	-rm -vf *.rpm
