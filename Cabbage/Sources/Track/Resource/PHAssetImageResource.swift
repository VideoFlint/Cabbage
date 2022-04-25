//
//  PHAssetImageResource.swift
//  Cabbage
//
//  Created by Vito on 2018/7/24.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation
import CoreImage
import Photos

/// Load image from PHAsset as video frame
open class PHAssetImageResource: ImageResource {
    
    open var asset: PHAsset?
    
    public init(asset: PHAsset, duration: CMTime) {
        super.init()
        self.asset = asset
        self.duration = duration
        self.selectedTimeRange = CMTimeRange(start: CMTime.zero, duration: duration)
    }
    
    required public init() {
        super.init()
    }
    
    open override func image(at time: CMTime, renderSize: CGSize) -> CIImage? {
        return image
    }
    
}
