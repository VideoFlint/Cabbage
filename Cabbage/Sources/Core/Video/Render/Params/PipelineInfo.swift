//
//  PipelineInfo.swift
//  Cabbage
//
//  Created by Vito on 2022/5/2.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import Metal

public class PipelineInfo {
    
    public private(set) var pipelineState: MTLRenderPipelineState
    public private(set) var reflection: MTLRenderPipelineReflection
    
    init(pipelineState: MTLRenderPipelineState, reflection: MTLRenderPipelineReflection) {
        self.pipelineState = pipelineState
        self.reflection = reflection
    }
    
}
