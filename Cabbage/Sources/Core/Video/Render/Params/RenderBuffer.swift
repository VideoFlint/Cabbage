//
//  RenderBuffer.swift
//  Cabbage
//
//  Created by Vito on 2022/5/2.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation

public class RenderBuffer {
    public private(set) var bytes: UnsafeRawPointer
    public private(set) var length: Int
    
    /// Index in shader
    public var index: Int = 0
    
    public var label: String?
    
    public init(bytes: UnsafeRawPointer, length: Int) {
        self.bytes = bytes
        self.length = length
    }
    
    public func update(bytes: UnsafeRawPointer, length: Int) {
        self.bytes = bytes
        self.length = length
    }
    
}

public extension RenderBuffer {
    static let standardImageVerticesBuffer: RenderBuffer = {
        let vertices = [
            -1.0, 1.0,
             1.0, 1.0,
             -1.0, -1.0,
             1.0, -1.0]
        return RenderBuffer(bytes: vertices,
                            length: MemoryLayout<Float>.size * vertices.count)
    }()
    
    static let standardTextureCoordinateBuffer: RenderBuffer = {
      let vertices = [
        0.0, 0.0,
        1.0, 0.0,
        0.0, 1.0,
        1.0, 1.0]
        return RenderBuffer(bytes: vertices,
                            length: MemoryLayout<Float>.size * vertices.count)
    }()
}
