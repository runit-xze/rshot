# Debian packaging plan for rshot

Goal: package rshot for inclusion into Debian `main`, DFSG-compliant, lintian-clean,
reproducible. No ITP until the package is fully buildable and verified on a real
Debian system.

Maintainer: Ashley Brooks <runit@runit.lol>
Upstream:   https://github.com/runit-xze/rshot
Source fmt: 3.0 (quilt), non-native
Section:    graphics
Priority:   optional
Sponsor:    TBD after package is ready

---

## Phase 1 — Module layout migration

**Goal:** rshot's `.pm` files live at `share/shutter/resources/modules/Shutter/...`
and `bin/rshot` adds that to `@INC` via `use lib File::Spec->catdir(...)`.
Move them to `/usr/share/perl5/Shutter/...` per Perl Policy §2.3 so
`use Shutter::App::CLI` works without any `use lib` shim.

| Action | Detail |
|---|---|
| Edit `bin/rshot` | Remove the `use lib File::Spec->catdir(...)` block; `use Shutter::App::CLI;` now works directly. |
| Edit `Makefile install` | Split install into two pieces: perl modules → `/usr/share/perl5/`, resources → `/usr/share/shutter/resources/`. |
| Move `share/shutter/resources/modules/Shutter/` | To `share/shutter/perl/Shutter/` in source (to separate code from data). Installed to `/usr/share/perl5/Shutter/` (note: the package name on disk is `Shutter/`, not the source dir name). |
| Update tests | `t/` files that do `use lib "..."` to find modules need updating to use the new source layout. |
| Verify | `perl -I share/shutter/perl -c share/shutter/perl/Shutter/App/CLI.pm` should still parse; `bin/rshot --help` works. |
| Don't change | The `share/shutter/resources/{icons,credits,license,conf,gui,po,system}/` tree — that's data, not Perl code, and stays under `/usr/share/shutter/resources/`. |

**Rationale for `share/shutter/perl/` not `share/perl5/`:** the source still lives
in the rshot project tree, just under a clearer dir name. `/usr/share/perl5/` is
the *install* path only; source layout is free.

---

## Phase 2 — `debian/` directory

### `debian/control`

```
Source: rshot
Maintainer: Ashley Brooks <runit@runit.lol>
Uploaders:  <empty until sponsor>
Section: graphics
Priority: optional
Build-Depends:
 debhelper-compat (= 13),
 perl,
 libgtk-3-dev,
 libglib2.0-dev,
 libcairo2-dev,
 libpango1.0-dev,
 libgoocanvas-2.0-dev,
 libgtk-3-imageview-dev,
 libwnck-3-dev,
 libxml2-dev,
 intltool,
 po4a,
 dh-sequence-perl-native,
 libpath-tiny-perl (>= 0.076),
Standards-Version: 4.7.4.1
Rules-Requires-Root: no
Testsuite: autopkgtest
Homepage: https://github.com/runit-xze/rshot
Vcs-Browser: https://github.com/runit-xze/rshot
Vcs-Git: https://github.com/runit-xze/rshot.git

Package: rshot
Architecture: any
Depends:
 ${perl:Depends},
 ${misc:Depends},
 ${shlibs:Depends},
 libgtk-3-0 (>= 3.18),
 libgoocanvas-2.0-9,
 libgtk3-imageview-perl,
 libgoocanvas2-perl,
 libgtk3-perl,
 libmoo-perl,
 liblog-any-perl,
 libpath-tiny-perl,
 libwww-perl,
 libjson-maybexs-perl,
 libipc-run3-perl,
 libfuture-perl,
Recommends: libwnck-3-0 (>= 43.0), gnome-web-photo | python3-playwright
Suggests: imagemagick
Description: feature-rich screenshot tool with annotation
 rshot is a screenshot application for the Linux desktop, written in
 Perl with GTK3. It captures full screens, individual windows, arbitrary
 rectangular regions, or web pages from a URL; annotates the result with
 arrows, text, shapes, blur, censor, and freehand highlighter; and can
 upload directly to Catbox.moe, ImgBB, or any ShareX-compatible (.sxcu)
 hosting service.
 .
 The application integrates with the system tray, supports Wayland via
 xdg-desktop-portal, and persists session history, upload presets, and
 user settings in standard XDG paths under ~/.config/rshot.
```

### `debian/rules` (skeleton)

```make
#!/usr/bin/make -f
include /usr/share/dpkg/default.mk
include /usr/share/dpkg/architecture.mk

# Reproducibility: stamp every built file with the same mtime.
export DEB_BUILD_MAINT_OPTIONS = hardening=+all reproducible=+all
export DEB_BUILD_OPTIONS      = nostrip nocheck terse
export SOURCE_DATE_EPOCH      = $(shell date -u -d "@$$(git log -1 --format=%ct)" +%s 2>/dev/null || date -u +%s)

%:
	dh $@ --with perl_magic --builddirectory=build

override_dh_auto_configure:
	# No autoconf. The project is plain Perl.
	dh_auto_configure

override_dh_auto_build:
	dh_auto_build

override_dh_auto_install:
	dh_auto_install -- prefix=/usr

override_dh_install:
	# Move our Perl modules to /usr/share/perl5/Shutter/
	# (perl_magic helper or hand-rolled mv below)
	dh_install

override_dh_auto_clean:
	dh_auto_clean
	rm -rf build .debhelper

override_dh_installdocs:
	dh_installdocs --all CHANGES README.md

override_dh_installchangelogs:
	dh_installchangelogs CHANGES
```

### `debian/copyright`

Machine-readable DEP-5 format. Two parts:
- `Files: *` covering all original rshot Perl code (Copyright 2008-2013 Mario Kemper + 2025 Shutter Team, GPL-3+)
- `Files: share/shutter/resources/icons/*` separately noting which icons are rshot-original vs. system-theme derivative (need to audit; many icons are likely from GNOME icon theme and need upstream attribution)
- `Files: share/shutter/resources/license/gplv3` — copy GPL-3 verbatim into `/usr/share/common-licenses/GPL-3` reference

### `debian/source/format`

```
3.0 (quilt)
```

### `debian/upstream/signing-key.asc`

If upstream signs tags: `<GPG public key blob>`. rshot doesn't yet.

### `debian/watch`

```
version=4
https://github.com/runit-xze/rshot/tags .*/v?(\d[\d.]*)\.tar\.gz
```

### `debian/gbp.conf` (optional)

```
[DEFAULT]
debian-branch = debian/main
upstream-branch = upstream/latest
pristine-tar = True
sign-tags = True
```

---

## Phase 3 — Reproducibility

Per §4.15, packages MUST build bit-for-bit identically. Real risks for rshot:

| Source of non-determinism | Fix |
|---|---|
| Timestamps embedded in `.pm` files (POD `=head1 NAME` doesn't include dates, but generated `.mo` files do) | `find build -exec touch -d "@$SOURCE_DATE_EPOCH" {} +` before packing. Set `find ... -print0 \| LC_ALL=C sort -z` for file order. |
| `intltool` produces files in arbitrary order | Wrap in `LC_ALL=C sort` calls in `debian/rules`. |
| Perl's `Module::Build`-style `Build` script output order | Use `make -j1 DESTDIR=... install` and sort `find` output. |
| The `rshot-logo.png` binary | Already a fixed blob; verify sha256. |
| Compiled `.pyc` or similar | rshot has none. |

**Verification command:**
```
sbuild --build-dep-resolver=apt -d bookworm-amd64 ../rshot_<version>-1.dsc
sbuild --build-dep-resolver=apt -d bookworm-amd64 ../rshot_<version>-1.dsc
diff -r build1/ build2/
strip-nondeterminism /path/to/rshot_<version>-1_amd64.deb
```

Must produce zero diff. CI integration: `.github/workflows/reprobuild.yml`
runs sbuild twice and posts a job summary.

---

## Phase 4 — Lintian cleanliness

Lintian tags we know will fire without work. Each needs fixing:

| Tag | Why it fires | Fix |
|---|---|---|
| `no-copyright-file` | `debian/copyright` missing | Write DEP-5 file. |
| `no-manual-page` | `rshot` has no `.1` | Write `debian/manpages/rshot.1` from the help text; install as `/usr/share/man/man1/rshot.1.gz`. |
| `package-installs-python-egg` | rshot doesn't | n/a |
| `script-with-language-extension` | `bin/rshot` has no extension | Rename to `rshot` in install path (not `rshot.pl`). |
| `unstripped-binary-or-object` | Default Debian strip runs | `nostrip` only in `DEB_BUILD_OPTIONS` for now (skip); or set `DEB_BUILD_OPTIONS+=nostrip` and rely on reproducible-builds tooling. |
| `extended-description-is-empty` | Synopsis vs long | Ensure both lines exist in Description. |
| `description-synopsis-starts-with-package-name` | "rshot - feature-rich..." | Drop "rshot -" prefix per §3.4.1. |
| `binary-without-manpage` | Same as no-manual-page | Fix manpage. |
| `desktop-entry-lacks-key` | Existing `.desktop` file | Ensure `Categories=`, `Exec=`, `Icon=` present. |
| `package-contains-broken-symlink` | rshot's `share/` tree has dangling symlinks? | Audit `find . -type l ! -exec test -e {} \;`. |
| `image-file-in-usr-lib` | If `.pm` files end up under `/usr/lib/.../perl/...` | Force to `/usr/share/perl5/` per Phase 1. |
| `possibly-insecure-handling-of-tmp-files` | If `mkdir /tmp/...` | Already converted to `File::Temp::tempdir` in earlier pass. |
| `package-contains-empty-directory` | `share/shutter/resources/{conf,po,...}` possibly | `find -type d -empty -delete` in `debian/rules`. |
| `changelog-file-empty-exception` | rare | verify. |
| `missing-build-dependency` | Specific build tools | Resolve with `apt build-dep`. |
| `depends-on-obsolete-package` | If we list `libgtk2-perl` anywhere | Use `libgtk3-perl` only. |
| `package-name-doesnt-match-soname` | n/a for Perl | n/a |

**Verification:**
```
lintian -iIE --pedantic --color=auto ../rshot_<ver>-1_amd64.changes
```
Target: 0 E, 0 W, only I tags with rationale.

---

## Phase 5 — Source format 3.0 (quilt), orig tarball

`debian/source/format` says `3.0 (quilt)`. That means we need:

1. **An upstream tarball**: `rshot_<version>.orig.tar.gz` containing everything EXCEPT `debian/`. Generated via:
   ```
   git tag v1.2.3   # or whatever
   git archive --format=tar.gz --prefix=rshot-1.2.3/ -o ../rshot_1.2.3.orig.tar.gz HEAD
   ```
   Or simpler, `git archive` with `debian/` excluded:
   ```
   git archive --format=tar.gz --prefix=rshot-1.2.3/ \
       --worktree-attributes \
       HEAD ':!debian' \
       -o ../rshot_1.2.3.orig.tar.gz
   ```

2. **`debian/changelog`** with a `-1` Debian revision:
   ```
   rshot (1.2.3-1) unstable; urgency=medium

     * Initial Debian package.
     * Source modules installed under /usr/share/perl5/Shutter/
     * Migration away from `use lib` shim (closes: #XXXXXX).
     * Module layout per Debian Perl Policy §2.3.

    -- Ashley Brooks <runit@runit.lol>  Mon, 28 Jun 2026 04:30:00 +0000
   ```

3. **No patches initially** — initial packagings rarely need any. If we later need a patch (e.g., for a debian-specific build option), `dpkg-source --before-build` will run `quilt pop` and `dpkg-source --after-build` will run `quilt push` automatically. Empty `debian/patches/` directory is fine.

4. **`debian/README.source`** (recommended since layout is non-trivial): explains the `share/shutter/perl/` → `/usr/share/perl5/Shutter/` mapping.

---

## Phase 6 — Deprecate the legacy Makefile install

The `Makefile install`/`uninstall` targets should stay for developer convenience
(they install into `/usr/local/`) but should NOT be how the Debian package is built.
The Makefile's `install` target becomes "developer-mode install only".

- `Makefile`: add a comment that says "For packaging, see `debian/rules`. These targets are for `make install` into `$prefix`."
- Update README to point at `debian/README.source` for the packaging layout.

---

## Phase 7 — CI verification

`.github/workflows/debian.yml`:

```yaml
name: Debian build verification
on: [push, pull_request]
jobs:
  sbuild:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install sbuild dependencies
        run: sudo apt install -y sbuild mmdebstrap
      - name: Build with sbuild (reproducible round 1)
        run: |
          git tag v$(date +%Y%m%d).test  # dummy upstream tag
          git archive --format=tar.gz --prefix=rshot-test/ HEAD ':!debian' -o /tmp/rshot-test.orig.tar.gz
          cp -r debian /tmp/debian
          cd /tmp && tar -xf rshot-test.orig.tar.gz
          cp -r debian rshot-test/
          cd /tmp && dpkg-source -b rshot-test
          sbuild --build-dep-resolver=apt -d bookworm-amd64 /tmp/rshot-test.dsc
          cp /tmp/rshot-test.build1.deb /tmp/rshot-test-1.deb
      - name: Build with sbuild (reproducible round 2)
        run: sbuild --build-dep-resolver=apt -d bookworm-amd64 /tmp/rshot-test.dsc
      - name: Diff .debs
        run: |
          cmp /tmp/rshot-test-1.deb /tmp/rshot-test-2.deb && echo "REPRODUCIBLE ✓"
      - name: Lintian
        run: lintian --info --display-info --display-experimental --pedantic /tmp/rshot-test*.changes
```

---

## Phase 8 — Final docs & ITP

When the above passes:

1. **Add `PACKAGING.md`** to the repo explaining:
   - "This package is in preparation for Debian inclusion. See `DEBIAN_PACKAGING_PLAN.md` for the roadmap."
   - Link to Salsa repository (will need to be created)
   - Link to bugs.debian.org WNPP page for the ITP

2. **Run `node /tmp/rshot-debian-cli.mjs bts_intent ...`** to draft the ITP.

3. **Commit + push.** No `git push` to origin until the package is buildable on
   a clean Debian bookworm sbuild.

---

## Open questions

- **Tests in autopkgtest?** §5.6.30 `Testsuite:` field implies an autopkgtest
  control file (`debian/tests/control`). rshot has `t/` but those are Perl
  Test::More tests, not autopkgtest. Decide later whether to add a smoke test
  that runs `rshot --help`.
- **Translation workflow?** rshot has `po/` files but `intltool` integration is
  ad-hoc. The Debian package should use `po4a` for `*.po` → `*.mo` and ship them
  via `Depends: locales \| locales-all`. Not blocking, but worth doing.
- **AppStream metainfo?** `org.shutter_project.Shutter.json` exists for Flatpak;
  a `.metainfo.xml` would make rshot show up nicely in software centers. Add
  to Phase 8 as nice-to-have.
- **Multi-Arch?** §5.6.34. rshot is `Architecture: any` because the `.pm` files
  reference XS modules that need `libgoocanvas2-perl` etc. — those are
  arch-dependent. `Multi-Arch: foreign` would let us co-install with
  `libgoocanvas2-perl:any`. Investigate during Phase 4.

---

## Success criteria (gate for ITP)

- [ ] `dpkg-buildpackage -us -uc -b` builds clean
- [ ] `lintian -iIE --pedantic *.changes` returns 0 errors, 0 warnings
- [ ] Two sbuild runs produce bit-identical .debs
- [ ] `apt install ./rshot_*.deb` on a clean bookworm produces a working `rshot --help`
- [ ] `debian/copyright` is DEP-5-compliant (machine-readable)
- [ ] `debian/manpages/rshot.1` exists and `man 1 rshot` works
- [ ] All `Build-Depends:` resolve on bookworm
- [ ] `rshot` does not appear in WNPP already
