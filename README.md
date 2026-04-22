# ImageCompare

ImageCompare is a native macOS SwiftUI app for visually comparing two images. It is built for quick before/after checks, visual QA, and spotting pixel-level changes without leaving the desktop.

## Features

- Drag and drop or open separate **Before** and **After** images.
- Compare images with Slider, Side by Side, Overlay, and Difference modes.
- Zoom, pan, reset the view, and swap before/after images.
- Generate a difference view for quick change detection.
- Export the current comparison view as a PNG.

## Requirements

- macOS 14.0 or later
- Xcode 15 or later
- Swift 5

## Getting Started

1. Open `ImageCompare.xcodeproj` in Xcode.
2. Select the `ImageCompare` scheme.
3. Build and run with `Cmd+R`.

## Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| `Cmd+1` | Slider mode |
| `Cmd+2` | Side by Side mode |
| `Cmd+3` | Overlay mode |
| `Cmd+4` | Difference mode |
| `Cmd+O` | Open Before image |
| `Cmd+Shift+O` | Open After image |
| `Cmd+S` | Swap Before and After |
| `Cmd+0` | Reset zoom |
| `Cmd++` | Zoom in |
| `Cmd+-` | Zoom out |
| `Cmd+E` | Export current view |

## Project Structure

```text
ImageCompare/
  Models/        Comparison mode definitions
  Utilities/     Image processing helpers
  ViewModels/    App state and image-loading logic
  Views/         SwiftUI comparison and drop-zone views
```

## License

No license has been added yet.
