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
import VideoToolbox


/// Load image from PHAsset as video frame
open class AVAssetReaderImageResource: ImageResource {
    
    public var asset: AVAsset?
    
    private var decompressionSession: VTDecompressionSession?
    
    private var sampleBuffers: [CMSampleBuffer] = []
    private var currentTimeRange = CMTimeRange.zero
    
    deinit {
        if let decompressionSession = decompressionSession {
            VTDecompressionSessionInvalidate(decompressionSession)
        }
    }
    
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
        guard selectedTimeRange.containsTime(time) else {
            return image
        }
        
        createDecodeCompressionIfNeed()
        loadSamplebuffersIfNeed(for: time)
        
        let sampleBuffer: CMSampleBuffer? = {
            for sampleBuffer in sampleBuffers {
                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let currentTime = selectedTimeRange.start + time
                if fabs(presentationTime.seconds - currentTime.seconds) <= 0.17 {
                    return sampleBuffer
                }
            }
            return nil
        }()
        if let sampleBuffer = sampleBuffer {
            if let decodedImageBuffer = decode(sampleBuffer: sampleBuffer) {
                let image = CIImage(cvPixelBuffer: decodedImageBuffer)
                return image
            }
        }
        
        return image;
    }
    
    private func createDecodeCompressionIfNeed() {
        if decompressionSession != nil {
            return
        }
        guard let asset = asset,
            let track = asset.tracks(withMediaType: .video).first,
            track.formatDescriptions.count > 0 else {
                return
        }
        let formatDesc = track.formatDescriptions.first as! CMVideoFormatDescription
        let status = VTDecompressionSessionCreate(allocator: nil, formatDescription: formatDesc, decoderSpecification: nil, imageBufferAttributes: nil, outputCallback: nil, decompressionSessionOut: &decompressionSession)
        if status != noErr {
            // throw someError(status)
            Log.error("Can't create decompressionSession")
        }
    }
    
    private func decode(sampleBuffer: CMSampleBuffer) -> CVImageBuffer? {
        guard let decompressionSession = decompressionSession else {
            return nil;
        }
        var decodedImageBuffer: CVImageBuffer?
        let status = VTDecompressionSessionDecodeFrame(decompressionSession, sampleBuffer: sampleBuffer, flags: [], infoFlagsOut: nil) { (status, flags, imageBuffer, presentationTimeStamp, presentationDuration) in
            if status != noErr {
                // throw someError(status)
                Log.error("1. Can't decode frame, status: \(status)")
                return
            }
            decodedImageBuffer = imageBuffer
        }
        if status != noErr {
            // throw someError(status)
            Log.error("2. Can't decode frame, status: \(status)")
        }
        return decodedImageBuffer
    }
    
    private func loadSamplebuffersIfNeed(for time: CMTime) {
        guard let asset = asset,
            let reader = try? AVAssetReader.init(asset: asset),
            let track = asset.tracks(withMediaType: .video).first else {
                return
        }
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        trackOutput.alwaysCopiesSampleData = false
        
        guard reader.canAdd(trackOutput) else {
            return
        }
        reader.add(trackOutput)
        
        if !currentTimeRange.containsTime(time) {
            var readerTimeRange = CMTimeRange(start: selectedTimeRange.start + time, duration: CMTime(value:60, timescale: 600))
            if readerTimeRange.end > selectedTimeRange.end {
                readerTimeRange.duration = selectedTimeRange.end - readerTimeRange.start
            }
            reader.timeRange = readerTimeRange
            reader.startReading()
            
            currentTimeRange = CMTimeRange(start: time, duration: readerTimeRange.duration)
        
            while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
                if CMSampleBufferGetDataBuffer(sampleBuffer) != nil {
                    sampleBuffers.append(sampleBuffer)
                }
            }
            
            reader.cancelReading()
        }
        
        return
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
