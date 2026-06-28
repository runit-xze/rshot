requires "Gtk3";
requires "Pango";
requires "Glib";
requires "Gtk3::ImageView";
requires "Net::DBus";
requires "GooCanvas2";
requires "Locale::gettext";
requires "Moo", ">= 2.0";
requires "Log::Any";
requires "Log::Any::Adapter";
requires "Log::Any::Adapter::Stderr";
requires "IPC::Run3";
requires "JSON::MaybeXS";
requires "LWP::UserAgent";
requires "Path::Tiny";
requires "URI";
requires "URI::Escape";
requires "X11::Protocol";
requires "Future";

test_requires "Test::MockModule";
test_requires "Test::Strict";
test_requires "Perl::Critic";
test_requires "Test::Perl::Critic";

develop_requires "App::CPAN::SBOM";
