//
//  AVAssetTrackResource.swift
//  Cabbage
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import UIKit

/// Load image from PHAsset as video frame
public class AVAssetTrackResource: Resource {
    
    public var asset: AVAsset?
    
    public init(asset: AVAsset) {
        super.init()
        self.asset = asset
        let duration = CMTimeMake(value: Int64(asset.duration.seconds * 600), timescale: 600)
        self.duration = duration;
        selectedTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
    }
    
    required public init() {
        super.init()
    }
    
    // MARK: - Content provider
    
    open override func tracks(for type: AVMediaType) -> [AVAssetTrack] {
        if let asset = asset {
            return asset.tracks(withMediaType: type)
        }
        return []
    }
    
    // MARK: - ResourceTrackInfoProvider
    
    public override func trackInfo(for type: AVMediaType, at index: Int) -> ResourceTrackInfo {
        let track = tracks(for: type)[index]
        return ResourceTrackInfo(track: track,
                                 selectedTimeRange: selectedTimeRange,
                                 scaleToDuration: scaledDuration)
    }
    
}

