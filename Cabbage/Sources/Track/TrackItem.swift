//
//  TrackItem.swift
//  Cabbage
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import CoreImage

open class TrackItem: NSObject, NSCopying, TransitionableVideoProvider, TransitionableAudioProvider {
    
    public var identifier: String
    public var resource: Resource
    public var configuration: TrackConfiguration
    
    public var videoTransition: VideoTransition?
    public var audioTransition: AudioTransition?
    
    public required init(resource: Resource) {
        identifier = ProcessInfo.processInfo.globallyUniqueString
        self.resource = resource
        configuration = TrackConfiguration()
        super.init()
        self.reloadTimelineDuration()
    }
    
    // MARK: - NSCopying
    
    open func copy(with zone: NSZone? = nil) -> Any {
        let item = type(of: self).init(resource: resource.copy() as! Resource)
        item.identifier = identifier
        item.configuration = configuration.copy() as! TrackConfiguration
        item.videoTransition = videoTransition
        item.audioTransition = audioTransition
        return item
    }
    
    // MARK: - CompositionTimeRangeProvider
    
    open var timeRange: CMTimeRange {
        get {
            return configuration.timelineTimeRange
        }
        set {
            configuration.timelineTimeRange = newValue
        }
    }
    
    /// Resource's selected time range that mix with speed
    open var resourceTargetTimeRange: CMTimeRange {
        get {
            var timeRange = resource.selectedTimeRange
            timeRange.start = CMTime.init(value: Int64(Float(timeRange.start.value) / configuration.speed),
                                          timeRange.start.timescale)
            timeRange.duration = CMTime.init(value: Int64(Float(timeRange.duration.value) / configuration.speed),
                                             timeRange.duration.timescale)
            return timeRange
        }
        set {
            let start = CMTime.init(value: Int64(Float(newValue.start.value) * configuration.speed),
                                    newValue.start.timescale)
            let duration = CMTime.init(value: Int64(Float(newValue.duration.value) * configuration.speed),
                                       newValue.duration.timescale)
            resource.selectedTimeRange = CMTimeRange.init(start: start, duration: duration)
        }
    }
    
    open func reloadTimelineDuration() {
        configuration.timelineTimeRange.duration = resourceTargetTimeRange.duration
    }
    
    // MARK: - TransitionableVideoProvider
    
    open func numberOfVideoTracks() -> Int {
        return resource.tracks(for: .video).count
    }
    
    open func videoCompositionTrack(for composition: AVMutableComposition, at index: Int, preferredTrackID: Int32) -> AVCompositionTrack? {
        let track = resource.tracks(for: .video)[index]
        
        let compositionTrack: AVMutableCompositionTrack? = {
            if let track = composition.track(withTrackID: preferredTrackID) {
                return track
            }
            return composition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: preferredTrackID)
        }()
        
        if let compositionTrack = compositionTrack {
            compositionTrack.preferredTransforms[timeRange.vf_identifier] = track.preferredTransform
            do {
                /*
                 Special logic for ImageResource, because of it provides a placeholder track,
                 Maybe not enough to fill the selectedTimeRange.
                 But ImageResource usually support unlimited time.
                 */
                if resource.isKind(of: ImageResource.self) {
                    let emptyDuration = CMTime(value: 1, 30)
                    let range = CMTimeRangeMake(start: CMTime.zero, duration: emptyDuration)
                    try compositionTrack.insertTimeRange(range, of: track, at: timeRange.start)
                    compositionTrack.scaleTimeRange(CMTimeRange(start: timeRange.start, duration: emptyDuration),
                                                    toDuration: resourceTargetTimeRange.duration)
                } else {
                    try compositionTrack.insertTimeRange(resource.selectedTimeRange, of: track, at: timeRange.start)
                    compositionTrack.scaleTimeRange(CMTimeRange(start: timeRange.start, duration: resource.selectedTimeRange.duration),
                                                    toDuration: resourceTargetTimeRange.duration)
                }
            } catch {
                Log.error(#function + error.localizedDescription)
            }
        }
        return compositionTrack
    }
    
    open func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        var finalImage: CIImage = {
            if let resource = resource as? ImageResource {
                var relativeTime = time - timeRange.start
                if relativeTime.seconds > 0 {
                    relativeTime = CMTime.init(value: Int64(Float(relativeTime.value) / configuration.speed),
                                               timescale: relativeTime.timescale)
                }
                if let resourceImage = resource.image(at: relativeTime, renderSize: renderSize) {
                    return resourceImage
                }
            }
            return sourceImage
        }()
        let info = VideoConfigurationEffectInfo.init(time: time, renderSize: renderSize, timeRange: timeRange)
        finalImage = configuration.videoConfiguration.applyEffect(to: finalImage, info: info)
        
        return finalImage
    }
    
    // MARK: - TransitionableAudioProvider
    
    open func numberOfAudioTracks() -> Int {
        return resource.tracks(for: .audio).count
    }
    
    open func audioCompositionTrack(for composition: AVMutableComposition, at index: Int, preferredTrackID: Int32) -> AVCompositionTrack? {
        let track = resource.tracks(for: .audio)[index]
        let compositionTrack: AVMutableCompositionTrack? = {
            if let track = composition.track(withTrackID: preferredTrackID) {
                return track
            }
            return composition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: preferredTrackID)
        }()
        if let compositionTrack = compositionTrack {
            do {
                try compositionTrack.insertTimeRange(resource.selectedTimeRange, of: track, at: timeRange.start)
                compositionTrack.scaleTimeRange(CMTimeRange(start: timeRange.start, duration: resource.selectedTimeRange.duration),
                                                toDuration: resourceTargetTimeRange.duration)
            } catch {
                Log.error(#function + error.localizedDescription)
            }
        }
        return compositionTrack
    }
    
    open func configure(audioMixParameters: AVMutableAudioMixInputParameters) {
        let volume = configuration.audioConfiguration.volume
        audioMixParameters.setVolumeRamp(fromStartVolume: volume, toEndVolume: volume, timeRange: configuration.timelineTimeRange)
        if configuration.audioConfiguration.nodes.count > 0 {
            if audioMixParameters.audioProcessingTapHolder == nil {
                audioMixParameters.audioProcessingTapHolder = AudioProcessingTapHolder()
            }
            audioMixParameters.audioProcessingTapHolder?.audioProcessingChain.nodes.append(contentsOf: configuration.audioConfiguration.nodes)
        }
    }
    
    
}

private extension CIImage {
    
    func flipYCoordinate() -> CIImage {
        let flipYTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: extent.origin.y * 2 + extent.height)
        return transformed(by: flipYTransform)
    }
    
}

public extension TrackItem {
    
    public func makeFullRangeCopy() -> TrackItem {
        let item = self.copy() as! TrackItem
        item.resource.selectedTimeRange = CMTimeRange.init(start: CMTime.zero, duration: item.resource.duration)
        item.reloadTimelineDuration()
        item.timeRange.start = CMTime.zero
        return item
    }
    
    public func generateFullRangeImageGenerator(size: CGSize = .zero) -> AVAssetImageGenerator? {
        let item = makeFullRangeCopy()
        let imageGenerator = AVAssetImageGenerator.create(from: [item], renderSize: size)
        imageGenerator?.updateAspectFitSize(size)
        return imageGenerator
    }
    
    public func generateFullRangePlayerItem(size: CGSize = .zero) -> AVPlayerItem? {
        let item = makeFullRangeCopy()
        let timeline = Timeline()
        timeline.videoChannel = [item]
        timeline.audioChannel = [item]
        let generator = CompositionGenerator(timeline: timeline)
        generator.renderSize = size
        let playerItem = generator.buildPlayerItem()
        return playerItem
    }
    
}
