//
//  TrackConfiguration.swift
//  Cabbage
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import CoreImage

public class TrackConfiguration: NSObject, NSCopying {
    
    // MARK: - Timing
    
    /// Track's final time range, it will be calculated using track's time, speed, transition and so on
    public var timelineTimeRange: CMTimeRange = CMTimeRange.zero
    public var speed: Float = 1.0
    
    // MARK: - Media
    public var videoConfiguration: VideoConfiguration = .createDefaultConfiguration()
    public var audioConfiguration: AudioConfiguration = .createDefaultConfiguration()
    
    public required override init() {
        super.init()
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let configuration = type(of: self).init()
        configuration.timelineTimeRange = timelineTimeRange
        configuration.speed = speed
        configuration.videoConfiguration = videoConfiguration.copy() as! VideoConfiguration
        configuration.audioConfiguration = audioConfiguration.copy() as! AudioConfiguration
        return configuration
    }
}

public class VideoConfiguration: NSObject, NSCopying {
    
    public static func createDefaultConfiguration() -> VideoConfiguration {
        return VideoConfiguration()
    }
    
    public enum BaseContentMode {
        case aspectFit
        case aspectFill
        case custom
    }
    public var baseContentMode: BaseContentMode = .aspectFit
    public var transform: CGAffineTransform?
    public var filterProcessor: ((CIImage) -> CIImage)?
    
    public required override init() {
        super.init()
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let configuration = type(of: self).init()
        configuration.baseContentMode = baseContentMode
        configuration.filterProcessor = filterProcessor
        configuration.transform = transform
        return configuration
    }
    
    // MARK: - Helper
    
    public func applyTo(sourceImage: CIImage, renderSize: CGSize) -> CIImage {
        var finalImage = sourceImage
        var transform = CGAffineTransform.identity
        switch baseContentMode {
        case .aspectFit:
            let fitTransform = CGAffineTransform.transform(by: finalImage.extent, aspectFitInRect: CGRect(origin: .zero, size: renderSize))
            transform = transform.concatenating(fitTransform)
        case .aspectFill:
            let fillTransform = CGAffineTransform.transform(by: finalImage.extent, aspectFillRect: CGRect(origin: .zero, size: renderSize))
            transform = transform.concatenating(fillTransform)
        case .custom:
            break
        }
        finalImage = finalImage.transformed(by: transform)
        
        if let transform = self.transform {
            finalImage = finalImage.transformed(by: transform)
        }
        
        if let filterProcessor = filterProcessor {
            finalImage = filterProcessor(finalImage)
        }
        
        return finalImage
    }
}

public class AudioConfiguration: NSObject, NSCopying {
    
    public static func createDefaultConfiguration() -> AudioConfiguration {
        return AudioConfiguration()
    }

    public var volume: Float = 1.0;
    public var nodes: [AudioProcessingNode] = []
    
    public required override init() {
        super.init()
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let configuration = type(of: self).init()
        configuration.volume = volume
        configuration.nodes = nodes
        return configuration
    }
    
}
