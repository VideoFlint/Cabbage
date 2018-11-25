//
//  ImageOverlayItem.swift
//  Cabbage
//
//  Created by Vito on 2018/10/2.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreMedia
import CoreImage

open class ImageOverlayItem: NSObject, ImageCompositionProvider, NSCopying {
   
    public var identifier: String
    public var resource: ImageResource
    required public init(resource: ImageResource) {
        identifier = ProcessInfo.processInfo.globallyUniqueString
        self.resource = resource
        let frame = CGRect(origin: CGPoint.zero, size: resource.size)
        self.videoConfiguration.baseContentMode = .custom(frame)
    }
    
    public var videoConfiguration: VideoConfiguration = .createDefaultConfiguration()
    
    // MARK: - NSCopying
    
    open func copy(with zone: NSZone? = nil) -> Any {
        let item = type(of: self).init(resource: resource.copy() as! ImageResource)
        item.identifier = identifier
        item.videoConfiguration = videoConfiguration.copy() as! VideoConfiguration
        item.timeRange = timeRange
        return item
    }
    
    // MARK: - ImageCompositionProvider
    
    public var timeRange: CMTimeRange = CMTimeRange()
    
    open func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        let relativeTime = time - timeRange.start
        guard let image = resource.image(at: relativeTime, renderSize: renderSize) else {
            return sourceImage
        }
        
        var finalImage = image
        
        let info = VideoConfigurationEffectInfo.init(time: time, renderSize: renderSize, timeRange: timeRange)
        finalImage = videoConfiguration.applyEffect(to: finalImage, info: info)

        finalImage = finalImage.composited(over: sourceImage)
        return finalImage
    }
    
}
