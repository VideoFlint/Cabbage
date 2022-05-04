//
//  Texture.swift
//  Cabbage
//
//  Created by Vito on 2022/4/25.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import Metal
import CoreVideo
import CoreImage

public class Image {
    
    public private(set) var texture: MTLTexture
    public private(set) var pixelBuffer: CVPixelBuffer
    public private(set) var size: CGSize
    
    public init(pixelBuffer: CVPixelBuffer, texture: MTLTexture) {
        self.pixelBuffer = pixelBuffer
        self.texture = texture
        self.size = CGSize(width: texture.width, height: texture.height)
    }
    
}

public extension RenderContext {
    
    func makeImage(size: CGSize) -> Image? {
        return self.textureCache.makeImage(size: size)
    }
    
    func makeImage(pixelBuffer: CVPixelBuffer) -> Image? {
        return self.textureCache.makeRGBTextureFromRGBPixelBuffer(pixelBuffer)
    }
    
    func makeImage(color: CIColor, size: CGSize) -> Image? {
        guard let image = self.makeImage(size: size) else {
            return nil
        }
        let param = RenderParams()
        param.renderPassDescriptorConfiguration = { (renderPassDescriptor) in
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(color.red,
                                                                                    color.green,
                                                                                    color.blue,
                                                                                    color.alpha)
        }
        param.outputImage = image
        self.render(param)
        return image
    }
    
    func makeImage(filePath: String, orientation: CGImagePropertyOrientation = .up) -> Image? {
        let url = URL(fileURLWithPath: filePath)
        guard let ciimage = CIImage(contentsOf: url) else {
            return nil
        }
        let finnalImage = ciimage.oriented(orientation)
        return self.makeImage(ciimage: finnalImage)
    }
    
    func makeImage(data: Data, orientation: CGImagePropertyOrientation = .up) -> Image? {
        guard var ciimage = CIImage(data: data) else {
            return nil
        }
        ciimage = ciimage.oriented(orientation)
        return self.makeImage(ciimage: ciimage)
    }
    
    func makeImage(cgimage: CGImage, orientation: CGImagePropertyOrientation = .up) -> Image? {
        var ciimage = CIImage(cgImage: cgimage)
        ciimage = ciimage.oriented(orientation)
        return self.makeImage(ciimage: ciimage)
    }
    
    
    func makeImage(ciimage: CIImage) -> Image? {
        guard let image = self.makeImage(size: ciimage.extent.size) else {
            return nil
        }
        self.ciContext.render(ciimage, to: image.pixelBuffer)
        return image
    }
    
}
