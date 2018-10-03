//
//  ImageOverlayItem.swift
//  Cabbage
//
//  Created by Vito on 2018/10/2.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreMedia
import CoreImage

open class ImageOverlayItem: ImageCompositionProvider {
   
    public var resource: ImageResource
    init(resource: ImageResource) {
        self.resource = resource
        self.frame = CGRect(origin: CGPoint.zero, size: resource.size)
        self.videoConfiguration.baseContentMode = .custom
    }
    
    public var frame: CGRect = CGRect.zero
    public var videoConfiguration: VideoConfiguration = .createDefaultConfiguration()
    
    // MARK: - ImageCompositionProvider
    
    public var timeRange: CMTimeRange = CMTimeRange()
    
    open func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        guard let image = resource.image(at: time, renderSize: renderSize) else {
            return sourceImage
        }
        
        var finalImage = image
        let scaleTransform = CGAffineTransform(scaleX: frame.size.width / image.extent.size.width, y: frame.size.height / image.extent.size.height)
        finalImage = finalImage.transformed(by: scaleTransform)
        let translateTransform = CGAffineTransform.init(translationX: frame.origin.x, y: frame.origin.y)
        finalImage = finalImage.transformed(by: translateTransform)
        
        finalImage = videoConfiguration.applyTo(sourceImage: finalImage, renderSize: renderSize)
        finalImage = finalImage.composited(over: sourceImage)
        return finalImage
    }
    
}
