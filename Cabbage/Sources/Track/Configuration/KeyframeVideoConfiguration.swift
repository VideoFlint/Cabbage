//
//  KeyframeVideoConfiguration.swift
//  Cabbage
//
//  Created by Vito on 2018/11/11.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation
import CoreImage
import CoreMedia

public struct KeyframeValueParam {
    public var fromValue: KeyframeValue?
    public var toValue: KeyframeValue
    public var tween: CGFloat
    public var info: VideoConfigurationEffectInfo
}

public protocol KeyframeValue: NSCopying {
    static func applyEffect(to sourceImage: CIImage, param: KeyframeValueParam) -> CIImage
}

public class KeyframeVideoConfiguration<Value: KeyframeValue>: VideoConfigurationProtocol {
    
    public init() { }
    
    public class Keyframe: NSCopying {
        public var time = CMTime.zero
        public var value: Value
        public var timingFunction: ((CGFloat) -> CGFloat)?
        
        public init(time: CMTime, value: Value) {
            self.time = time
            self.value = value
        }
        
        // MARK: - NSCopying
        
        public func copy(with zone: NSZone? = nil) -> Any {
            let value = self.value.copy(with: zone) as! Value
            let keyframe = Keyframe(time: time, value: value)
            keyframe.timingFunction = timingFunction
            return keyframe
        }
    }
    
    
    public private(set) var keyframes: [Keyframe] = []
    
    public func insert(_ keyframe: Keyframe) {
        var index = keyframes.count
        
        if let searchIndex = keyframes.firstIndex(where: { $0.time > keyframe.time }) {
            index = searchIndex
        }
        
        keyframes.insert(keyframe, at: index)
    }
    
    public func remove(_ keyframe: Keyframe) {
        keyframes.removeAll(where: { $0 === keyframe })
    }
    
    public func removeAllKeyframes() {
        keyframes = []
    }
    
    public func removeKeyframes(in timeRange: CMTimeRange) {
        keyframes.removeAll(where: { timeRange.containsTime($0.time) })
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let configuration = KeyframeVideoConfiguration()
        configuration.keyframes = keyframes.map({ $0.copy(with: zone) as! Keyframe })
        return configuration
    }
    
    // MARK: - VideoConfigurationProtocol
    
    public func applyEffect(to sourceImage: CIImage, info: VideoConfigurationEffectInfo) -> CIImage {
        var finalImage = sourceImage
        
        if keyframes.count > 0 {
            let toIndex: Int = {
                if let toIndex = keyframes.firstIndex(where: { (info.time - info.timeRange.start) <= $0.time }) {
                    return toIndex
                }
                return 0
            }()
            
            let fromKeyframe: Keyframe? = {
                if toIndex > 0 {
                    return keyframes[toIndex - 1]
                }
                return nil
            }()
            let toKeyframe = keyframes[toIndex]
            
            var tween: CGFloat = {
                let startTime = fromKeyframe != nil ? fromKeyframe!.time : CMTime.zero
                let relativeTime = (info.time - info.timeRange.start) - startTime
                let keyframeDuration = toKeyframe.time - startTime
                return CGFloat(relativeTime.seconds / keyframeDuration.seconds)
            }()
            
            tween = min(1.0, tween);
            if let timingFunction = toKeyframe.timingFunction {
                tween = timingFunction(tween)
            }
            let param = KeyframeValueParam(fromValue: fromKeyframe?.value, toValue: toKeyframe.value, tween: tween, info: info)
            finalImage = Value.applyEffect(to: sourceImage, param: param)
        }
        
        return finalImage
    }
    
}

// MARK: - Keyframe Values

public class TransformKeyframeValue: KeyframeValue {
    
    public var scale: CGFloat = 1.0
    public var rotation: CGFloat = 0
    public var translation: CGPoint = CGPoint.zero
    
    public init() { }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let value = TransformKeyframeValue.init()
        value.scale = scale
        value.rotation = rotation
        value.translation = translation
        return value
    }
    
    public static func applyEffect(to sourceImage: CIImage, param: KeyframeValueParam) -> CIImage {
        guard let toValue = param.toValue as? TransformKeyframeValue else {
            return sourceImage
        }
        var finalImage = sourceImage
        
        let fromValue: TransformKeyframeValue = {
            if let fromValue = param.fromValue as? TransformKeyframeValue {
                return fromValue
            }
            return TransformKeyframeValue()
        }()
        
        var transform = CGAffineTransform.identity
        transform = transform.concatenating(CGAffineTransform(translationX: -(sourceImage.extent.origin.x + sourceImage.extent.width/2), y: -(sourceImage.extent.origin.y + sourceImage.extent.height/2)))
        
        let scale = fromValue.scale + (toValue.scale - fromValue.scale) * param.tween
        transform = transform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
        
        let rotation = fromValue.rotation + (toValue.rotation - fromValue.rotation) * param.tween
        transform = transform.concatenating(CGAffineTransform(rotationAngle: rotation))
        
        let translationX = fromValue.translation.x + (toValue.translation.x - fromValue.translation.x) * param.tween
        let translationY = fromValue.translation.y + (toValue.translation.y - fromValue.translation.y) * param.tween
        transform = transform.concatenating(CGAffineTransform(translationX: translationX, y: translationY))
        
        transform = transform.concatenating(CGAffineTransform(translationX: (sourceImage.extent.origin.x + sourceImage.extent.width/2), y: (sourceImage.extent.origin.y + sourceImage.extent.height/2)))
        
        finalImage = sourceImage.transformed(by: transform)
        
        return finalImage
    }
    
}

public class OpacityKeyframeValue: KeyframeValue {
    
    public var opacity: CGFloat = 1.0
    
    public init() { }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let value = OpacityKeyframeValue.init()
        value.opacity = opacity
        return value
    }
    
    public static func applyEffect(to sourceImage: CIImage, param: KeyframeValueParam) -> CIImage {
        guard let toValue = param.toValue as? OpacityKeyframeValue else {
            return sourceImage
        }
        let fromValue: OpacityKeyframeValue = {
            if let fromValue = param.fromValue as? OpacityKeyframeValue {
                return fromValue
            }
            return OpacityKeyframeValue()
        }()
        let toOpacity = toValue.opacity
        let fromOpacity = fromValue.opacity
        let opacity = fromOpacity + (toOpacity - fromOpacity) * param.tween
        return sourceImage.apply(alpha: opacity)
    }
    
}
