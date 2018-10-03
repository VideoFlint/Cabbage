//
//  ImageCompositionGroupProvider.swift
//  Cabbage
//
//  Created by Vito on 2018/10/2.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreImage
import CoreMedia

public protocol ImageCompositionProvider: CompositionTimeRangeProvider, PassingThroughVideoCompositionProvider {}

public class ImageCompositionGroupProvider: PassingThroughVideoCompositionProvider {
    
    public var passingThroughVideoCompositionProvider: PassingThroughVideoCompositionProvider?
    public var imageCompositionProviders: [ImageCompositionProvider] = []
    
    public func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        var sourceImage = sourceImage
        
        imageCompositionProviders.forEach { (provider) in
            if provider.timeRange.containsTime(time) {
                sourceImage = provider.applyEffect(to: sourceImage, at: time, renderSize: renderSize)
            }
        }
        
        if let provider = passingThroughVideoCompositionProvider {
            sourceImage = provider.applyEffect(to: sourceImage, at: time, renderSize: renderSize)
        }
        
        return sourceImage
    }
    
}
