include /usr/share/dpkg/pkg-info.mk

PACKAGE=libpve-storage-perl
BUILDDIR ?= $(PACKAGE)-$(DEB_VERSION)

GITVERSION:=$(shell git rev-parse HEAD)

DEB=$(PACKAGE)_$(DEB_VERSION_UPSTREAM_REVISION)_all.deb

all:

.PHONY: dinstall
dinstall: deb
	dpkg -i $(DEB)

$(BUILDDIR):
	rm -rf $@ $@.tmp
	cp -a src $@.tmp
	cp -a debian $@.tmp/
	echo "git clone git://git.proxmox.com/git/pve-storage.git\\ngit checkout $(GITVERSION)" >$@.tmp/debian/SOURCE
	mv $@.tmp $@

.PHONY: deb
deb: $(DEB)
$(DEB): $(BUILDDIR)
	cd $(BUILDDIR); dpkg-buildpackage -b -us -uc
	lintian $(DEB)

.PHONY: clean distclean
distclean: clean
clean:
	rm -rf $(PACKAGE)-[0-9]*/ *.deb *.dsc *.build *.buildinfo *.changes $(PACKAGE)*.tar.*

.PHONY: upload
upload: $(DEB)
	tar cf - $(DEB) | ssh -X repoman@repo.proxmox.com -- upload --product pve --dist bullseye
