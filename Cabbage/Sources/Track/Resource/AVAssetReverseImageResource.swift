//
//  AVAssetReverseImageResource.swift
//  Cabbage
//
//  Created by Vito on 2018/11/18.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation
import CoreImage
import AVFoundation


/// Load image from AVAssetReader as video frame, but order reversed
open class AVAssetReverseImageResource: ImageResource {
    
    public var asset: AVAsset?
    
    private var assetReader: AVAssetReader?
    private var trackOutput: AVAssetReaderTrackOutput?
    private var sampleBuffers: [CMSampleBuffer] = []
    private var lastReaderTime = CMTime.zero
    
    private var loadBufferQueue: DispatchQueue = DispatchQueue(label: "com.cabbage.reverse.loadbuffer")
    
    private var bufferDuration = CMTime(seconds: 0.3, preferredTimescale: 600)
    
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
        guard selectedTimeRange.duration > time else {
            return nil
        }
        let realTime = max(0, selectedTimeRange.end.seconds - time.seconds) + selectedTimeRange.start.seconds
        
        let sampleBuffer: CMSampleBuffer? = loadSamplebuffer(for: CMTime(seconds: realTime, preferredTimescale: 600))
        if let sampleBuffer = sampleBuffer, let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            return CIImage(cvPixelBuffer: imageBuffer)
        }
        
        return image;
    }
    
    private func loadSamplebuffer(for time: CMTime) -> CMSampleBuffer? {
        // 1. If seeking backward, reset
        if time > self.lastReaderTime {
            loadBufferQueue.sync {
                cleanReader()
                self.sampleBuffers.removeAll()
            }
        }
        self.lastReaderTime = time
        
        
        // 2. get currentSampleBuffer
        var currentSampleBuffer: CMSampleBuffer?
        func getCurrentSampleBuffer() -> CMSampleBuffer? {
            let sampleBuffers = self.sampleBuffers
            return sampleBuffers.first { (sampleBuffer) -> Bool in
                return abs(CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds - time.seconds) < 0.05
            }
        }
        
        func removeUnusedBuffers() {
            loadBufferQueue.async {
                self.sampleBuffers.removeAll { (sampleBuffer) -> Bool in
                    let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
                    return presentationTime > time.seconds ||
                        (presentationTime < (self.selectedTimeRange.start.seconds - self.bufferDuration.seconds * 2))
                }
            }
        }
        
        currentSampleBuffer = getCurrentSampleBuffer()
        
        if currentSampleBuffer != nil {
            removeUnusedBuffers()
            // preload if need
            preloadSampleBuffers(at: time)
            return currentSampleBuffer
        }
        
        // 3. Not preload yet, force load
        loadBufferQueue.sync {
            currentSampleBuffer = getCurrentSampleBuffer()
            if currentSampleBuffer == nil {
                self.forceLoadSampleBuffer(at: time)
            }
        }
        
        if currentSampleBuffer != nil {
            return currentSampleBuffer
        }
        
        currentSampleBuffer = getCurrentSampleBuffer()
        
        preloadSampleBuffers(at: time)
        
        removeUnusedBuffers()
        
        return currentSampleBuffer
    }
    
    private func forceLoadSampleBuffer(at time: CMTime) {
        var endTime = time
        if let sampleBuffer = sampleBuffers.last {
            endTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        }
        let startSeconds: Double = max(endTime.seconds - bufferDuration.seconds, selectedTimeRange.start.seconds);
        let startTime = CMTime(seconds: startSeconds, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTime, end: endTime);
        let reader = createAssetReader(for: timeRange)
        if let assetReader = reader.0, let trackOutput = reader.1 {
            assetReader.startReading()
            
            while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
                if CMSampleBufferGetImageBuffer(sampleBuffer) != nil {
                    self.sampleBuffers.insert(sampleBuffer, at: 0)
                }
            }
            self.sampleBuffers.sort { (buffer1, buffer2) -> Bool in
                return CMSampleBufferGetPresentationTimeStamp(buffer1) > CMSampleBufferGetPresentationTimeStamp(buffer2)
            }
            assetReader.cancelReading()
        }
    }
    
    private var isPreloading = false
    private func preloadSampleBuffers(at time: CMTime) {
        guard !isPreloading else {
            return
        }
        
        var needPreload = false
        
        if let sampleBuffer = sampleBuffers.last {
            let presentationDuration = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
            needPreload = presentationDuration > 0 && presentationDuration > (time.seconds) - bufferDuration.seconds
        } else {
            needPreload = true
        }
        
        if !needPreload {
            return
        }
        
        isPreloading = true
        loadBufferQueue.async {
            if self.assetReader == nil || self.trackOutput == nil {
                self.createAssetReaderOutput(at: time)
            } else {
                self.resetReader(at: time)
            }
            
            if self.assetReader == nil || self.trackOutput == nil {
                return
            }
            
            while let sampleBuffer = self.trackOutput?.copyNextSampleBuffer() {
                if CMSampleBufferGetImageBuffer(sampleBuffer) != nil {
                    self.sampleBuffers.insert(sampleBuffer, at: 0)
                }
            }
            self.sampleBuffers.sort { (buffer1, buffer2) -> Bool in
                return CMSampleBufferGetPresentationTimeStamp(buffer1) > CMSampleBufferGetPresentationTimeStamp(buffer2)
            }
            
            self.isPreloading = false
        }
    }
    
    private func createAssetReader(for timeRange: CMTimeRange) -> (AVAssetReader?, AVAssetReaderTrackOutput?) {
        guard let asset = asset,
            let reader = try? AVAssetReader.init(asset: asset),
            let track = asset.tracks(withMediaType: .video).first else {
                return (nil, nil)
        }
        let size = track.naturalSize.applying(track.preferredTransform)
        let outputSettings: [String : Any] =
            [String(kCVPixelBufferWidthKey): size.width,
             String(kCVPixelBufferHeightKey): size.height]
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        trackOutput.alwaysCopiesSampleData = false
        trackOutput.supportsRandomAccess = true
        
        guard reader.canAdd(trackOutput) else {
            return (nil, nil)
        }
        reader.add(trackOutput)
        reader.timeRange = timeRange
        
        return (reader, trackOutput)
    }
    
    private func createAssetReaderOutput(at time: CMTime) {
        let startSeconds: Double = max(time.seconds - bufferDuration.seconds, selectedTimeRange.start.seconds);
        let startTime = CMTime(seconds: startSeconds, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTime, end: time);
        let reader = createAssetReader(for: timeRange)
        
        self.assetReader = reader.0
        self.trackOutput = reader.1
        assetReader?.startReading()
    }
    
    private func resetReader(at time: CMTime) {
        guard let trackOutput = self.trackOutput else {
            return
        }
        var endTime = time
        if let sampleBuffer = sampleBuffers.last {
            endTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        }
        let startSeconds: Double = max(endTime.seconds - bufferDuration.seconds, selectedTimeRange.start.seconds);
        let startTime = CMTime(seconds: startSeconds, preferredTimescale: 600)
        trackOutput.reset(forReadingTimeRanges: [NSValue(timeRange: CMTimeRange(start: startTime, end: endTime))])
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
        let resource = super.copy(with: zone) as! AVAssetReverseImageResource
        resource.asset = asset
        resource.bufferDuration = bufferDuration;
        return resource
    }
}
