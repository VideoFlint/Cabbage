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
    
    public init(asset: PHAsset) {
        super.init()
        self.asset = asset
        self.duration = CMTime.init(value: 3000, 600)
    }
    
    required public init() {
        super.init()
    }
    
    open override func image(at time: CMTime, renderSize: CGSize) -> CIImage? {
        return image
    }

    @discardableResult
    open override func prepare(progressHandler:((Double) -> Void)? = nil, completion: @escaping (ResourceStatus, Error?) -> Void)  -> ResourceTask? {
        status = .unavaliable
        statusError = NSError.init(domain: "com.resource.status", code: 0, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Empty resource", comment: "")])
        guard let asset = asset else {
            completion(status, statusError)
            return nil
        }
        
        let progressHandler: PHAssetImageProgressHandler = { (progress, error, stop, info) in
            if let b = info?[PHImageCancelledKey] as? NSNumber, b.boolValue {
                return
            }
            if error != nil {
                return
            }
            DispatchQueue.main.async {
                progressHandler?(progress)
            }
        }
        
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.version = .current
        imageRequestOptions.deliveryMode = .highQualityFormat
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.progressHandler = progressHandler
        let requestID = PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 720, height: 720), contentMode: .aspectFit, options: imageRequestOptions) { [weak self] (image, info) in
            guard let strongSelf = self else { return }
            if let error = info?[PHImageErrorKey] as? NSError {
                DispatchQueue.main.async {
                    strongSelf.statusError = error
                    strongSelf.status = .unavaliable
                    completion(strongSelf.status, strongSelf.statusError)
                }
                return
            }
            DispatchQueue.main.async {
                if let image = image {
                    strongSelf.size = image.size
                    strongSelf.image = CIImage(image: image)
                }
                strongSelf.status = .avaliable
                completion(strongSelf.status, strongSelf.statusError)
            }
        }
        
        return ResourceTask.init(cancel: {
            PHImageManager.default().cancelImageRequest(requestID)
        })
    }
    
    // MARK: - NSCopying
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let resource = super.copy(with: zone) as! PHAssetImageResource
        resource.asset = asset
        
        return resource
    }
}
