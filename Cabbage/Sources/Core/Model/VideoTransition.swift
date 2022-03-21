//
//  VideoTransition.swift
//  Cabbage
//
//  Created by Vito on 01/03/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreImage
import CoreMedia

public protocol VideoTransition: AnyObject {
    var identifier: String { get }
    var duration: CMTime { get }
    func renderImage(foregroundImage: CIImage,
                     backgroundImage: CIImage,
                     forTweenFactor tween: Float64,
                     renderSize: CGSize) -> CIImage
}

open class NoneTransition: VideoTransition {
    public var identifier: String {
        return String(describing: self)
    }
    
    open var duration: CMTime
    
    public init(duration: CMTime = CMTime.zero) {
        self.duration = duration
    }
    
    open func renderImage(foregroundImage: CIImage, backgroundImage: CIImage, forTweenFactor tween: Float64, renderSize: CGSize) -> CIImage {
        return foregroundImage.composited(over: backgroundImage)
    }
}

public class CrossDissolveTransition: NoneTransition {
    
    override public func renderImage(foregroundImage: CIImage, backgroundImage: CIImage, forTweenFactor tween: Float64, renderSize: CGSize) -> CIImage {
        if let crossDissolveFilter = CIFilter(name: "CIDissolveTransition") {
            crossDissolveFilter.setValue(backgroundImage, forKey: "inputImage")
            crossDissolveFilter.setValue(foregroundImage, forKey: "inputTargetImage")
            crossDissolveFilter.setValue(tween, forKey: "inputTime")
            if let outputImage = crossDissolveFilter.outputImage {
                return outputImage
            }
        }
        return super.renderImage(foregroundImage: foregroundImage, backgroundImage: backgroundImage, forTweenFactor: tween, renderSize: renderSize)
    }
}

public class SwipeTransition: NoneTransition {
    
    override public func renderImage(foregroundImage: CIImage, backgroundImage: CIImage, forTweenFactor tween: Float64, renderSize: CGSize) -> CIImage {
        if let filter = CIFilter(name: "CISwipeTransition") {
            let targetImage = foregroundImage
            filter.setValue(backgroundImage, forKey: "inputImage")
            filter.setValue(targetImage, forKey: "inputTargetImage")
            filter.setValue(tween, forKey: "inputTime")
            let extent = CIVector(x: targetImage.extent.origin.x,
                                  y: targetImage.extent.origin.y,
                                  z: targetImage.extent.size.width,
                                  w: targetImage.extent.size.height)
            filter.setValue(extent, forKey: "inputExtent")
            
            filter.setValue(targetImage.extent.size.width, forKey: "inputWidth")
            if let outputImage = filter.outputImage {
                return outputImage
            }
        }
        return super.renderImage(foregroundImage: foregroundImage, backgroundImage: backgroundImage, forTweenFactor: tween, renderSize: renderSize)
    }
    
}

public class PushTransition: NoneTransition {
    
    override public func renderImage(foregroundImage: CIImage, backgroundImage: CIImage, forTweenFactor tween: Float64, renderSize: CGSize) -> CIImage {
        
        let tween = TimingFunctionFactory.quadraticEaseInOut(p: Float(tween))
        let offsetTransform = CGAffineTransform(translationX: renderSize.width * CGFloat(tween), y: 0)
        let bgImage = image(backgroundImage, apply: offsetTransform)
        
        let foregroundTransform = CGAffineTransform(translationX: renderSize.width * CGFloat(-1 + tween), y: 0)
        let frontImage = image(foregroundImage, apply: foregroundTransform)
        
        let resultImage = bgImage.composited(over: frontImage)
        return resultImage
    }
    
    private func image(_ image: CIImage, apply transform: CGAffineTransform) -> CIImage {
        let filter = CIFilter(name: "CIAffineTransform")!
        filter.setValue(image, forKey: "inputImage")
        filter.setValue(transform, forKey: "inputTransform")
        guard let outputImage = filter.outputImage else {
            return image
        }
        
        return outputImage
    }
    
}

public class BoundingUpTransition: NoneTransition {
    
    override public func renderImage(foregroundImage: CIImage, backgroundImage: CIImage, forTweenFactor tween: Float64, renderSize: CGSize) -> CIImage {
        let tween = TimingFunctionFactory.quadraticEaseInOut(p: Float(tween))
        let height = renderSize.height
        let offsetTransform = CGAffineTransform(translationX: 0, y: height * CGFloat(tween))
        let bgImage = image(backgroundImage, apply: offsetTransform)
        
        let scale: CGFloat = {
            let factor = 0.5 - abs(0.5 - tween)
            return CGFloat(1 + (factor * 2 * 0.1))
        }()
        let foregroundTransform = CGAffineTransform(translationX: 0, y: height * CGFloat(-1 + tween)).scaledBy(x: scale, y: scale)
        let frontImage = image(foregroundImage, apply: foregroundTransform)
        
        let resultImage = frontImage.composited(over: bgImage)
        return resultImage
    }
    
    private func image(_ image: CIImage, apply transform: CGAffineTransform) -> CIImage {
        let filter = CIFilter(name: "CIAffineTransform")!
        filter.setValue(image, forKey: "inputImage")
        filter.setValue(transform, forKey: "inputTransform")
        guard let outputImage = filter.outputImage else {
            return image
        }
        
        return outputImage
    }
    
}

public class FadeTransition: NoneTransition {
    
    override public func renderImage(foregroundImage: CIImage, backgroundImage: CIImage, forTweenFactor tween: Float64, renderSize: CGSize) -> CIImage {
        let backgroundAlpha: CGFloat = {
            let alpha: CGFloat = CGFloat((0.5 - tween) * 2)
            if alpha > 0 {
                return alpha
            }
            return 0
        }()
        let foregroundAlpha: CGFloat = {
            let alpha: CGFloat = CGFloat((tween - 0.5) * 2)
            if alpha > 0 {
                return alpha
            }
            return 0
        }()
        let frontImage = foregroundImage.apply(alpha: foregroundAlpha)
        let bgImage = backgroundImage.apply(alpha: backgroundAlpha)
        
        let resultImage = frontImage.composited(over: bgImage)
        return resultImage
    }
    
    
}
