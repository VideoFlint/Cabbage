//
//  RenderParams.swift
//  Cabbage
//
//  Created by Vito on 2022/5/2.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import Metal

private let AttributeOutputImage = "Attribute_OutputImage"
private let AttributeRenderOptions = "Attribute_RenderOptions"
private let AttributeRenderPassDescriptiorConfiguration = "Attribute_RenderPassDescriptiorConfiguration"
private let AttributeRenderEncoderConfiguration = "Attribute_RenderEncoderConfiguration"

private let AttributePipelineState = "Attribute_PipelineState"
private let AttributeVertexTextures = "Attribute_VertexTextures"
private let AttributeFragmentTextures = "Attribute_FragmentTextures"
private let AttributeVertexBuffers = "Attribute_VertexBuffers"
private let AttributeFragmentBuffers = "Attribute_FragmentBuffers"
private let AttributeDrawOptions = "Attribute_DrawOptions"

private let AttributeInputTextures = "Attribute_InputTextures"


public typealias RenderPassDescriptorConfiguration = (MTLRenderPassDescriptor) -> Void
public typealias RenderEncoderConfiguration = (MTLRenderCommandEncoder) -> Void

public class RenderParams {
    
    private var inputDic: [String: Any] = [:]
    
    public func setInputValue(_ value: Any?, for key: String) {
        if let value = value {
            self.inputDic[key] = value
        } else {
            self.inputDic.removeValue(forKey: key)
        }
    }
    
    public func inputValue(for key: String) -> Any? {
        return self.inputDic[key]
    }
}

// MARK: - Filters

public extension RenderParams {
    
    var outputImage: Image? {
        get {
            return self.inputDic[AttributeOutputImage] as? Image
        }
        set {
            self.inputDic[AttributeOutputImage] = newValue
        }
    }
    
    var renderOptions: RenderOptions? {
        get {
            return self.inputDic[AttributeRenderOptions] as? RenderOptions
        }
        set {
            self.inputDic[AttributeRenderOptions] = newValue
        }
    }
    
    /// Configure renderPassDescriptor for more advance usage, do not set the `colorAttachments[0].texture`, it wiil be set to `outputImage.texture`
    var renderPassDescriptorConfiguration: RenderPassDescriptorConfiguration? {
        get {
            return self.inputDic[AttributeRenderPassDescriptiorConfiguration] as? RenderPassDescriptorConfiguration
        }
        set {
            self.inputDic[AttributeRenderPassDescriptiorConfiguration] = newValue
        }
    }
    
    /// Configure renderEncoder for more advance usage
    var renderEncoderConfiguration: RenderEncoderConfiguration? {
        get {
            return self.inputDic[AttributeRenderEncoderConfiguration] as? RenderEncoderConfiguration
        }
        set {
            self.inputDic[AttributeRenderEncoderConfiguration] = newValue
        }
    }
    
    var inputTextures: [MTLTexture]? {
        get {
            return self.inputDic[AttributeInputTextures] as? [MTLTexture]
        }
        set {
            self.inputDic[AttributeInputTextures] = newValue
        }
    }
    
}

// MARK: - Render

public extension RenderParams {
    
    /// Pipeline info, include vertex shader, fragmen shader
    var pipelineState: MTLRenderPipelineState? {
        get {
            return self.inputDic[AttributePipelineState] as? MTLRenderPipelineState
        }
        set {
            self.inputDic[AttributePipelineState] = newValue
        }
    }
    
    /// Input vertex textures
    var vertexTextures: [RenderTexture]? {
        get {
            return self.inputDic[AttributeVertexTextures] as? [RenderTexture]
        }
        set {
            self.inputDic[AttributeVertexTextures] = newValue
        }
    }
    
    /// Input fragment textures
    var fragmentTextures: [RenderTexture]? {
        get {
            return self.inputDic[AttributeFragmentTextures] as? [RenderTexture]
        }
        set {
            self.inputDic[AttributeFragmentTextures] = newValue
        }
    }
    
    /// Vertex buffers, usually is uniform settings
    var vertexBuffers: [RenderBuffer]? {
        get {
            return self.inputDic[AttributeVertexBuffers] as? [RenderBuffer]
        }
        set {
            self.inputDic[AttributeVertexBuffers] = newValue
        }
    }
    
    /// Fragment buffers, usually is uniform settings
    var fragmentBuffers: [RenderBuffer]? {
        get {
            return self.inputDic[AttributeFragmentBuffers] as? [RenderBuffer]
        }
        set {
            self.inputDic[AttributeFragmentBuffers] = newValue
        }
    }
    
    var drawOptions: RenderDrawOptions? {
        get {
            return self.inputDic[AttributeDrawOptions] as? RenderDrawOptions
        }
        set {
            self.inputDic[AttributeDrawOptions] = newValue
        }
    }
    
}
