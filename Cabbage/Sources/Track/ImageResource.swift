//
//  ImageResource.swift
//  Cabbage
//
//  Created by Vito on 2018/7/27.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation
import CoreImage


/// Provider a Image as video frame
open class ImageResource: Resource {
    
    public init(image: CIImage) {
        super.init()
        self.image = image
        self.status = .avaliable
    }
    
    required public init() {
        super.init()
    }
    
    open var image: CIImage? = nil
    
    open func image(at time: CMTime, renderSize: CGSize) -> CIImage? {
        return image
    }
    
    open override func tracks(for type: AVMediaType) -> [AVAssetTrack] {
        if type != .video {
            return []
        }
        if let tracks = ImageResource.emptyAsset?.tracks(withMediaType: type) {
            return tracks
        }
        
        return []
    }
    
    // MARK: - NSCopying
    open override func copy(with zone: NSZone? = nil) -> Any {
        let resource = super.copy(with: zone) as! ImageResource
        resource.image = image
        return resource
    }
    
    // MARK: - Helper
    
    private static let emptyAsset: AVAsset? = {
        let bundle = Bundle(for: ImageResource.self)
        if let bundleURL = bundle.resourceURL?.appendingPathComponent("Cabbage.bundle") {
            let resourceBundle = Bundle.init(url: bundleURL)
            if let videoURL = resourceBundle?.url(forResource: "black_empty", withExtension: "mp4") {
                return AVAsset(url: videoURL)
            }
        }
        
        
        if let url = Bundle.main.url(forResource: "black_empty", withExtension: "mp4") {
            let asset = AVAsset(url: url)
            return asset
        }
        
        
        return nil
    }()
}
