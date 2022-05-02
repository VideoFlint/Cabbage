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

public protocol RenderContextDeviceUpdater {
    func ciContextWithDevice(_ device: MTLDevice) -> CIContext
    func textureCacheWithDevice(_ device: MTLDevice) -> TextureCache
}

public class RenderContext {
    
    static var shared: RenderContext? = {
        if let device = MTLCreateSystemDefaultDevice() {
            return RenderContext(device: device)
        }
        return nil
    }()
    
    public private(set) var device: MTLDevice
    public private(set) var textureCache: TextureCache
    public private(set) var ciContext: CIContext
    private var commandQueue: MTLCommandQueue?
    
    public private(set) var library: ContextLibrary
    public private(set) var pipeline: ContextPipeline
    
    public init(device: MTLDevice, updater: RenderContextDeviceUpdater? = nil) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.library = ContextLibrary(device: device)
        self.pipeline = ContextPipeline(device: device, library: self.library)
        
        if let updater = updater {
            self.textureCache = updater.textureCacheWithDevice(device)
            self.ciContext = updater.ciContextWithDevice(device)
        } else {
            self.textureCache = TextureCache(device: self.device)
            self.ciContext = {
                var options: [CIContextOption : Any] = [CIContextOption.workingColorSpace: NSNull(),
                                                        CIContextOption.outputColorSpace: NSNull()]
                if #available(iOS 10.0, *) {
                    options[CIContextOption.cacheIntermediates] = false
                }
                let context = CIContext(mtlDevice: device, options: options)
                return context
            }()
        }
    }
    
    // MARK: - Render
    
    public func render(_ params: RenderParams) {
        guard let renderOptions = params.renderOptions else {
            return
        }
        self.submitCommandBuffer(renderOptions: renderOptions) { commandBuffer in
            let descriptor = MTLRenderPassDescriptor()
            descriptor.colorAttachments[0].texture = params.outputImage?.texture
            descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0)
            descriptor.colorAttachments[0].storeAction = MTLStoreAction.store
            descriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
            if let configuration = params.renderPassDescriptorConfiguration {
                configuration(descriptor)
            }
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
            }
            encoder.setFrontFacing(MTLWinding.clockwise)
            if let configuration = params.renderEncoderConfiguration {
                configuration(encoder)
            }
            if let pipelineState = params.pipelineState {
                encoder.setRenderPipelineState(pipelineState)
                
                // Vertex Texture
                if let textures = params.vertexTextures {
                    for texture in textures {
                        encoder.setVertexTexture(texture.texture, index: texture.index)
                    }
                }
                
                // Fragment Texture
                if let textures = params.fragmentTextures {
                    for texture in textures {
                        encoder.setFragmentTexture(texture.texture, index: texture.index)
                    }
                }
                
                // Vertex Buffers
                if let buffers = params.vertexBuffers {
                    for buffer in buffers {
                        encoder.setVertexBytes(buffer.bytes,
                                               length: buffer.length,
                                               index: buffer.index)
                    }
                }
                
                // Fragment Buffers
                if let buffers = params.fragmentBuffers {
                    for buffer in buffers {
                        encoder.setFragmentBytes(buffer.bytes,
                                                 length: buffer.length,
                                                 index: buffer.index)
                    }
                }
                
                // Primitives
                if let drawOption = params.drawOptions {
                    encoder.setVertexBytes(drawOption.imageVertices.bytes,
                                           length: drawOption.imageVertices.length,
                                           index: drawOption.imageVertices.index)
                    
                    encoder.drawPrimitives(type: drawOption.primitiveType,
                                           vertexStart: drawOption.vertexStart,
                                           vertexCount: drawOption.vertexCount)
                }
            }
            
            encoder.endEncoding()
        }
    }
    
    public func render(_ params: RenderMPSImageKernamParam) {
        self.submitCommandBuffer(renderOptions: params.renderOptions) { commandBuffer in
            params.unaryImageKernal.encode(commandBuffer: commandBuffer,
                                           sourceTexture: params.inputTexture,
                                           destinationTexture: params.outputTexture)
        }
    }
    
    private func submitCommandBuffer(renderOptions: RenderOptions, encoderGenerator:(MTLCommandBuffer) -> Void) {
        var commandQueue = renderOptions.commandQueue
        if commandQueue == nil {
            commandQueue = self.commandQueue
        }
        guard let commandQueue = commandQueue else {
            Log.error("RenderContext no commandQueue")
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            Log.error("RenderContext create commandBuffer failed")
            return
        }
        
        encoderGenerator(commandBuffer)
        
        if let commandBufferConfiguration = renderOptions.commandBufferConfiguration {
            commandBufferConfiguration(commandBuffer)
        }
        
        commandBuffer.commit()
        
        if renderOptions.waitUntilCompleted {
            commandBuffer.waitUntilCompleted()
        }
    }
    
    // MARK: - Copy
    
    public func copy(from sourceTexture: MTLTexture, to targetTexture: MTLTexture) {
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            return
        }
        guard let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder() else {
            return
        }
        
        blitCommandEncoder.copy(from: sourceTexture,
                                sourceSlice: 0,
                                sourceLevel: 0,
                                sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                                sourceSize: MTLSizeMake(sourceTexture.width, sourceTexture.height, 1),
                                to: targetTexture,
                                destinationSlice: 0,
                                destinationLevel: 0,
                                destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blitCommandEncoder.endEncoding()
        commandBuffer.commit()
    }
    
}
