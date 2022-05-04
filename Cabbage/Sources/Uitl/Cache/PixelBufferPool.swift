//
//  PixelBufferPool.swift
//  Cabbage
//
//  Created by Vito on 2022/5/4.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import CoreVideo

public class PixelBufferPool: PixelBufferPoolProtocol {
    
    private let lock = NSLock()
    private var poolCache: [String: CVPixelBufferPool] = [:]
    
    
    // MARK: - PixelBufferPoolProtocol
    public func makePixelBuffer(size: CGSize) -> CVPixelBuffer? {
        return self.makePixelBuffer(size: size, format: kCVPixelFormatType_32BGRA)
    }
    
    public func makePixelBuffer(size: CGSize, format: OSType) -> CVPixelBuffer? {
        self.lock.lock()
        guard let pixelBufferPool = self.makePixelBufferPool(format: format, size: size) else {
            self.lock.unlock()
            return nil
        }
        
        var pixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault,
                                           pixelBufferPool,
                                           &pixelBuffer)
        self.lock.unlock()
        return pixelBuffer
    }
    
    public func flushPool() {
        self.lock.lock()
        self.poolCache.values.forEach { pool in
            CVPixelBufferPoolFlush(pool, CVPixelBufferPoolFlushFlags.excessBuffers)
        }
        self.poolCache.removeAll()
        self.lock.unlock()
    }
    
    // MARK: - Helper
    
    private func makePixelBufferPool(format: OSType, size: CGSize) -> CVPixelBufferPool? {
        let key = self.makeKey(format: format, size: size)
        if let pool = self.poolCache[key] {
            return pool
        }
        
        let attributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: format,
            kCVPixelBufferWidthKey: size.width,
            kCVPixelBufferHeightKey: size.height,
            kCVPixelBufferIOSurfacePropertiesKey: [:],
            kCVPixelBufferMetalCompatibilityKey: true,
            kCVPixelBufferOpenGLESCompatibilityKey: true
        ]
        var pixelBufferPool: CVPixelBufferPool? = nil
        let status = CVPixelBufferPoolCreate(kCFAllocatorDefault,
                                             nil,
                                             attributes as CFDictionary,
                                             &pixelBufferPool)
        guard let pool = pixelBufferPool else {
            Log.error("PixelBufferPool create pool failed, status: \(status)")
            return nil
        }
        
        self.poolCache[key] = pool
        
        return pool
    }
    
    private func makeKey(format: OSType, size: CGSize) -> String {
        return "\(Int(size.width)), \(Int(size.height)), \(format)"
    }
}
