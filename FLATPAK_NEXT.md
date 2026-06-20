# rshot Flatpak — Next Steps

This document tracks remaining work to get `rshot` building, testing, and publishing
as a Flatpak on Flathub. Pick up here after the initial manifest scaffolding is done.

---

## Status Snapshot

| Item | Status |
|---|---|
| `org.shutter_project.Shutter.json` manifest skeleton | ✅ Done |
| `generated-sources.json` (CPAN deps + SHA256s) | ✅ Done |
| XDG Portal backend for screenshots | ✅ Done |
| Wayland / Flatpak environment detection | ✅ Done |
| `flatpak-builder` test build | ❌ Not started |
| GooCanvas2 Perl binding in manifest | ❌ Not started |
| Gtk3::ImageView Perl binding in manifest | ❌ Not started |
| PipeWire ScreenCast backend (video on Wayland) | ❌ Not started |
| `.desktop` file + AppStream metainfo | ❌ Needs review |
| Flathub submission PR | ❌ Not started |

---

## Step 1 — Install flatpak-builder and do a test build

```bash
sudo apt install flatpak-builder flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.gnome.Platform//45 org.gnome.Sdk//45
```

Then do a local build (sandboxed, no install):

```bash
flatpak-builder --sandbox --force-clean build-dir org.shutter_project.Shutter.json
```

The first build will take a long time (~30 min) as it compiles Perl 5.40 from
source inside the sandbox. Subsequent builds are cached.

> [!TIP]
> Use `--jobs=$(nproc)` to speed up the Perl compile step.

---

## Step 2 — Fix the `perl-libs` module sources

The current `perl-libs` module in the manifest has a placeholder `sources` block.
It needs to be replaced with the actual contents of `generated-sources.json` inlined,
**or** restructured so `flatpak-builder` can read the generated file as an include.

The cleanest approach (used by other Flathub Perl apps) is to make `generated-sources.json`
a sibling file and reference it directly in the manifest as a second sources array:

```json
{
    "name": "perl-libs",
    "buildsystem": "simple",
    "build-commands": [
        "bash perl-libs/install.sh",
        "chmod -R u+w /app/lib/perl5"
    ],
    "sources": "generated-sources.json"
}
```

> [!IMPORTANT]
> `flatpak-builder` supports a string path for `sources` that points to a JSON
> file containing a sources array. Confirm the version you have supports this —
> it was added in flatpak-builder 1.2.x.

---

## Step 3 — Add missing Perl XS bindings as modules

Two Perl modules used by rshot are not in the GNOME runtime and cannot be installed
from CPAN alone — they are Perl bindings to C libraries that must be compiled
**against the SDK's system headers** as dedicated Flatpak modules.

### 3a. GooCanvas2

`GooCanvas2` is a Perl binding to `libgoocanvas-2.0`. The C library is available in
the GNOME SDK but the Perl wrapper must be compiled inside the sandbox.

Add this module to the manifest **before** the `shutter` module:

```json
{
    "name": "perl-GooCanvas2",
    "buildsystem": "simple",
    "build-commands": [
        "perl Makefile.PL PREFIX=${FLATPAK_DEST}",
        "make",
        "make install"
    ],
    "sources": [
        {
            "type": "archive",
            "url": "https://cpan.metacpan.org/authors/id/P/PM/PMICHAUD/GooCanvas2-0.06.tar.gz",
            "sha256": "<run: curl -sL <url> | sha256sum>"
        }
    ]
}
```

> [!NOTE]
> Run `curl -sL <url> | sha256sum` to get the real SHA256 before committing.

### 3b. Gtk3::ImageView

`Gtk3::ImageView` wraps `libgtk-3-dev`. Same approach as above — find the CPAN
tarball URL, get its SHA256, and add a dedicated build module.

```json
{
    "name": "perl-Gtk3-ImageView",
    "buildsystem": "simple",
    "build-commands": [
        "perl Makefile.PL PREFIX=${FLATPAK_DEST}",
        "make",
        "make install"
    ],
    "sources": [
        {
            "type": "archive",
            "url": "https://cpan.metacpan.org/authors/id/I/IM/IMAGER/Gtk3-ImageView-10.tar.gz",
            "sha256": "<run: curl -sL <url> | sha256sum>"
        }
    ]
}
```

---

## Step 4 — PipeWire ScreenCast backend (Wayland video recording)

Video recording on Wayland requires the `org.freedesktop.portal.ScreenCast` D-Bus
portal instead of `x11grab`. This is a significant backend addition to
`Shutter::Screenshot::VideoRecorder`.

### How it works

1. **Open a ScreenCast session** via D-Bus:
   `org.freedesktop.portal.ScreenCast.CreateSession`
2. **Select sources** (monitor, window, or both):
   `org.freedesktop.portal.ScreenCast.SelectSources`
3. **Start the session** and receive a PipeWire node ID + fd:
   `org.freedesktop.portal.ScreenCast.Start`
4. **Pass to ffmpeg**:
   ```
   ffmpeg -f pipewire -i <node_id> -c:v libx264 output.mp4
   ```

### Files to change

- `Shutter/Screenshot/VideoRecorder.pm` — add a `_use_pipewire` flag; when set,
  replace the `x11grab` input with a PipeWire fd source.
- `Shutter/App/Handlers/Screenshot_VideoRecord.pm` — detect Wayland/Flatpak and
  negotiate the ScreenCast portal session before launching `VideoRecorder`.
- `Shutter/Screenshot/Wayland.pm` — add a new `screencast_portal()` function
  analogous to the existing `xdg_portal()` screenshot function.

### Additional Flatpak finish-args needed

```json
"--talk-name=org.freedesktop.portal.ScreenCast",
"--device=all"
```

---

## Step 5 — Verify `.desktop` and AppStream metainfo

Flathub requires:

1. **A `.desktop` file** at `/app/share/applications/org.shutter_project.Shutter.desktop`
   with `StartupWMClass` set to `rshot`.
2. **An AppStream metainfo XML file** at
   `/app/share/metainfo/org.shutter_project.Shutter.metainfo.xml`

The metainfo file must include:
- `<id>org.shutter_project.Shutter</id>`
- `<name>`, `<summary>`, `<description>`
- At least one `<screenshot>` with a real URL
- A `<releases>` block with a version and date
- `<url type="homepage">` and `<url type="bugtracker">`
- `<content_rating type="oars-1.1"/>` (use `oars-tagger` tool to generate)

> [!IMPORTANT]
> Flathub CI will reject the submission if the metainfo file is missing or
> malformed. Run `appstream-util validate` locally before submitting.

---

## Step 6 — Flathub submission

1. Fork [https://github.com/flathub/flathub](https://github.com/flathub/flathub)
2. Create a new branch: `new-app/org.shutter_project.Shutter`
3. Add a directory `org.shutter_project.Shutter/` containing:
   - `org.shutter_project.Shutter.json`
   - `generated-sources.json`
   - Any other sidecar JSON files for additional modules
4. Open a Pull Request — Flathub bots will run CI automatically

> [!NOTE]
> Flathub reviewers will check that:
> - All source URLs are stable (no `git` type without a commit hash)
> - No bundled binaries
> - The app works correctly in the sandbox
> - Metainfo passes `appstream-util validate --nonet`

---

## Useful Commands Reference

```bash
# Local sandboxed build
flatpak-builder --sandbox --force-clean build-dir org.shutter_project.Shutter.json

# Install locally for testing
flatpak-builder --user --install --force-clean build-dir org.shutter_project.Shutter.json

# Run the locally installed Flatpak
flatpak run org.shutter_project.Shutter

# Run with Wayland forced
flatpak run --socket=wayland --env=GDK_BACKEND=wayland org.shutter_project.Shutter

# Validate AppStream metainfo
appstream-util validate share/metainfo/org.shutter_project.Shutter.metainfo.xml

# Generate OARS content rating
oars-tagger

# Re-run CPAN generator if deps change
PERL5LIB=~/perl5/lib/perl5 perl /tmp/flatpak-builder-tools/cpan/flatpak-cpan-generator-patched.pl \
  -o generated-sources.json <module list>
```

---

## Known Risks

| Risk | Mitigation |
|---|---|
| Perl 5.40 compile time is very long (~25 min cold) | Use `flatpak-builder` cache; only recompiles on source change |
| `perllocal.pod` conflicts between XS modules | All `Makefile.PL`-style installs must be in **one** `make install` invocation — the generated `install.sh` handles this |
| GNOME runtime version drift | Pin `runtime-version` in manifest; bump deliberately when testing a new SDK |
| PipeWire portal requires portal running on host | Works on GNOME 41+ / KDE Plasma 5.22+; older DEs may fall back gracefully |
