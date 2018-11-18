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
                return testReaderOutput()
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
            trackItem.configuration.videoConfiguration.baseContentMode = .aspectFit
            return trackItem
        }()
        
        let timeline = Timeline()
        timeline.videoChannel = [bambooTrackItem]
        timeline.audioChannel = [bambooTrackItem]
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        compositionGenerator.renderSize = CGSize(width: 1920, height: 1080)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    func overlayPlayerItem() -> AVPlayerItem? {
        let bambooTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "bamboo", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.configuration.videoConfiguration.baseContentMode = .aspectFit
            return trackItem
        }()
        
        let timeline = Timeline()
        timeline.videoChannel = [bambooTrackItem]
        timeline.audioChannel = [bambooTrackItem]
        
        timeline.passingThroughVideoCompositionProvider = {
            let imageCompositionGroupProvider = ImageCompositionGroupProvider()
            let url = Bundle.main.url(forResource: "overlay", withExtension: "jpg")!
            let image = CIImage(contentsOf: url)!
            let resource = ImageResource(image: image)
            let imageCompositionProvider = ImageOverlayItem(resource: resource)
            imageCompositionProvider.timeRange = CMTimeRange(start: CMTime.init(seconds: 1, preferredTimescale: 600), end: CMTime(seconds: 4, preferredTimescale: 600))
            imageCompositionProvider.frame = CGRect.init(x: 100, y: 500, width: 400, height: 400)
            
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
            
            imageCompositionGroupProvider.imageCompositionProviders = [imageCompositionProvider]
            return imageCompositionGroupProvider
        }()
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        compositionGenerator.renderSize = CGSize(width: 1920, height: 1080)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    func transitionPlayerItem() -> AVPlayerItem? {
        let bambooTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "bamboo", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.configuration.videoConfiguration.baseContentMode = .aspectFit
            return trackItem
        }()
        
        let seaTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "sea", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.configuration.videoConfiguration.baseContentMode = .aspectFit
            return trackItem
        }()
        
        let transitionDuration = CMTime(seconds: 2, preferredTimescale: 600)
        bambooTrackItem.videoTransition = PushTransition(duration: transitionDuration)
        bambooTrackItem.audioTransition = FadeInOutAudioTransition.init(duration: transitionDuration)
        
        let timeline = Timeline()
        timeline.videoChannel = [bambooTrackItem, seaTrackItem]
        timeline.audioChannel = [bambooTrackItem, seaTrackItem]
        
        Timeline.reloadVideoStartTime(providers: timeline.videoChannel)
        Timeline.reloadAudioStartTime(providers: timeline.audioChannel)
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        compositionGenerator.renderSize = CGSize(width: 1920, height: 1080)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    func keyframePlayerItem() -> AVPlayerItem? {
        let bambooTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "bamboo", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.configuration.videoConfiguration.baseContentMode = .aspectFit
            
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
                    opacityKeyframeValue.transalation = value.2
                    let keyframe = KeyframeVideoConfiguration.Keyframe(time: CMTime(seconds: time, preferredTimescale: 600), value: opacityKeyframeValue)
                    configuration.insert(keyframe)
                })
                
                return configuration
            }()
            trackItem.configuration.videoConfiguration.configurations.append(transformKeyframeConfiguration)
            return trackItem
        }()
        
        let timeline = Timeline()
        timeline.videoChannel = [bambooTrackItem]
        timeline.audioChannel = [bambooTrackItem]
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        compositionGenerator.renderSize = CGSize(width: 1920, height: 1080)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
    func testReaderOutput() -> AVPlayerItem? {
        let bambooTrackItem: TrackItem = {
            let url = Bundle.main.url(forResource: "bamboo", withExtension: "mp4")!
            let resource = AVAssetTrackResource(asset: AVAsset(url: url))
            let trackItem = TrackItem(resource: resource)
            trackItem.configuration.videoConfiguration.baseContentMode = .aspectFit
            return trackItem
        }()
        
        let timeline = Timeline()
        timeline.videoChannel = [bambooTrackItem]
        timeline.audioChannel = [bambooTrackItem]
        
        timeline.passingThroughVideoCompositionProvider = {
            let imageCompositionGroupProvider = ImageCompositionGroupProvider()
            let url = Bundle.main.url(forResource: "sea", withExtension: "mp4")!
            let resource = AVAssetReaderImageResource(asset: AVAsset(url: url))
            let imageCompositionProvider = ImageOverlayItem(resource: resource)
            imageCompositionProvider.timeRange = CMTimeRange(start: CMTime.init(seconds: 1, preferredTimescale: 600), end: CMTime(seconds: 4, preferredTimescale: 600))
            imageCompositionProvider.frame = CGRect.init(x: 100, y: 500, width: 400, height: 400)
            
            imageCompositionGroupProvider.imageCompositionProviders = [imageCompositionProvider]
            return imageCompositionGroupProvider
        }()
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        compositionGenerator.renderSize = CGSize(width: 1920, height: 1080)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }
    
}

