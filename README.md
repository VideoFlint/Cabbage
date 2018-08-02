![](https://ws1.sinaimg.cn/large/6ca4705bgy1ftvakl767wj215o07st9r.jpg)

[中文说明](https://github.com/VideoFlint/Cabbage/wiki/中文说明)

A high-level video composition framework build on top of AVFoundation. It's simple to use and easy to extend. Use it and make life easier if you are implementing video composition feature.

## Features

- Build result content objcet with only few step. 

1. Create resource  
2. Set configuration 
3. Generate AVPlayerItem/AVAssetImageGenerator/AVExportSession

- Resouce: Support video, audio, and image. Resource is extendable, you can create your customized resource type. e.g gif image resource
- Video configuration support: transform, speed, filter and so on. The configuration is extendable.
- Audio configuration support: change volume or process with audio raw data in real time, you can be a rocker. The configuration is extendable.
- Transition: Clips may transition with previous and next clip

## Requirements

- iOS 9.0+
- Swift 4.x

## Projects using Cabbage

- [VideoCat](https://github.com/vitoziv/VideoCat): A demo project demonstrates how to use Cabbage.

## Usage

Below is the simplest example. Create a resource from AVAsset, set the video frame's scale mode to aspect fill, then insert trackItem to timeline, after all use CompositionGenerator to build AVAssetExportSession/AVAssetImageGenerator/AVPlayerItem.

```Swift

// 1. Create a resource
let asset: AVAsset = ...     
let resource = AVAssetTrackResource(asset: asset)

// 2. Create a TrackItem instance, TrackItem can configure video&audio configuration
let trackItem = TrackItem(resource: resource)
// Set the video scale mode on canvas
trackItem.configuration.videoConfiguration.baseContentMode = .aspectFill

// 3. Add TrackItem to timeline
let timeline = Timeline()
timeline.videoChannel = [trackItem]
timeline.audioChannel = [trackItem]

// 4. Use CompositionGenerator to create AVAssetExportSession/AVAssetImageGenerator/AVPlayerItem
let compositionGenerator = CompositionGenerator(timeline: timeline)
// Set the video canvas's size
compositionGenerator.renderSize = CGSize(width: 1920, height: 1080)
let exportSession = compositionGenerator.buildExportSession(presetName: AVAssetExportPresetMediumQuality)
let playerItem = compositionGenerator.buildPlayerItem()
let imageGenerator = compositionGenerator.buildImageGenerator()

```

**Timeline**

Use to construct resource, the developer is responsible for putting resources at the right time range.

**CompositionGenerator**

Use CompositionGenerator to create AVAssetExportSession/AVAssetImageGenerator/AVPlayerItem

CompositionGenerator use Timeline instance translate to AVFoundation API.

**Resource**

Currently support

 - Image type: `ImageResource`, `PHAssetImageResource`
 - Video&Audio type: `AVAssetTrackResource`, `PHAssetTrackResource`

**TrackItem**

Currently support

- Change speed
- Video Configuration
    - baseContentMode, video frame's scale mode base on canvas size
    - transform
    - filterProcessor, apply custom video frame process operation
- Audio Configuration
    - volume
    - audioTapHolder, apply custom audio process operation 
- videoTransition, audioTransition


## Why I create this project

AVFoundation aready provide powerful composition API for video and audio, but these API are far away from easy to use.

**1.AVComposition**

We need to know how and when to connect different tracks. Say we save the time range info for a track, finnaly we will realize the time range info is very easy to broken, consider below scenarios

- Change previous track's time range info
- Change speed
- Add new track
- Add/remove transition

These operations will affect the timeline and all tracks' time range info need to be updated.

Bad thing is that AVComposition only supports video track and audio track. If we want to combine photo and video, it's very difficult to implement.

**2.AVVideoCompostion**

Use `AVVideoCompositionInstruction` to construct timeline, use `AVVideoCompositionLayerInstruction` to configure track's transform. If we want to operate raw video frame data, need implement `AVVideoCompositing` protocol.

After I write the code, I realized there are many codes unrelated to business logic, they should be encapsulated.

**3.Difffcult to extend features**

AVFoundation only supports a few basic composition features. As far as I know, it only can change video frame transform and audio volume. If a developer wants to implement other features, e.g apply a filter to a video frame, then need to rewrite AVVideoCompostion's `AVVideoCompositing` protocol. The workload suddenly become very large.

Life is hard why should I write hard code too? So I create Cabbage, easy to understand API, flexible feature scalability.

## Installation

**Cocoapods**

```
platform :ios, '9.0'
use_frameworks!

target 'MyApp' do
  # your other pod
  # ...
  pod 'VFCabbage'
end
```

**Manually**

It is not recommended to install the framework manually, but if you have to do it manually.
You can 

- simplely drag `Cabbage/Sources` folder to you project.
- Or add Cabbage as a submodule.

```
$ git submodule add https://github.com/VideoFlint/Cabbage.git
```

## LICENSE

Under MIT

## Special Thanks

- Icon designed by [熊猫先生](https://dribbble.com/viennaong)
