//
//  TextureCache.swift
//  Cabbage
//
//  Created by Vito on 2022/4/27.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import CoreVideo

public class TextureCache {
    public private(set) var device: MTLDevice
    
    public private(set) var textureCache: CVMetalTextureCache?
    public private(set) var textureLoader: MTKTextureLoader
    
    public init(device: MTLDevice) {
        self.device = device
        let cacheAttributes: CFDictionary = [kCVMetalTextureCacheMaximumTextureAgeKey: 0] as CFDictionary
        let textureAttributes: CFDictionary? = {
            if #available(iOS 11.0, macOS 10.13, *) {
                return [kCVMetalTextureUsage: [MTLTextureUsage.shaderRead,
                                               MTLTextureUsage.renderTarget,
                                               MTLTextureUsage.shaderWrite,
                                               MTLTextureUsage.pixelFormatView]] as CFDictionary
            }
            return nil
        }()
        CVMetalTextureCacheCreate(nil,
                                  cacheAttributes,
                                  device,
                                  textureAttributes,
                                  &self.textureCache)
        self.textureLoader = MTKTextureLoader(device: device)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryWarning(_:)),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }
    
    public func makeImage(size: CGSize) -> Image? {
        guard let pixelBuffer = CacheContext.shared.pixelBufferPool.makePixelBuffer(size: size) else {
            return nil
        }
        let image = self.makeRGBTextureFromRGBPixelBuffer(pixelBuffer)
        return image
    }
    
    public func makeRGBTextureFromRGBPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> Image? {
        return self.makeTexture(pixelBuffer: pixelBuffer, planeIndex: 0, pixelFormat: .bgra8Unorm)
    }
    
    public func makeLuminanceTexture(pixelBuffer: CVPixelBuffer) -> Image? {
        var format = MTLPixelFormat.r8Unorm
        let pixelBufferFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        if pixelBufferFormat == kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange ||
            pixelBufferFormat == kCVPixelFormatType_420YpCbCr10BiPlanarFullRange {
            format = MTLPixelFormat.r16Unorm
        }
        return self.makeTexture(pixelBuffer: pixelBuffer, planeIndex: 0, pixelFormat: format)
    }
    
    public func makeChrominanaceTexture(pixelBuffer: CVPixelBuffer) -> Image? {
        var format = MTLPixelFormat.rg8Unorm
        let pixelBufferFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        if pixelBufferFormat == kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange ||
            pixelBufferFormat == kCVPixelFormatType_420YpCbCr10BiPlanarFullRange {
            format = MTLPixelFormat.rg16Unorm
        }
        return self.makeTexture(pixelBuffer: pixelBuffer, planeIndex: 1, pixelFormat: format)
    }
    
    public func makeTexture(pixelBuffer: CVPixelBuffer, planeIndex: Int, pixelFormat: MTLPixelFormat) -> Image? {
        var textureImage: CVMetalTexture?
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let status: CVReturn = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                         self.textureCache!,
                                                                         pixelBuffer,
                                                                         nil,
                                                                         pixelFormat,
                                                                         width,
                                                                         height,
                                                                         planeIndex,
                                                                         &textureImage)
        guard let textureImage = textureImage else {
            Log.error("[ERROR] makeTexture() create metal texture format(" + String(pixelFormat.rawValue) + ") failed: " + String(status))
            return nil
        }
        
        guard let texture = CVMetalTextureGetTexture(textureImage) else {
            Log.error("[ERROR] makeTexture() get metal texture failed: ")
            return nil
        }
        
        let image = Image(pixelBuffer: pixelBuffer, texture: texture)
        return image
    }
    
    public func cleanCache() {
        if let textureCache = self.textureCache {
            CVMetalTextureCacheFlush(textureCache, 0)
        }
    }
    
    @objc private func didReceiveMemoryWarning(_ notification: Notification) {
        self.cleanCache()
    }
    
}
