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
    
    @discardableResult
    open override func prepare(progressHandler: ((Double) -> Void)? = nil, completion: @escaping (Resource.ResourceStatus, Error?) -> Void) -> ResourceTask? {
        if self.asset != nil {
            return super.prepare(progressHandler: progressHandler, completion: completion)
        }
        
        guard let phasset = phasset else {
            completion(status, nil)
            return nil
        }
        if #available(iOS 9.1, *) {
            if phasset.mediaSubtypes == .photoLive {
                let options = PHLivePhotoRequestOptions()
                options.deliveryMode = .fastFormat
                options.isNetworkAccessAllowed = true
                let requestID = self.videoUrl(forLivePhotoAsset: phasset, options: options, completion: { [weak self] (url) in
                    guard let `self` = self else { return }
                    guard let url = url else {
                        DispatchQueue.main.async {
                            completion(self.status, nil)
                        }
                        return
                    }
                    let asset = AVAsset.init(url: url)
                    self.duration = asset.duration
                    self.asset = asset
                    if let track = asset.tracks(withMediaType: .video).first {
                        self.size = track.naturalSize.applying(track.preferredTransform)
                    }
                    self.status = .avaliable
                    DispatchQueue.main.async {
                        completion(self.status, nil)
                    }
                })
                return ResourceTask.init(cancel: {
                    PHImageManager.default().cancelImageRequest(requestID)
                })
            } else {
                completion(status, nil)
                return nil
            }
        } else {
            // Fallback on earlier versions
            completion(status, nil)
            return nil
        }
    }
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let resource = super.copy(with: zone) as! PHAssetLivePhotoResource
        resource.asset = asset
        resource.phasset = phasset
        return resource
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
