//
//  RenderMPSImageKernalParam.swift
//  Cabbage
//
//  Created by Vito on 2022/5/2.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders

public class RenderMPSImageKernamParam {
    public var outputTexture: MTLTexture
    public var inputTexture: MTLTexture
    public var unaryImageKernal: MPSUnaryImageKernel
    
    public var renderOptions = RenderOptions()
    
    init(outputTexture: MTLTexture, inputTexture: MTLTexture, unaryImageKernal: MPSUnaryImageKernel) {
        self.outputTexture = outputTexture
        self.inputTexture = inputTexture
        self.unaryImageKernal = unaryImageKernal
    }
}
