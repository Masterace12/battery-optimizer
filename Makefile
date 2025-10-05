# Makefile for Steam Deck Power Manager

.PHONY: install uninstall clean package

prefix ?= /usr/local
sysconfdir ?= /etc
localstatedir ?= /var

install:
	# Create directories
	install -dm755 $(DESTDIR)$(prefix)/lib/steamdeck-power-manager/
	install -dm755 $(DESTDIR)$(sysconfdir)/steamdeck-power-manager/
	install -dm755 $(DESTDIR)$(localstatedir)/lib/steamdeck-power-manager/
	install -dm755 $(DESTDIR)$(localstatedir)/log/steamdeck-power-manager/
	install -dm755 $(DESTDIR)$(sysconfdir)/systemd/system/
	
	# Install Python modules
	cp -r steamdeck_power_manager/core $(DESTDIR)$(prefix)/lib/steamdeck-power-manager/
	cp -r steamdeck_power_manager/control $(DESTDIR)$(prefix)/lib/steamdeck-power-manager/
	cp -r steamdeck_power_manager/utils $(DESTDIR)$(prefix)/lib/steamdeck-power-manager/
	cp steamdeck_power_manager/__init__.py $(DESTDIR)$(prefix)/lib/steamdeck-power-manager/
	
	# Install configuration
	install -m644 steamdeck_power_manager/config/default_config.json $(DESTDIR)$(sysconfdir)/steamdeck-power-manager/config.json
	
	# Install systemd services
	install -m644 steamdeck_power_manager/service/steamdeck-power-manager-monitor.service $(DESTDIR)$(sysconfdir)/systemd/system/
	install -m644 steamdeck_power_manager/service/steamdeck-power-manager-control.service $(DESTDIR)$(sysconfdir)/systemd/system/
	
	# Install wrapper script
	install -m755 steamdeck-power-manager.sh $(DESTDIR)$(prefix)/bin/

uninstall:
	# Remove systemd services
	rm -f $(DESTDIR)$(sysconfdir)/systemd/system/steamdeck-power-manager-monitor.service
	rm -f $(DESTDIR)$(sysconfdir)/systemd/system/steamdeck-power-manager-control.service
	
	# Remove configuration
	rm -rf $(DESTDIR)$(sysconfdir)/steamdeck-power-manager/
	
	# Remove Python modules
	rm -rf $(DESTDIR)$(prefix)/lib/steamdeck-power-manager/
	
	# Remove wrapper script
	rm -f $(DESTDIR)$(prefix)/bin/steamdeck-power-manager.sh

clean:
	rm -rf dist/

# Create AUR-ready tarball
package:
	@echo "Creating release tarball..."
	@tar --exclude='.git' --exclude='*.tar.gz' --exclude='dist' -czf steamdeck-power-manager-$(shell date +%Y%m%d).tar.gz .
	@mkdir -p dist/
	@mv steamdeck-power-manager-*.tar.gz dist/
	@echo "Tarball created in dist/ directory"

# Calculate SHA256 checksum for PKGBUILD
checksum:
	@echo "Calculating checksum for latest tarball..."
	@sha256sum dist/steamdeck-power-manager-*.tar.gz