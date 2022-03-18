#@maintainer gene@mozilla.com
#@update 2020-11-09

# Required RPM packages:
# fpm
# rpm-build
# mono-devel
# nodejs

#If you change the PKGVER ensure the module list in npm_modules.sha256sum is accurate

#This is the ad-ldap-connector version
PKGVER:= 5.0.13
#This is the packaging sub-release version
PKGREL:= 2
PKGSUFFIX:= -mozilla

PKGNAME:=ad-ldap-connector
PKGPATH:=https://github.com/auth0/ad-ldap-connector/archive/
PKGSHA256:=2145b00452fba817d9733c4dce44d2a6af69c80976cfbaf74cb0aa50a81a65f8
NPMS=npm_modules.sha256sum
RUBY_VERSION=2.7.2

PKGARCHIVE:=v$(PKGVER).tar.gz
PKGDIRNAME:=$(PKGNAME)-$(PKGVER)

#Required for the fancy checksumming
#with GNU Make we'd reach foreach's and patterns limits
SHELL:=/bin/bash

all: fpm

fpm: extract npm_verify patch
	#Creating package
	mkdir -p target/opt
	cp -vr $(PKGDIRNAME) target/opt/$(PKGNAME)
	mkdir -p target/usr/lib/systemd/system
	cp -v $(PKGNAME).service target/usr/lib/systemd/system
	~/.rvm/bin/rvm $(RUBY_VERSION) do fpm -s dir -t rpm \
		--rpm-user $(PKGNAME) --rpm-group $(PKGNAME) \
		--rpm-digest sha256 \
		--before-install pre-install.sh \
		--depends nodejs --depends npm \
		--iteration $(PKGREL) \
		--exclude opt/$(PKGNAME)/$(PKGNAME)-$(PKGVER)$(PKGSUFFIX) \
		-n $(PKGNAME) -v $(PKGVER)$(PKGSUFFIX) -C target

patch: $(PKGDIRNAME)
	@cd $(PKGDIRNAME) && find ../patches -type f -name '*.patch' -print0 | sort -z | xargs -t -0 -n 1 patch --verbose -p1 -i

npm_download: extract
	@cd $(PKGDIRNAME) && npm i --production

npm_verify: npm_download
	cat $(NPMS) | sha256sum -c

regenerate_sums: npm_download
	@echo Generating NEW checksums...
	find $(PKGDIRNAME)/node_modules/ -type f -exec sha256sum {} \; > npm_modules.sha256sum

extract: $(PKGDIRNAME)
$(PKGDIRNAME): verify
	tar xvzf $(PKGARCHIVE) || unzip $(PKGARCHIVE)

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
	gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
	test -e ~/.rvm/scripts/rvm || curl -sSL https://get.rvm.io | bash -s stable
	~/.rvm/bin/rvm install $(RUBY_VERSION)
	~/.rvm/bin/rvm $(RUBY_VERSION) do gem install --no-document fpm

.PHONY: all fpm patch clean verify download extract npm_verify npm_download regenerate_sums setup
clean:
	-rm $(PKGARCHIVE)
	-rm -r $(PKGDIRNAME)
	-rm -r target
	-rm *.rpm
