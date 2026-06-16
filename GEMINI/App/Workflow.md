# Shutter::App::Workflow

## Purpose
Initializes and coordinates the after-capture workflow system including the pipeline and pin-to-screen features.

## Location
`share/shutter/resources/modules/Shutter/App/Workflow.pm`

## Key Methods

### `new(cli => $cli)`
Constructor. Creates AfterCapturePipeline and PinToScreen objects.

### `get_workflow_widget()`
Returns the workflow configuration widget from AfterCapturePipeline.

## Attributes
- `cli` - Reference to CLI object
- `acp` - Shutter::App::AfterCapturePipeline instance
- `pins` - Shutter::App::PinToScreen instance

## Dependencies
- `Shutter::App::AfterCapturePipeline`
- `Shutter::App::PinToScreen`

## Related
- See `Shutter::App::AfterCapturePipeline` for pipeline execution
- See `Shutter::App::Init` for initialization