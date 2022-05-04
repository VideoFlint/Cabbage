//
//  CacheContext.swift
//  Cabbage
//
//  Created by Vito on 2022/5/4.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import CoreVideo

public protocol PixelBufferPoolProtocol {
    
    func makePixelBuffer(size: CGSize) -> CVPixelBuffer?
    
    /// Create pixelbuffer from cache
    /// - Parameters:
    ///   - size: pixel size
    ///   - format: pixelBuffer format, see `CVPixelBuffer.h`, example  `kCVPixelFormatType_32BGRA`
    /// - Returns: Pixelbuffer
    func makePixelBuffer(size: CGSize, format: OSType) -> CVPixelBuffer?
    
    /// Clean cache
    func flushPool()
}

public class CacheContext {
    
    public static let shared = CacheContext()
    
    public var pixelBufferPool: PixelBufferPoolProtocol
    
    init() {
        pixelBufferPool = PixelBufferPool()
    }
    
}
