//
//  ViewController.swift
//  Cabbage
//
//  Created by Vito on 2018/7/28.
//  Copyright © 2018 Vito. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playerItem: AVPlayerItem? = {
            if indexPath.row == 1 {
                return overlayPlayerItem()
            } else if indexPath.row == 2 {
                return transitionPlayerItem()
            } else if indexPath.row == 3 {
                return keyframePlayerItem()
            } else if indexPath.row == 4 {
                return fourSquareVideo()
            } else if indexPath.row == 5 {
                return testReaderOutput()
            } else if indexPath.row == 6 {
                return reversePlayerItem()
            } else if indexPath.row == 7 {
                return twoVideoPlayerItem()
            }
            return simplePlayerItem()
        }()
        if let playerItem = playerItem {
            let controller = AVPlayerViewController()
            controller.player = AVPlayer.init(playerItem: playerItem)
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: - Demo
    
    func simplePlayerItem() -> AVPlayerItem? {
        let bambooTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "bamboo", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let timeline = Timeline()
        timeline.videoChannel = [bambooTrackItem]
        timeline.audioChannel = [bambooTrackItem]
        timeline.renderSize = CGSize(width: 1920, height: 1080)
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    func overlayPlayerItem() -> AVPlayerItem? {
        let bambooTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "bamboo", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let timeline = Timeline()
        timeline.videoChannel = [bambooTrackItem]
        timeline.audioChannel = [bambooTrackItem]
        
        timeline.passingThroughVideoCompositionProvider = {
            let imageCompositionGroupProvider = ImageCompositionGroupProvider()
            let url = Bundle.main.url(forResource: "overlay", withExtension: "jpg")!
            let image = CIImage(contentsOf: url)!
            let resource = ImageResource(image: image, duration: CMTime.init(seconds: 3, preferredTimescale: 600))
            let imageCompositionProvider = ImageOverlayItem(resource: resource)
            imageCompositionProvider.startTime = CMTime(seconds: 1, preferredTimescale: 600)
            let frame = CGRect.init(x: 100, y: 500, width: 400, height: 400)
            imageCompositionProvider.videoConfiguration.contentMode = .custom
            imageCompositionProvider.videoConfiguration.frame = frame;
            imageCompositionProvider.videoConfiguration.transform = CGAffineTransform.init(rotationAngle: CGFloat.pi / 4)
            
            let keyframeConfiguration: KeyframeVideoConfiguration<OpacityKeyframeValue> = {
                let configuration = KeyframeVideoConfiguration<OpacityKeyframeValue>()
                
                let timeValues: [(Double, CGFloat)] = [(0.0, 0), (0.5, 1.0), (2.5, 1.0), (3.0, 0.0)]
                timeValues.forEach({ (time, value) in
                    let opacityKeyframeValue = OpacityKeyframeValue()
                    opacityKeyframeValue.opacity = value
                    let keyframe = KeyframeVideoConfiguration.Keyframe(time: CMTime(seconds: time, preferredTimescale: 600), value: opacityKeyframeValue)
                    configuration.insert(keyframe)
                })
                
                return configuration
            }()
            imageCompositionProvider.videoConfiguration.configurations.append(keyframeConfiguration)

            let transformKeyframeConfiguration: KeyframeVideoConfiguration<TransformKeyframeValue> = {
                let configuration = KeyframeVideoConfiguration<TransformKeyframeValue>()

                let timeValues: [(Double, (CGFloat, CGFloat, CGPoint))] =
                    [(0.0, (1.0, 0, CGPoint.zero)),
                     (1.0, (1.0, CGFloat.pi, CGPoint(x: 100, y: 80))),
                     (2.0, (1.0, CGFloat.pi * 2, CGPoint(x: 300, y: 240))),
                     (3.0, (1.0, 0, CGPoint.zero))]
                timeValues.forEach({ (time, value) in
                    let opacityKeyframeValue = TransformKeyframeValue()
                    opacityKeyframeValue.scale = value.0
                    opacityKeyframeValue.rotation = value.1
                    opacityKeyframeValue.translation = value.2
                    let keyframe = KeyframeVideoConfiguration.Keyframe(time: CMTime(seconds: time, preferredTimescale: 600), value: opacityKeyframeValue)
                    configuration.insert(keyframe)
                })

                return configuration
            }()
            imageCompositionProvider.videoConfiguration.configurations.append(transformKeyframeConfiguration)
            
            imageCompositionGroupProvider.imageCompositionProviders = [imageCompositionProvider]
            return imageCompositionGroupProvider
        }()
        
        timeline.renderSize = CGSize(width: 1920, height: 1080)
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    func transitionPlayerItem() -> AVPlayerItem? {
        let bambooTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "bamboo", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let overlayTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "overlay", withExtension: "jpg")!
            let image = CIImage(contentsOf: url)!
            let resource = ImageResource(image: image, duration: CMTime.init(seconds: 5, preferredTimescale: 600))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let seaTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "sea", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let transitionDuration = CMTime(seconds: 2, preferredTimescale: 600)
        bambooTrackItem.videoTransition = PushTransition(duration: transitionDuration)
        bambooTrackItem.audioTransition = FadeInOutAudioTransition(duration: transitionDuration)
        
        overlayTrackItem.videoTransition = BoundingUpTransition(duration: transitionDuration)
        
        let timeline = Timeline()
        timeline.videoChannel = [bambooTrackItem, overlayTrackItem, seaTrackItem]
        timeline.audioChannel = [bambooTrackItem, seaTrackItem]
        
        do {
            try Timeline.reloadVideoStartTime(providers: timeline.videoChannel)
        } catch {
            assert(false, error.localizedDescription)
        }
        timeline.renderSize = CGSize(width: 1920, height: 1080)
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    func keyframePlayerItem() -> AVPlayerItem? {
        let bambooTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "bamboo", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            
            let transformKeyframeConfiguration: KeyframeVideoConfiguration<TransformKeyframeValue> = {
                let configuration = KeyframeVideoConfiguration<TransformKeyframeValue>()
                
                let timeValues: [(Double, (CGFloat, CGFloat, CGPoint))] =
                    [(0.0, (1.0, 0, CGPoint.zero)),
                     (1.0, (1.2, CGFloat.pi / 20, CGPoint(x: 100, y: 80))),
                     (2.0, (1.5, CGFloat.pi / 15, CGPoint(x: 300, y: 240))),
                     (3.0, (1.0, 0, CGPoint.zero))]
                timeValues.forEach({ (time, value) in
                    let opacityKeyframeValue = TransformKeyframeValue()
                    opacityKeyframeValue.scale = value.0
                    opacityKeyframeValue.rotation = value.1
                    opacityKeyframeValue.translation = value.2
                    let keyframe = KeyframeVideoConfiguration.Keyframe(time: CMTime(seconds: time, preferredTimescale: 600), value: opacityKeyframeValue)
                    configuration.insert(keyframe)
                })
                
                return configuration
            }()
            trackItem.videoConfiguration.configurations.append(transformKeyframeConfiguration)
            return trackItem
        }()
        
        let timeline = Timeline()
        timeline.videoChannel = [bambooTrackItem]
        timeline.audioChannel = [bambooTrackItem]
        timeline.renderSize = CGSize(width: 1920, height: 1080)
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    func testReaderOutput() -> AVPlayerItem? {
        let bambooTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "bamboo", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let flyTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "cute", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let timeline = Timeline()
        timeline.videoChannel = [bambooTrackItem, flyTrackItem]
        
        try! Timeline.reloadVideoStartTime(providers: timeline.videoChannel)
        
//        timeline.passingThroughVideoCompositionProvider = {
//            let imageCompositionGroupProvider = ImageCompositionGroupProvider()
//            let url = Bundle.main.url(forResource: "sea", withExtension: "mp4")!
//            let resource = AVAssetReaderImageResource(asset: AVAsset(url: url))
//            resource.selectedTimeRange = CMTimeRange.init(start: CMTime(seconds: 0, preferredTimescale: 600), end: CMTime(seconds: 3, preferredTimescale: 600))
//            let imageCompositionProvider = ImageOverlayItem(resource: resource)
//            imageCompositionProvider.startTime = CMTime(seconds: 1, preferredTimescale: 600)
//            let frame = CGRect.init(x: 100, y: 500, width: 600, height: 400)
//            imageCompositionProvider.videoConfiguration.contentMode = .custom(frame)
//            
//            imageCompositionGroupProvider.imageCompositionProviders = [imageCompositionProvider]
//            return imageCompositionGroupProvider
//        }()
        
        timeline.renderSize = CGSize(width: 1920, height: 1080)
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    
    func twoVideoPlayerItem() -> AVPlayerItem? {
        let renderSize = CGSize(width: 1920, height: 1080)
        let bambooTrackItem: TrackItem = {
            let width = renderSize.width / 2
            let height = width * (9/16)
            let url = Bundle.main.url(forResource: "bamboo", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            resource.selectedTimeRange = CMTimeRange.init(start: CMTime.zero, end: CMTime.init(value: 1800, 600))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .custom
            trackItem.videoConfiguration.frame = CGRect(x: 0, y: (renderSize.height - height) / 2, width: width, height: height)
            return trackItem
        }()
        
        let seaTrackItem: TrackItem = {
            let height = renderSize.height
            let width = height * (9/16)
            let url = Bundle.main.url(forResource: "cute", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            resource.selectedTimeRange = CMTimeRange.init(start: CMTime.zero, end: CMTime.init(value: 1800, 600))
            let trackItem = TrackItem(resource: resource)
            trackItem.audioConfiguration.volume = 0.3
            trackItem.videoConfiguration.contentMode = .custom
            trackItem.videoConfiguration.frame = CGRect(x: renderSize.width / 2 + (renderSize.width / 2 - width) / 2, y: (renderSize.height - height) / 2, width: width, height: height)
            return trackItem
        }()
        
        let trackItems = [bambooTrackItem]
        
        let timeline = Timeline()
        timeline.videoChannel = trackItems
        timeline.audioChannel = trackItems
        
        timeline.overlays = [seaTrackItem]
        timeline.audios = [seaTrackItem]
        timeline.renderSize = renderSize;
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    func fourSquareVideo() -> AVPlayerItem? {
        let bambooTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "bamboo", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let seaTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "sea", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        
        let flyTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "cute", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let bamboo2TrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "bamboo", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let trackItems = [flyTrackItem, bambooTrackItem, seaTrackItem, bamboo2TrackItem]
        
        let timeline = Timeline()
        timeline.videoChannel = trackItems
        timeline.audioChannel = trackItems
        
        try! Timeline.reloadVideoStartTime(providers: timeline.videoChannel)
        
        let renderSize = CGSize(width: 1920, height: 1080)
        
        timeline.overlays = {
            let foursquareRenderSize = CGSize(width: renderSize.width / 2, height: renderSize.height / 2)
            var overlays: [VideoProvider] = []
            let fullTimeRange: CMTimeRange = {
                var duration = CMTime.zero
                trackItems.forEach({ duration = $0.duration + duration })
                return CMTimeRange.init(start: CMTime.zero, duration: duration)
            }()
            
            // Update main item's frame
            func frameWithIndex(_ index: Int) -> CGRect {
                switch index {
                case 0:
                    return CGRect(origin: CGPoint.zero, size: foursquareRenderSize)
                case 1:
                    return CGRect(origin: CGPoint(x: foursquareRenderSize.width, y: 0), size: foursquareRenderSize)
                case 2:
                    return CGRect(origin: CGPoint(x: 0, y:  foursquareRenderSize.height), size: foursquareRenderSize)
                case 3:
                    return CGRect(origin: CGPoint(x: foursquareRenderSize.width, y: foursquareRenderSize.height), size: foursquareRenderSize)
                default:
                    break
                }
                return CGRect(origin: CGPoint.zero, size: foursquareRenderSize)
            }
            
            trackItems.enumerated().forEach({ (offset, mainTrackItem) in
                let frame: CGRect = {
                    let index = offset % 4
                    return frameWithIndex(index)
                }()
                mainTrackItem.videoConfiguration.contentMode = .aspectFit
                mainTrackItem.videoConfiguration.frame = frame
                
                let timeRanges = fullTimeRange.substruct(mainTrackItem.timeRange)
                for timeRange in timeRanges {
                    Log.debug("timeRange: {\(String(format: "%.2f", timeRange.start.seconds)) - \(String(format: "%.2f", timeRange.end.seconds))}")
                    if timeRange.duration.seconds > 0 {
                        let staticTrackItem = mainTrackItem.copy() as! TrackItem
                        staticTrackItem.startTime = timeRange.start
                        staticTrackItem.duration = timeRange.duration
                        if timeRange.start <= mainTrackItem.timeRange.start {
                            let start = staticTrackItem.resource.selectedTimeRange.start
                            staticTrackItem.resource.selectedTimeRange = CMTimeRange(start: start, duration: CMTime(value: 1, 30))
                        } else {
                            let start = staticTrackItem.resource.selectedTimeRange.end - CMTime(value: 1, 30)
                            staticTrackItem.resource.selectedTimeRange = CMTimeRange(start: start, duration: CMTime(value: 1, 30))
                        }
                        overlays.append(staticTrackItem)
                    }
                }
            })
            
            return overlays
        }()
        timeline.renderSize = renderSize;
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    func reversePlayerItem() -> AVPlayerItem? {
        let seaTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "sea", withExtension: "mp4")!
            let resource = AVAssetReverseImageResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.videoConfiguration.contentMode = .aspectFit
            return trackItem
        }()
        
        let timeline = Timeline()
        timeline.videoChannel = [seaTrackItem]
        timeline.renderSize = CGSize(width: 1920, height: 1080)
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    
}

