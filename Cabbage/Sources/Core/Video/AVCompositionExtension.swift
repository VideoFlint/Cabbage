//
//  AVCompositionTrackExtension.swift
//  Cabbage
//
//  Created by Vito on 2022/4/10.
//  Copyright © 2022 Vito. All rights reserved.
//

import AVFoundation

extension AVCompositionTrack {
    private static var preferredTransformsKey: UInt8 = 0
    var preferredTransforms: [String: CGAffineTransform] {
        get {
            if let transforms = objc_getAssociatedObject(self, &AVCompositionTrack.preferredTransformsKey) as? [String: CGAffineTransform] {
                return transforms
            }
            let transforms: [String: CGAffineTransform] = [:]
            self.preferredTransforms = transforms
            return transforms
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AVCompositionTrack.preferredTransformsKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension AVMutableComposition {
    
    func vf_mutableTrackCompatiableWithTrack(_ track: AVAssetTrack, timeRange: CMTimeRange) -> AVMutableCompositionTrack? {
        let trackKey = track.vf_trackKey()
        
        for mutableCompositionTrack in self.tracks(withMediaType: track.mediaType) {
            let mutableTrackKey = mutableCompositionTrack.vf_trackKey()
            if trackKey != mutableTrackKey {
                continue
            }
            
            /**
             When merging tracks, videos cannot be spliced continuously, otherwise when using AVPlayer for precise seek, when the seek reaches the time point just between two video clips, subsequent decoding will always return to the previous video.
             
             It may be a decoder bug, so the timerange of the segments is expanded here to prevent the segments from being merged into the same track next to each other.
             */
            let offset = CMTime(value: 300, 600)
            let duration = CMTimeAdd(mutableCompositionTrack.timeRange.duration, offset)
            let trackTimeRange = CMTimeRangeMake(start: mutableCompositionTrack.timeRange.start, duration: duration)
            let intersection = CMTimeRangeGetIntersection(trackTimeRange, otherRange: timeRange)
            if CMTimeGetSeconds(intersection.duration) <= 0 {
                return mutableCompositionTrack
            }
            
            for segment in mutableCompositionTrack.segments {
                let start = CMTimeAdd(segment.timeMapping.target.start, offset)
                let doubleOffset = CMTimeMakeWithSeconds(CMTimeGetSeconds(offset) * 2, preferredTimescale: 600)
                let duration = CMTimeSubtract(segment.timeMapping.target.duration, doubleOffset)
                let targetTimeRange = CMTimeRange(start: start, duration: duration)
                if (segment.isEmpty && CMTimeRangeContainsTimeRange(targetTimeRange, otherRange: timeRange)) {
                    return mutableCompositionTrack
                }
            }
        }
        
        let mutableCompositionTrack = self.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: kCMPersistentTrackID_Invalid)
        return mutableCompositionTrack
    }
    
}


extension AVAssetTrack {
    
    func vf_trackKey() -> String {
        var trackKey = self.mediaType.rawValue
        if self.mediaType == AVMediaType.audio {
            let formatDes = self.formatDescriptions.first as! CMFormatDescription?
            if let formatDes = formatDes,
               let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDes) {
                trackKey = trackKey +
                ", sampleRate: " + String(asbd.pointee.mSampleRate) +
                ", channelCount: " + String(asbd.pointee.mChannelsPerFrame) +
                ", formatID: " + String(asbd.pointee.mFormatID)
            }
        }
        
        return trackKey
    }
    
}
