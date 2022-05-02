//
//  ShaderUniformSettings.swift
//  Cabbage
//
//  Created by Vito on 2022/5/2.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import Metal

public class ShaderUniformSettings {
    
    public private(set) var uniformSettingsKey: String
    public private(set) var arguments: [MTLArgument]
    public private(set) var renderBuffer: RenderBuffer?
    
    private var argument: MTLArgument?
    private var uniformBytes: UnsafeMutableRawPointer?
    private var uniformInfo: [String: Any] = [:]
    
    deinit {
        if let uniformBytes = uniformBytes {
            uniformBytes.deallocate()
        }
    }
    
    public init(arguments: [MTLArgument], uniformSettingsKey: String = "uniform") {
        self.arguments = arguments
        self.uniformSettingsKey = uniformSettingsKey
    }
    
    private func updateUniformLookupTable(arguments: [MTLArgument]) {
        for argument in arguments {
            if argument.type == MTLArgumentType.buffer &&
                argument.bufferDataType == MTLDataType.struct &&
                argument.name == self.uniformSettingsKey {
                self.argument = argument
                self.uniformBytes = calloc(argument.bufferDataSize / argument.bufferAlignment, argument.bufferDataSize)
                if let members = argument.bufferStructType?.members {
                    for member in members {
                        self.uniformInfo[member.name] = "Unset"
                    }
                }
                break
            }
        }
    }
    
    public func set<T>(_ value: T, key: String) {
        guard let uniformBytes = uniformBytes else {
            // Can't set, if we didn't find the key in shader
            return
        }
        
        guard let member = self.argument?.bufferStructType?.memberByName(key) else {
            return
        }
        
        uniformBytes.storeBytes(of: value, toByteOffset: member.offset, as: T.self)
        self.uniformInfo[member.name] = "{offset: \(member.offset), length: \(MemoryLayout<T>.size)}"
        self.updateRenderBuffer()
    }
    
    private func updateRenderBuffer() {
        guard let uniformBytes = uniformBytes, let argument = self.argument else {
            return
        }

        self.renderBuffer = RenderBuffer(bytes: uniformBytes, length: argument.bufferDataSize)
        self.renderBuffer?.index = argument.index
    }
    
}
