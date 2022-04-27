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
