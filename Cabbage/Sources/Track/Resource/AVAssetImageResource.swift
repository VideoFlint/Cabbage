//
//  AVAssetImageResource.swift
//  Cabbage
//
//  Created by Vito on 2018/11/18.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation
import CoreImage
import AVFoundation


/// Load image from PHAsset as video frame
open class AVAssetImageResource: ImageResource {
    
    public var asset: AVAsset?
    private var imageGenerator: AVAssetImageGenerator?
    
    public init(asset: AVAsset) {
        super.init()
        self.asset = asset
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true;
        imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        imageGenerator.updateAspectFitSize(CGSize.init(width: 500, height: 500))
        self.imageGenerator = imageGenerator
        let duration = CMTimeMake(value: Int64(asset.duration.seconds * 600), timescale: 600)
        selectedTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
    }
    
    required public init() {
        super.init()
    }
    
    open override func image(at time: CMTime, renderSize: CGSize) -> CIImage? {
        guard selectedTimeRange.containsTime(time) else {
            return image
        }
        
        if let imageGenerator = imageGenerator {
            let imageTime = selectedTimeRange.start + time
            if let cgImage = try? imageGenerator.copyCGImage(at: imageTime, actualTime: nil) {
                return CIImage(cgImage: cgImage)
            }
        }
        
        return image;
    }
    
    // MARK: - Load Media before use resource
    
    @discardableResult
    open override func prepare(progressHandler:((Double) -> Void)? = nil, completion: @escaping (ResourceStatus, Error?) -> Void) -> ResourceTask? {
        if let asset = asset {
            asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"], completionHandler: { [weak self] in
                guard let strongSelf = self else { return }
                
                defer {
                    if asset.tracks.count > 0 {
                        if let track = asset.tracks(withMediaType: .video).first {
                            strongSelf.size = track.naturalSize.applying(track.preferredTransform)
                        }
                        strongSelf.status = .avaliable
                        strongSelf.duration = asset.duration
                    }
                    DispatchQueue.main.async {
                        completion(strongSelf.status, strongSelf.statusError)
                    }
                }
                
                var error: NSError?
                let tracksStatus = asset.statusOfValue(forKey: "tracks", error: &error)
                if tracksStatus != .loaded {
                    strongSelf.statusError = error;
                    strongSelf.status = .unavaliable;
                    Log.error("Failed to load tracks, status: \(tracksStatus), error: \(String(describing: error))")
                    return
                }
                let durationStatus = asset.statusOfValue(forKey: "duration", error: &error)
                if durationStatus != .loaded {
                    strongSelf.statusError = error;
                    strongSelf.status = .unavaliable;
                    Log.error("Failed to duration tracks, status: \(tracksStatus), error: \(String(describing: error))")
                    return
                }
            })
            return ResourceTask.init(cancel: {
                asset.cancelLoading()
            })
        } else {
            completion(status, statusError)
        }
        return nil
    }
    
    // MARK: - NSCopying
    
    override open func copy(with zone: NSZone? = nil) -> Any {
        let resource = super.copy(with: zone) as! AVAssetImageResource
        resource.asset = asset
        resource.imageGenerator = imageGenerator
        return resource
    }
}
