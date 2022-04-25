//
//  PHAssetTrackResource.swift
//  Cabbage
//
//  Created by Vito on 24/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import Photos

public class PHAssetTrackResource: AVAssetTrackResource {
    
    public var phasset: PHAsset?
    
    public init(phasset: PHAsset) {
        super.init()
        self.phasset = phasset
        let duration = CMTimeMake(value: Int64(phasset.duration * 600), timescale: 600)
        self.duration = duration;
        selectedTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
    }
    
    required public init() {
        super.init()
    }
    
}
