//
//  RenderContext.swift
//  Cabbage
//
//  Created by Vito on 2022/4/24.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import CoreMedia
import CoreImage

class RenderContext {
    
    static let shared = RenderContext()
    
    public private(set) var device: MTLDevice
    public private(set) var textureCache: TextureCache
    public private(set) lazy var ciContext = CIContext(mtlDevice: self.device)
    
    public init(device: MTLDevice) {
        self.device = device
        self.textureCache = TextureCache(device: self.device)
    }
    
    
    
}
