//
//  Resource.swift
//  Cabbage
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import CoreImage

public struct ResourceTrackInfo {
    public var track: AVAssetTrack
    public var selectedTimeRange: CMTimeRange
    public var scaleToDuration: CMTime
}


public protocol ResourceTrackInfoProvider: AnyObject {
    func trackInfo(for type: AVMediaType, at index: Int) -> ResourceTrackInfo
    func image(at time: CMTime, renderSize: CGSize) -> CIImage?
}

open class Resource: NSObject, ResourceTrackInfoProvider, RenderStageDelegate {
    
    /// Max duration of this resource
    open var duration: CMTime = CMTime.zero
    
    /// Selected time range, indicate how many resources will be inserted to AVCompositionTrack
    open var selectedTimeRange: CMTimeRange = CMTimeRange.zero
    
    private var _scaledDuration: CMTime = CMTime.invalid
    public var scaledDuration: CMTime {
        get {
            if !_scaledDuration.isValid {
                return selectedTimeRange.duration
            }
            return _scaledDuration
        }
        set {
            _scaledDuration = newValue
        }
    }
    
    /// Natural frame size of this resource
    open var size: CGSize = .zero
    
    private let renderStage: RenderStage
    
    required override public init() {
        renderStage = RenderStage()
        super.init()
        renderStage.delegate = self
    }
    
    public func sourceTime(for timelineTime: CMTime) -> CMTime {
        let seconds = selectedTimeRange.start.seconds + timelineTime.seconds * (selectedTimeRange.duration.seconds / scaledDuration.seconds)
        return CMTime(seconds: seconds, preferredTimescale: 600)
    }
    
    
    
    /// Provide tracks for specific media type
    ///
    /// - Parameter type: specific media type, currently only support AVMediaTypeVideo and AVMediaTypeAudio
    /// - Returns: tracks
    open func tracks(for type: AVMediaType) -> [AVAssetTrack] {
        if let tracks = Resource.emptyAsset?.tracks(withMediaType: type) {
            return tracks
        }
        return []
    }
    
    // MARK: - ResourceTrackInfoProvider
    
    public func trackInfo(for type: AVMediaType, at index: Int) -> ResourceTrackInfo {
        let track = tracks(for: type)[index]
        let emptyDuration = CMTime(value: 1, 30)
        let emptyTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: emptyDuration)
        return ResourceTrackInfo(track: track,
                                 selectedTimeRange: emptyTimeRange,
                                 scaleToDuration: scaledDuration)
    }
    
    open func image(at time: CMTime, renderSize: CGSize) -> CIImage? {
        return nil
    }
    
    // MARK: - RenderStageDelegate
    func leaveRenderTimeRange(_ renderStage: RenderStage) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5, execute: self.cancelBlcok)
    }
    
    func enterRenderTimeRange(_ renderStage: RenderStage) {
        self.cancelBlcok.cancel()
    }
    
    // MARK: Cache Manager
    
    private lazy var cancelBlcok = DispatchWorkItem { [weak self] in
        guard let strongSelf = self else {
            return
        }
        strongSelf.cleanCache()
    }
    
    open func cleanCache() {
        // Implement by subclass if needed
    }
    
    func updateRenderTime(_ renderTime: CMTime, timelineTimeRange: CMTimeRange) {
        self.renderStage.updateRenderTime(renderTime, timelineTimeRange: timelineTimeRange)
    }
    
    // MARK: - Helper
    
    private static let emptyAsset: AVAsset? = {
        let bundle = Bundle(for: ImageResource.self)
        if let videoURL = bundle.url(forResource: "black_empty", withExtension: "mp4") {
            return AVAsset(url: videoURL)
        }
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

public class ResourceTask {
    public var cancelHandler: (() -> Void)?
    
    public init(cancel: (() -> Void)? = nil) {
        self.cancelHandler = cancel
    }
    
    public func cancel() {
        cancelHandler?()
    }
}

public extension Resource {
    func setSpeed(_ speed: Float) {
        scaledDuration = selectedTimeRange.duration * (1 / speed)
    }
}
