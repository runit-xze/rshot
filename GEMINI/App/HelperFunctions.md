# Shutter::App::HelperFunctions

## Purpose
Utility functions for file operations, string handling, and UI helpers.

## Location
`share/shutter/resources/modules/Shutter/App/HelperFunctions.pm`

## Key Methods

### File Operations
- `file_exists($filename)` - Check if file exists and is readable
- `folder_exists($folder)` - Check if directory exists
- `uri_exists($filename)` - Check if URI exists
- `file_executable($filename)` - Check if file is executable

### Path Handling
- `switch_home_in_file($filename)` - Replace ~ with $HOME
- `utf8_decode($string)` - Decode UTF-8 string

### String Operations
- `ncmp($a, $b)` - Natural comparison for version strings
- `nsort(@list)` - Natural sort
- `format_bytes($bytes)` - Format bytes to human readable

### External Commands
- `xdg_open($dialog, $link, $user_data)` - Open URL with xdg-open
- `xdg_open_mail($dialog, $mail, @user_data)` - Open mailto
- `nautilus_sendto($user_data)` - Send via email

### Program Info
- `usage()` - Print command line usage
- `icon_size($size)` - GTK icon size lookup (GTK2->GTK3 compat)
- `accel($str)` - Parse accelerator string

## Dependencies
- `Gtk3` - GUI for file dialogs
- `File::Copy` - File operations
- `File::Spec` - Path operations

## Usage
```perl
my $shf = Shutter::App::HelperFunctions->new($sc);
$shf->file_exists('/path/to/file');
$shf->xdg_open(undef, 'https://example.com');
```

## Related
- Used by `Shutter::App::Common` for state management