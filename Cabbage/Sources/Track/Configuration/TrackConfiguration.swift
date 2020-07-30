//
//  TrackConfiguration.swift
//  Cabbage
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import CoreImage

public struct VideoConfigurationEffectInfo {
    public var time = CMTime.zero
    public var renderSize = CGSize.zero
    public var timeRange = CMTimeRange.zero
}

public protocol VideoConfigurationProtocol: NSCopying {
    func applyEffect(to sourceImage: CIImage, info: VideoConfigurationEffectInfo) -> CIImage
}

public class VideoConfiguration: NSObject, VideoConfigurationProtocol {
    
    public static func createDefaultConfiguration() -> VideoConfiguration {
        return VideoConfiguration()
    }
    
    public enum BaseContentMode {
        case aspectFit
        case aspectFill
        case custom
    }
    public var contentMode: BaseContentMode = .aspectFit
    /// Default is renderSize
    public var frame: CGRect?
    public var transform: CGAffineTransform?
    public var opacity: Float = 1.0
    public var configurations: [VideoConfigurationProtocol] = []
    
    public required override init() {
        super.init()
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let configuration = type(of: self).init()
        configuration.contentMode = contentMode
        configuration.transform = transform
        configuration.opacity = opacity;
        configuration.configurations = configurations.map({ $0.copy(with: zone) as! VideoConfigurationProtocol });
        configuration.frame = frame;
        return configuration
    }
    
    // MARK: - VideoConfigurationProtocol
    
    public func applyEffect(to sourceImage: CIImage, info: VideoConfigurationEffectInfo) -> CIImage {
        var finalImage = sourceImage

        if let userTransform = self.transform {
            var transform = CGAffineTransform.identity
            transform = transform.concatenating(CGAffineTransform(translationX: -(finalImage.extent.origin.x + finalImage.extent.width/2), y: -(finalImage.extent.origin.y + finalImage.extent.height/2)))
            transform = transform.concatenating(userTransform)
            transform = transform.concatenating(CGAffineTransform(translationX: (finalImage.extent.origin.x + finalImage.extent.width/2), y: (finalImage.extent.origin.y + finalImage.extent.height/2)))
            finalImage = finalImage.transformed(by: transform)
        }

        let frame = self.frame ?? CGRect(origin: CGPoint.zero, size: info.renderSize)
        switch contentMode {
        case .aspectFit:
            let transform = CGAffineTransform.transform(by: finalImage.extent, aspectFitInRect: frame)
            finalImage = finalImage.transformed(by: transform).cropped(to: frame)
            break
        case .aspectFill:
            let transform = CGAffineTransform.transform(by: finalImage.extent, aspectFillRect: frame)
            finalImage = finalImage.transformed(by: transform).cropped(to: frame)
            break
        case .custom:
            var transform = CGAffineTransform(scaleX: frame.size.width / sourceImage.extent.size.width, y: frame.size.height / sourceImage.extent.size.height)
            let translateTransform = CGAffineTransform.init(translationX: frame.origin.x, y: frame.origin.y)
            transform = transform.concatenating(translateTransform)
            finalImage = finalImage.transformed(by: transform)
            break
        }
        
        finalImage = finalImage.apply(alpha: CGFloat(opacity))
        
        configurations.forEach { (videoConfiguration) in
            finalImage = videoConfiguration.applyEffect(to: finalImage, info: info)
        }
        
        return finalImage
    }
}

public protocol AudioConfigurationProtocol: AudioProcessingNode, NSCopying { }

public class AudioConfiguration: NSObject, NSCopying {
    
    public static func createDefaultConfiguration() -> AudioConfiguration {
        return AudioConfiguration()
    }

    public var volume: Float = 1.0;
    public var nodes: [AudioConfigurationProtocol] = []
    
    public required override init() {
        super.init()
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let configuration = type(of: self).init()
        configuration.volume = volume
        configuration.nodes = nodes.map { $0.copy() as! AudioConfigurationProtocol }
        return configuration
    }
    
}

public class VolumeAudioConfiguration: NSObject, AudioConfigurationProtocol {
    
    public var timeRange: CMTimeRange
    public var startVolume: Float
    public var endVolume: Float
    public var timingFunction: ((Double) -> Double)?
    public required init(timeRange: CMTimeRange, startVolume: Float, endVolume: Float) {
        self.timeRange = timeRange
        self.startVolume = startVolume
        self.endVolume = endVolume
        super.init()
    }
    
    public func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>) {
        if timeRange.duration.isValid {
            if self.timeRange.intersection(timeRange).duration.seconds > 0 {
                var percent = (timeRange.end.seconds - self.timeRange.start.seconds) / self.timeRange.duration.seconds
                if let timingFunction = timingFunction {
                    percent = timingFunction(percent)
                }
                let volume = startVolume + (endVolume - startVolume) * Float(percent)
                AudioMixer.changeVolume(for: bufferListInOut, volume: volume)
            }
        }
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let configuration = type(of: self).init(timeRange: timeRange, startVolume: startVolume, endVolume: endVolume)
        configuration.timingFunction = timingFunction
        return configuration
    }
    
}
