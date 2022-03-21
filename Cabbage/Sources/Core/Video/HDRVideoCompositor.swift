//
//  HDRVideoCompositor.swift
//  Cabbage
//
//  Created by Vito on 2022/3/21.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation

import AVFoundation
import CoreImage

open class HDRVideoCompositor: VideoCompositor  {
    
    public var supportsHDRSourceFrames: Bool = true
    public var supportsWideColorSourceFrames: Bool = true
    
    public override init() {
        super.init()
        sourcePixelBufferAttributes = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr10BiPlanarFullRange,
                                       String(kCVPixelBufferOpenGLESCompatibilityKey): true,
                                       String(kCVPixelBufferMetalCompatibilityKey): true];
        requiredPixelBufferAttributesForRenderContext = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr10BiPlanarFullRange,
                                                         String(kCVPixelBufferOpenGLESCompatibilityKey): true,
                                                         String(kCVPixelBufferMetalCompatibilityKey): true];
    }

}
