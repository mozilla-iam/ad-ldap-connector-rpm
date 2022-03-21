#@maintainer gene@mozilla.com
#@update 2020-11-09

# If you change the PKGVER:
# * update PKGSHA256
# * ensure the module list in the NPMS file is accurate

# This is the ad-ldap-connector version
PKGVER:= 5.0.13
# This is the RPM's sub-release version ('iteration' in `fpm` parlance)
# Bump this when you repackage the same version of software differently.
# Reset to 1 when you upgrade.
PKGREL:= 2
PKGSUFFIX:= -mozilla

# When you update the PKGVER:
# * do `make download` to fetch the .tar.gz
# * do `sha256sum` on the .tar.gz you got and save it to PKGSHA256:
# * do `make verify` to check your work.
PKGSHA256:=2145b00452fba817d9733c4dce44d2a6af69c80976cfbaf74cb0aa50a81a65f8
# This is manual work; there's no checksum on github to read/compare against.

###########################################################################
# You -shouldn't- need to modify below this point.  But reading can't hurt.
###########################################################################

# The package that we build.  Notice that we also have other uses of this common name.
# Use the right variable in recipes!
PKGNAME:=ad-ldap-connector
PKG_USER:=ad-ldap-connector
PKG_GROUP:=ad-ldap-connector
# Where to find the packages on github:
PKGPATH:=https://github.com/auth0/ad-ldap-connector/archive/refs/tags/

# This filename holds checksums of all the nodejs / npm modules we install.
NPMS=npm_modules.sha256sum

# `fpm` (which will package the RPM), is a rubygem that needs at least 2.3.  CentOS7 ships
# with 2.0.  So this is used with `rvm` (Ruby Version Manager) to provide a ruby version
# advanced enough to let `fpm` run.  It's only used for the packaging process, not the
# end-result build product.
RUBY_VERSION=2.7.2

PKGARCHIVE:=v$(PKGVER).tar.gz
PKGDIRNAME:=$(PKGNAME)-$(PKGVER)

# Required for the fancy checksumming
# with GNU Make we'd reach foreach's and patterns limits
SHELL:=/bin/bash

# And here's the magic recipes:

all: fpm

fpm: extract npm_verify patch
	# Creating package
	mkdir -p target/opt
	cp -vr $(PKGDIRNAME) target/opt/$(PKGNAME)
	mkdir -p target/usr/lib/systemd/system
	cp -v sources/ad-ldap-connector.service target/usr/lib/systemd/system/
	~/.rvm/bin/rvm $(RUBY_VERSION) do fpm -s dir -t rpm \
		--rpm-user $(PKG_USER) --rpm-group $(PKG_GROUP) \
		--rpm-digest sha256 \
		--before-install sources/pre-install.sh \
		--depends nodejs --depends npm \
		--iteration $(PKGREL) \
		--exclude opt/$(PKGNAME)/$(PKGNAME)-$(PKGVER)$(PKGSUFFIX) \
		--name $(PKGNAME) --version $(PKGVER)$(PKGSUFFIX) -C target

patch: $(PKGDIRNAME)
	@cd $(PKGDIRNAME) && find ../patches -type f -name '*.patch' -print0 | sort -z | xargs -t -0 -n 1 patch --verbose -p1 -i

npm_download: extract
	@cd $(PKGDIRNAME) && npm install --production

npm_verify: npm_download
	cat $(NPMS) | sha256sum -c

regenerate_sums: npm_download
	@echo Generating NEW checksums...
	find $(PKGDIRNAME)/node_modules/ -type f -exec sha256sum {} \; > $(NPMS)

extract: $(PKGDIRNAME)
$(PKGDIRNAME): verify
	mkdir -p $(PKGDIRNAME) && tar zxf $(PKGARCHIVE) -C $(PKGDIRNAME) --strip-components 1

download: $(PKGARCHIVE)
$(PKGARCHIVE):
	@echo Getting package release $(PKGVER)...
	curl -# -L -O $(PKGPATH)$(PKGARCHIVE)

verify: $(PKGARCHIVE)
	@echo Verifying package checksum...
	echo "$(PKGSHA256) $(PKGARCHIVE)" | sha256sum -c

setup:
	sudo --validate
	sudo yum update -y
	test -e /etc/yum.repos.d/nodesource-el7.repo || curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
	sudo yum install -y git unzip rpm-build nodejs gcc gcc-c++ patch autoconf automake bison libffi-devel libtool readline-devel sqlite-devel zlib-devel openssl-devel
	@# This command comes from the rvm installer.  However, since keyservers are garbage, it's no good to us anymore.
	@#gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
	@# Instead, we import directly from the RVM folks:
	curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
	curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
	@# Now that there are keys, install rvm (local to this directory):
	test -e ~/.rvm/scripts/rvm || curl -sSL https://get.rvm.io | bash -s stable
	@# Install a ruby version high enough to support fpm:
	~/.rvm/bin/rvm install $(RUBY_VERSION)
	@# Lastly, install fpm:
	~/.rvm/bin/rvm $(RUBY_VERSION) do gem install --no-document fpm

.PHONY: all fpm patch clean verify download extract npm_verify npm_download regenerate_sums setup
clean:
	-rm -vf $(PKGARCHIVE)
	-rm -rvf $(PKGDIRNAME)
	-rm -rvf target
	-rm -vf *.rpm
