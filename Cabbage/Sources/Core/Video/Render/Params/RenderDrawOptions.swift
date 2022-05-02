//
//  RenderDrawOptions.swift
//  Cabbage
//
//  Created by Vito on 2022/5/2.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import Metal

public class RenderDrawOptions {
    
    public var primitiveType: MTLPrimitiveType = MTLPrimitiveType.triangleStrip
    public var vertexStart: Int = 0
    public var vertexCount: Int = 4
    public var imageVertices: RenderBuffer
    
    public init(imageVertices: RenderBuffer) {
        self.imageVertices = imageVertices
    }
    
}
