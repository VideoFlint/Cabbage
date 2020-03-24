//
//  BlurVideoConfiguration.swift
//  ScreenFlow
//
//  Created by MorningStar on 2020/3/24.
//  Copyright © 2020 MorningStar. All rights reserved.
//

import Cabbage
import CoreImage

private typealias Filter = (CIImage) -> CIImage

private func blur(radius: Double) -> Filter {
    return { image in
        let parameters: [String: Any] = [
            kCIInputRadiusKey: radius,
            kCIInputImageKey: image
        ]
        guard let filter = CIFilter(name: "CIGaussianBlur",
                                    parameters: parameters)
            else { fatalError() }
        guard let outputImage = filter.outputImage
            else { fatalError() }
        return outputImage
    }
}

class BlurVideoConfiguration: NSObject, VideoConfigurationProtocol {
    
    public var blurRadius: Double?
    
    enum BlurMode {
        case background
        case fill
    }
    public var blurMode: BlurMode = .background
    public required override init() {
        super.init()
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let configuration = type(of: self).init()
        return configuration
    }


    func applyEffect(to sourceImage: CIImage, info: VideoConfigurationEffectInfo) -> CIImage {
        let frame = CGRect(origin: CGPoint.zero, size: info.renderSize)
        var blurImage = sourceImage
        let transform = CGAffineTransform.transform(by: blurImage.extent, aspectFillRect: frame)
        blurImage = blurImage.transformed(by: transform).cropped(to: frame)
        let targetBlurRadius = blurRadius ?? 0
        blurImage = blur(radius: targetBlurRadius)(blurImage)
        guard blurMode == .background else {
            return blurImage
        }
        let compositor = CIFilter(name:"CISourceOverCompositing")
        compositor?.setValue(sourceImage, forKey: kCIInputImageKey)
        compositor?.setValue(blurImage, forKey: kCIInputBackgroundImageKey)
        if let compositedCIImage = compositor?.outputImage {
            return compositedCIImage
        }
        
        return blur(radius: targetBlurRadius)(sourceImage)
    }

}
