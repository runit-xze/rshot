package Shutter::Draw::StateManager;
use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

sub init_state {
    my $self = shift;
	$self->{_shf} = Shutter::App::HelperFunctions->new($self->{_sc});

	require Shutter::Draw::ToolbarManager;
	$self->{_toolbar_manager} = Shutter::Draw::ToolbarManager->new(drawing_tool => $self);

	require Shutter::Draw::ContextMenuManager;
	$self->{_context_menu_manager} = Shutter::Draw::ContextMenuManager->new(drawing_tool => $self);

	$self->{_toolbar_manager}->setup_view;



	#clipboard
	$self->{_clipboard} = Gtk3::Clipboard::get($Gtk3::Gdk::SELECTION_CLIPBOARD);

	#file
	$self->{_filename}    = undef;
	$self->{_filetype}    = undef;
	$self->{_mimetype}    = undef;
	$self->{_import_hash} = undef;

	#custom cursors
	$self->{_cursors} = undef;

	#ui
	$self->{_uimanager} = undef;
	$self->{_factory}   = undef;

	#canvas
	$self->{_canvas} = undef;

	#all items are stored here
	$self->{_uid}           = time;
	$self->{_items}         = undef;
	$self->{_items_history} = undef;

	#undo and redo stacks
	$self->{_undo} = undef;
	$self->{_redo} = undef;

	#autoscroll option, disabled by default
	$self->{_autoscroll} = FALSE;

	#drawing colors and line width
	#general - shown in the bottom hbox
	$self->{_fill_color}         = Gtk3::Gdk::RGBA::parse('#0000ff');
	$self->{_fill_color}->alpha(0.25);
	$self->{_stroke_color}       = Gtk3::Gdk::RGBA::parse('#ff0000');
	$self->{_stroke_color}->alpha(1);
	$self->{_line_width}         = 3;
	$self->{_font}               = "Sans Regular 16";

	#obtain current colors and font_desc from the main window
	$self->{_style}    = $self->{_sc}->get_mainwindow->get_style_context;
	$self->{_style_bg} = $self->{_style}->get_background_color('selected');
	$self->{_style_bg}->alpha(1);
	#$self->{_style_tx} = $self->{_style}->text('selected');

	#remember drawing colors, line width and font settings
	#maybe we have to restore them
	$self->{_last_fill_color}         = Gtk3::Gdk::RGBA::parse('#0000ff');
	$self->{_last_fill_color}->alpha(0.25);
	$self->{_last_stroke_color}       = Gtk3::Gdk::RGBA::parse('#ff0000');
	$self->{_last_stroke_color}->alpha(1);
	$self->{_last_line_width}         = 3;
	$self->{_last_font}               = "Sans Regular 16";

	#some status variables
	$self->{_busy}                    = undef;
	$self->{_current_item}            = undef;
	$self->{_current_new_item}        = undef;
	$self->{_current_copy_item}       = undef;
	$self->{_last_mode}               = 10;
	$self->{_current_mode}            = 10;
	$self->{_current_mode_descr}      = "select";
	$self->{_current_pixbuf}          = undef;
	$self->{_current_pixbuf_filename} = undef;
	$self->{_cut}                     = FALSE;

	$self->{_start_time} = undef;

	$self->{_stipple_pixbuf} = Gtk3::Gdk::Pixbuf->new_from_file($self->{_sc}->get_root . '/share/shutter/resources/gui/stipple.png');

	print "DrawingTool initialized\n" if $self->{_sc}->get_debug;




	
}

1;
