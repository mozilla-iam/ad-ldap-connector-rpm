#@maintainer gene@mozilla.com
#@update 2020-11-09

# If you change the PKGVER:
# * update PKGSHA256

# This is the ad-ldap-connector version
PKGVER:= 6.1.8
# This is the RPM's sub-release version ('iteration' in `fpm` parlance)
# Bump this when you repackage the same version of software differently.
# Reset to 1 when you upgrade.
PKGREL:= 3
PKGSUFFIX:= -mozilla

# When you update the PKGVER:
# * do `make download` to fetch the .tar.gz
# * do `sha256sum` on the .tar.gz you got and save it to PKGSHA256:
# * do `make verify` to check your work.
PKGSHA256:=85ab7d3570682fb592161ea4fab49a67409833deb60c4b4f8488ef08479bb950
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

# A directory that we will use as we build the package.
BUILDDIR=buildroot

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

FPM_INSTALLED = $(shell which fpm 2>/dev/null)
RVM_INSTALLED = $(shell which rvm 2>/dev/null)
ifneq (, $(FPM_INSTALLED))
  FPM_BIN = 'fpm'
endif
ifneq (, $(RVM_INSTALLED))
  FPM_BIN = "rvm $(RUBY_VERSION) do fpm"
endif
ifeq (, $(FPM_BIN))
  @echo "Unable to find fpm; try `make fpm-setup`?"
  exit 1
endif

# And here's the magic recipes:

# Make sure our build directory exists:
$(BUILDDIR):
	mkdir -p $@

download: $(BUILDDIR)/$(PKGARCHIVE)
$(BUILDDIR)/$(PKGARCHIVE): | $(BUILDDIR)
	@echo Getting package release $(PKGVER)...
	curl -# -L -o $(BUILDDIR)/$(PKGARCHIVE) -O $(PKGPATH)$(PKGARCHIVE)

verify: $(BUILDDIR)/$(PKGARCHIVE)
	@echo Verifying package checksum...
	echo "$(PKGSHA256) $(BUILDDIR)/$(PKGARCHIVE)" | sha256sum -c

extract: $(BUILDDIR)/$(PKGDIRNAME)
$(BUILDDIR)/$(PKGDIRNAME): $(BUILDDIR)/$(PKGARCHIVE) verify
	mkdir -p $(BUILDDIR)/$(PKGDIRNAME) && tar zxf $(BUILDDIR)/$(PKGARCHIVE) -C $(BUILDDIR)/$(PKGDIRNAME) --strip-components 1

npm_download: | $(BUILDDIR)/$(PKGDIRNAME)
	@cd $(BUILDDIR)/$(PKGDIRNAME) && npm install --production

all: rpm

rpm: npm_download | $(BUILDDIR)/$(PKGDIRNAME)
	# Creating package
	mkdir -p $(BUILDDIR)/target/opt
	cp -vr $(BUILDDIR)/$(PKGDIRNAME) $(BUILDDIR)/target/opt/$(PKGNAME)
	mkdir -p $(BUILDDIR)/target/usr/lib/systemd/system
	cp -v sources/ad-ldap-connector.service $(BUILDDIR)/target/usr/lib/systemd/system/
	$(FPM_BIN) -s dir -t rpm \
		--rpm-user $(PKG_USER) --rpm-group $(PKG_GROUP) \
		--rpm-digest sha256 \
		--before-install sources/pre-install.sh \
		--depends nodejs --depends npm \
		--iteration $(PKGREL) \
		--exclude opt/$(PKGNAME)/$(PKGNAME)-$(PKGVER)$(PKGSUFFIX) \
		--name $(PKGNAME) --version $(PKGVER)$(PKGSUFFIX) -C $(BUILDDIR)/target

fpm-setup:
	sudo --validate
	sudo yum update -y
	test -e /etc/yum.repos.d/nodesource-el7.repo || curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
	sudo yum install -y git unzip rpm-build nodejs gcc gcc-c++ autoconf automake bison libffi-devel libtool readline-devel sqlite-devel zlib-devel openssl-devel
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

.PHONY: all fpm clean verify download extract npm_download fpm-setup
clean:
	-rm -rvf $(BUILDDIR)
	-rm -vf *.rpm
