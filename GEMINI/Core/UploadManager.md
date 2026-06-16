# Shutter::App::Core::UploadManager

## Purpose
Manages file upload functionality to various hosting services.

## Location
`share/shutter/resources/modules/Shutter/App/Core/UploadManager.pm`

## Key Methods

### `new($common)`
Constructor. Takes a Common object for accessing application state.

### `upload_file($key, $upload_type)`
Uploads a screenshot to a configured hosting service.
- Retrieves file from session by key
- Uses configured upload plugin (FTP, ShareX, etc.)
- Stores result links in session

### `get_upload_links_menu($key, $menu_links)`
Generates menu with upload links for a screenshot.
- Creates menu items for each upload service
- Handles copy-to-clipboard actions

## Upload Plugins
- `Shutter::Upload::FTP` - Direct FTP upload
- `Shutter::Upload::ShareX` - ShareX-compatible services (Imgur, etc.)

## Account Configuration
Accounts stored in `~/.shutter/accounts.xml`:
```perl
%accounts = (
    $plugin_name => {
        'path' => '/path/to/plugin',
        'host' => 'hostname.com',
        'username' => 'user',
        'password' => 'encrypted',
        'module' => 'upload_module_name',
        'supports_oauth_upload' => 1,
    }
)
```

## Result Storage
```perl
$session_screens{$key}->{'links'} = {
    'direct_link' => 'https://...',
    'html_link' => 'https://...',
    'bbcode' => '[url=...]...',
}
```

## Dependencies
- `Shutter::Upload::FTP` - FTP implementation
- `Shutter::Upload::ShareX` - ShareX services
- `Shutter::App::SimpleDialogs` - Error dialogs

## Related
- See `Shutter::Upload::Shared` for common upload logic
- See `Shutter::App::SettingsManager` for account persistence