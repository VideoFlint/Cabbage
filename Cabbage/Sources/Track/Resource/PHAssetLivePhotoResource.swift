//
//  PHAssetLivePhotoResource.swift
//  SliderArtDataKit
//
//  Created by aby.wang on 2019/4/16.
//  Copyright © 2019 AlanMoMo. All rights reserved.
//

import Photos
import UIKit

public class PHAssetLivePhotoResource: AVAssetTrackResource {
    public var phasset: PHAsset?
    
    public init(phasset: PHAsset) {
        super.init()
        self.phasset = phasset
        let duration = CMTime(seconds: phasset.duration, preferredTimescale: 600)
        selectedTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
    }
    
    required public init() {
        super.init()
    }
    
}

extension PHAssetLivePhotoResource {
    @available(iOS 9.1, *)
    func videoUrl(forLivePhotoAsset asset: PHAsset, options: PHLivePhotoRequestOptions?, completion: @escaping (URL?) -> Void) -> PHImageRequestID {
        let fileUrl = URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(String(format: "%@", asset.value(forKey: "filename") as? String ?? "temp")).mov")
        return PHImageManager.default().requestLivePhoto(for: asset, targetSize: UIScreen.main.bounds.size, contentMode: PHImageContentMode.default, options: options, resultHandler: { (livePhoto, info) in
            guard let livePhoto = livePhoto else { completion(nil); return }
            var assetResources: [PHAssetResource]? = nil
            assetResources = PHAssetResource.assetResources(for: livePhoto)
            var videoResource: PHAssetResource? = nil
            for resource in assetResources ?? [] {
                if resource.type == .pairedVideo {
                    videoResource = resource
                    break
                }
            }
            guard videoResource != nil else { completion(nil); return }
            try? FileManager.default.removeItem(at: fileUrl)
            PHAssetResourceManager.default().writeData(for: videoResource!, toFile: fileUrl, options: nil, completionHandler: { (error) in
                if let error = error {
                    Log.error("\(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(fileUrl)
                }
            })
        })
    }
}
