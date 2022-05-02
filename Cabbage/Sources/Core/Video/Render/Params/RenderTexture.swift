//
//  RenderTexture.swift
//  Cabbage
//
//  Created by Vito on 2022/5/2.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import Metal

public class RenderTexture {
    public var texture: MTLTexture
    
    /// Index in shader
    public var index: Int = 0
    
    public init(_ texture: MTLTexture) {
        self.texture = texture
    }
}
