prefix = /usr/local

all:
	./po2mo.sh

lint:
	perlcritic --profile .perlcriticrc bin/ share/shutter/resources/modules/ t/

test:
	prove -Ishare/shutter/resources/modules -It/lib -r t/

map:
	./scripts/map_dependencies.pl > DEPENDENCIES.md
	sed -i '1i# Dependency Map\n\n```mermaid' DEPENDENCIES.md
	echo '```' >> DEPENDENCIES.md

tidy:
	perltidy -b bin/rshot $$(find share/shutter/resources/modules/ -name "*.pm") $$(find t/ -name "*.t")

clean:
	if [ -d $(srcdir)share/locale ]; then \
		rm -r $(srcdir)share/locale; \
	fi
install: all
	install -Dm644 $(srcdir)COPYING $(prefix)/share/doc/rshot/COPYING
	install -Dm644 $(srcdir)README $(prefix)/share/doc/rshot/README
	install -Dm755 $(srcdir)bin/rshot $(prefix)/bin/rshot
	cp -r $(srcdir)share/ $(prefix)/

uninstall:
	rm $(prefix)/bin/rshot
	rm $(prefix)/share/metainfo/rshot.metainfo.xml
	rm $(prefix)/share/applications/rshot.desktop
	rm -r $(prefix)/share/doc/rshot/
	rm $(prefix)/share/man/man1/rshot.1
	rm $(prefix)/share/pixmaps/rshot.png
	rm -r $(prefix)/share/shutter/
	rm $(prefix)/share/icons/HighContrast/scalable/apps/rshot.svg
	rm $(prefix)/share/icons/HighContrast/scalable/apps/rshot-panel.svg
	for size in 128x128  16x16  192x192  22x22  24x24  256x256  32x32  36x36  48x48  64x64  72x72  96x96; do \
		rm $(prefix)/share/icons/hicolor/$$size/apps/rshot.png; \
	done
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
