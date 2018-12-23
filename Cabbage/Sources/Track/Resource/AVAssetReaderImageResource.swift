//
//  AVAssetReaderImageResource.swift
//  Cabbage
//
//  Created by Vito on 2018/11/18.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation
import CoreImage
import AVFoundation


/// Load image from PHAsset as video frame
open class AVAssetReaderImageResource: ImageResource {
    
    public var asset: AVAsset?
    
    private var lastReaderTime = CMTime.zero
    
    private var assetReader: AVAssetReader?
    private var trackOutput: AVAssetReaderTrackOutput?
    
    public init(asset: AVAsset) {
        super.init()
        self.asset = asset
        let duration = CMTimeMake(value: Int64(asset.duration.seconds * 600), timescale: 600)
        selectedTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: duration)
    }
    
    required public init() {
        super.init()
    }
    
    open override func image(at time: CMTime, renderSize: CGSize) -> CIImage? {
        let time = sourceTime(for: time)
        let sampleBuffer: CMSampleBuffer? = loadSamplebuffer(for: time)
        if let sampleBuffer = sampleBuffer, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            return CIImage(cvPixelBuffer: imageBuffer)
        }
        
        return image;
    }
    
    private func loadSamplebuffer(for time: CMTime) -> CMSampleBuffer? {
        if time < self.lastReaderTime || time.seconds > self.lastReaderTime.seconds + 1.0 {
            self.cleanReader()
        }
        
        if assetReader == nil || trackOutput == nil {
            createAssetReaderOutput(at: time)
        }
        
        if assetReader == nil || trackOutput == nil {
            return nil
        }
        
        self.lastReaderTime = time
        
        var currentSampleBuffer: CMSampleBuffer?
        while let sampleBuffer = trackOutput?.copyNextSampleBuffer() {
            if CMSampleBufferGetImageBuffer(sampleBuffer) != nil {
                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                if presentationTime.seconds > time.seconds - 0.017 {
                    currentSampleBuffer = sampleBuffer
                    break
                }
            }
        }
        return currentSampleBuffer
    }
    
    private func createAssetReaderOutput(at time: CMTime) {
        guard let asset = asset,
            let reader = try? AVAssetReader.init(asset: asset),
            let track = asset.tracks(withMediaType: .video).first else {
                return
        }
        let outputSettings: [String : Any] =
            [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA,
             String(kCVPixelBufferOpenGLESCompatibilityKey): true]
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        trackOutput.alwaysCopiesSampleData = false
        
        guard reader.canAdd(trackOutput) else {
            return
        }
        reader.add(trackOutput)
        reader.timeRange = CMTimeRange(start: time, end: selectedTimeRange.end);
        reader.startReading()
        
        self.assetReader = reader
        self.trackOutput = trackOutput
    }
    
    private func cleanReader() {
        self.assetReader?.cancelReading()
        self.assetReader = nil
        self.trackOutput = nil
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
        let resource = super.copy(with: zone) as! AVAssetReaderImageResource
        resource.asset = asset
        return resource
    }
}
