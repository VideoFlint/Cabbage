//
//  KeyframeVideoConfiguration.swift
//  Cabbage
//
//  Created by Vito on 2018/11/11.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation
import CoreImage
import CoreMedia

public class KeyframeVideoConfiguration: VideoConfigurationProtocol {
    
    
    
    public func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        
        return sourceImage
    }
    
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let configuration = KeyframeVideoConfiguration()
        
        return configuration
    }
    
    
}
