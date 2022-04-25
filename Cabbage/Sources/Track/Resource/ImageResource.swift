//
//  ImageResource.swift
//  Cabbage
//
//  Created by Vito on 2018/7/27.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation
import CoreImage

/// Provide a Image as video frame
open class ImageResource: Resource {
    
    public init(image: CIImage, duration: CMTime) {
        super.init()
        self.image = image
        self.duration = duration
        self.selectedTimeRange = CMTimeRange(start: CMTime.zero, duration: duration)
    }
    
    required public init() {
        super.init()
    }
    
    public var image: CIImage? = nil
    
    open override func image(at time: CMTime, renderSize: CGSize) -> CIImage? {
        return image
    }
    
}
