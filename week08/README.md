# week08 - Filter Cam

A camera app that applies Core Image filters to the live front camera video.

## Features

- live filtered preview from the front camera
- 9 filters: Normal, Noir, Comic, Pixel, Crystal, Thermal, Sepia, Twirl, Bloom
- strength slider for filters that support it (Pixel, Crystal, Sepia, Twirl, Bloom)
- camera button saves a filtered photo to the Photos library
- record button saves a filtered video to the Photos library
- recording timer shown at the top while recording

## Files

- `CameraModel.swift` - camera session, recording with AVAssetWriter, saving to Photos
- `Filters.swift` - list of filters and their settings
- `FrameView.swift` - draws the latest camera frame
- `ContentView.swift` - the screen: slider, filter buttons, photo and record buttons

## Notes

- based on the 08-CameraRecorder class example
- needs a real iPhone, the simulator has no camera
- uses @Observable, no Combine needed for the model
