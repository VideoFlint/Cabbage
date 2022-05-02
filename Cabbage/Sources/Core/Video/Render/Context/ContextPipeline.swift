//
//  ContextPipeline.swift
//  Cabbage
//
//  Created by Vito on 2022/4/26.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import Metal

public class ContextPipeline {
    public private(set) var device: MTLDevice
    public private(set) var library: ContextLibrary
    private var pipelineCache: [String: PipelineInfo] = [:]
    
    public init(device: MTLDevice, library: ContextLibrary) {
        self.device = device
        self.library = library
    }
    
    public func generatePipeline(vertexName: String, fragmentName: String) throws -> PipelineInfo {
        let key = self.generateKey(vertexName: vertexName, fragmentName: fragmentName)
        if let cachedPipelineInfo = self.pipelineCache[key] {
            return cachedPipelineInfo
        }
        guard let vertexFunction = self.library.functionWithName(vertexName) else {
            throw NSError(domain: ErrorDomain.render.rawValue,
                          code: ErrorCode.common.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Create vertexFunction: " + vertexName + " failed"])
        }
        guard let fragmentFunction = self.library.functionWithName(fragmentName) else {
            throw NSError(domain: ErrorDomain.render.rawValue,
                          code: ErrorCode.common.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: "Create fragmentFunction: " + vertexName + " failed"])
        }
        return try self.generatePipeline(vertexFunction: vertexFunction, fragmentFunction: fragmentFunction)
    }
    
    public func generatePipeline(vertexFunction: MTLFunction, fragmentFunction: MTLFunction) throws -> PipelineInfo {
        let key = self.generateKey(vertexName: vertexFunction.name, fragmentName: fragmentFunction.name)
        if let cachedPipelineInfo = self.pipelineCache[key] {
            return cachedPipelineInfo
        }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        var reflection: MTLRenderPipelineReflection? = nil
        let pipelineState = try self.device.makeRenderPipelineState(descriptor: descriptor,
                                                                    options: [.argumentInfo, .bufferTypeInfo],
                                                                    reflection: &reflection)
        
        let pipelineInfo = PipelineInfo(pipelineState: pipelineState, reflection: reflection!)
        self.pipelineCache[key] = pipelineInfo
        return pipelineInfo
    }
    
    private func generateKey(vertexName: String, fragmentName: String) -> String {
        return vertexName + "-" + fragmentName
    }
    
    public func cleanCache() {
        self.pipelineCache.removeAll()
    }
    
}
