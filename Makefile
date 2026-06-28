# Makefile - developer-mode install only.
# For Debian packaging, see debian/rules. The two layouts coexist:
#   * `make install` (this Makefile) installs Perl modules to $(prefix)/share/perl5/Shutter/
#     and resources to $(prefix)/share/shutter/. Use this for `carton exec` / dev installs.
#   * `dpkg-buildpackage` (Phase 2) installs into /usr/{bin,share} per Debian policy.
# Both layouts install to the same Perl @INC namespace (Shutter::*).

prefix = /usr/local
perl5dir = $(prefix)/share/perl5

all:
	./po2mo.sh

lint:
	perlcritic --profile .perlcriticrc bin/ share/shutter/perl/ t/

test:
	prove -Ishare/shutter/perl -It/lib -r t/

map:
	./scripts/map_dependencies.pl > DEPENDENCIES.md
	sed -i '1i# Dependency Map\n\n```mermaid' DEPENDENCIES.md
	echo '```' >> DEPENDENCIES.md

tidy:
	perltidy -b bin/rshot $$(find share/shutter/perl/ -name "*.pm") $$(find t/ -name "*.t")

sbom:
	cpan-sbom \
		--project-directory . \
		--project-name "RShot" \
		--project-type application \
		--project-version "1 (Rev.1876)" \
		--project-license GPL-3.0-or-later \
		--project-author "Shutter Contributors" \
		--project-description "A GTK-based screenshot tool for Linux" \
		-o bom.json

clean:
	if [ -d $(srcdir)share/locale ]; then \
		rm -r $(srcdir)share/locale; \
	fi
install: all
	install -Dm644 $(srcdir)COPYING $(prefix)/share/doc/rshot/COPYING
	install -Dm644 $(srcdir)README $(prefix)/share/doc/rshot/README
	install -Dm755 $(srcdir)bin/rshot $(prefix)/bin/rshot
	install -Dm644 $(srcdir)share/pixmaps/rshot-logo.png $(prefix)/share/pixmaps/rshot-logo.png
	# Perl modules -> /usr/local/share/perl5/ (Debian Perl Policy §2.3)
	install -d $(perl5dir)
	cp -r $(srcdir)share/shutter/perl/Shutter $(perl5dir)/
	install -d $(perl5dir)/X11/Protocol/Ext
	install -m644 $(srcdir)share/shutter/perl/X11/Protocol/Ext/XFIXES.pm $(perl5dir)/X11/Protocol/Ext/XFIXES.pm
	# Data resources -> /usr/local/share/shutter/resources/ (icons, credits, license, po, etc.)
	install -d $(prefix)/share/shutter/resources
	cp -r $(srcdir)share/shutter/resources/. $(prefix)/share/shutter/resources/

uninstall:
	rm -f $(prefix)/bin/rshot
	rm -f $(prefix)/share/pixmaps/rshot-logo.png
	rm -rf $(prefix)/share/doc/rshot
	rm -rf $(prefix)/share/perl5/Shutter
	rm -f $(perl5dir)/X11/Protocol/Ext/XFIXES.pm
	rm -rf $(prefix)/share/shutter
	for size in 16x16 22x22 24x24; do \
		rm $(prefix)/share/icons/hicolor/$$size/apps/rshot-panel.png; \
	done
	rm $(prefix)/share/icons/hicolor/scalable/apps/rshot-panel.svg
	rm $(prefix)/share/icons/hicolor/scalable/apps/rshot.svg
	for locale in $(prefix)/share/locale/*; do \
		for mofile in shutter.mo shutter-plugins.mo shutter-upload-plugins.mo; do \
			if [ -f $$locale/LC_MESSAGES/$$mofile ]; then \
				rm $$locale/LC_MESSAGES/$$mofile; \
			fi \
		done \
	done
