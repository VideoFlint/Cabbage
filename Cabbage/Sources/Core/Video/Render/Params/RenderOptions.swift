//
//  RenderOptions.swift
//  Cabbage
//
//  Created by Vito on 2022/5/2.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import Metal

public typealias CommandBufferConfiguration = (MTLCommandBuffer) -> Void

public class RenderOptions {
    
    /// The command queue of rendering command, if the command queue is not set, will use the default command queue.
    public var commandQueue: MTLCommandQueue?
    
    /// Blocks execution of the current thread until execution of the command buffer is completed. Default is false
    public var waitUntilCompleted: Bool = false
    
    public var commandBufferConfiguration: CommandBufferConfiguration? = nil
    
}
