//
//  ContextLibrary.swift
//  Cabbage
//
//  Created by Vito on 2022/4/25.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import Metal

public class ContextLibrary {
    
    private(set) var device: MTLDevice
    private var libraryCache: [String: MTLLibrary] = [:]
    
    public var libraries: [MTLLibrary] {
        get {
            return Array(self.libraryCache.values)
        }
    }
    
    init(device: MTLDevice) {
        self.device = device
        self.registerDefaultLibrary()
    }
    
    public func registerLibrary(_ filePath: String) throws {
        if !FileManager.default.fileExists(atPath: filePath) {
            let error = NSError(domain: "com.cabbage.render",
                                code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "Metal library is not exist at path: " + filePath])
            throw error
        }
        
        if self.libraryCache[filePath] != nil {
            return
        }
        
        let library = try self.device.makeLibrary(filepath: filePath)
        library.label = filePath
        self.libraryCache[filePath] = library
    }
    
    public func unregisterLibrary(_ filePath: String) {
        self.libraryCache.removeValue(forKey: filePath)
    }
    
    public func functionWithName(_ name: String) -> MTLFunction? {
        var function: MTLFunction? = nil
        for library in self.libraryCache.values {
            if let f = library.makeFunction(name: name) {
                function = f
                break
            }
        }
        return function
    }
    
    // MARK: - Helper
    
    private func registerDefaultLibrary() {
        let bundle = Bundle.main
        guard let libraryPath = bundle.path(forResource: "cabbage", ofType: "metallib") else {
            return
        }
        do {
            try self.registerLibrary(libraryPath)
        } catch (let e) {
            Log.error("register default metal libarary failed: " + e.localizedDescription)
            assert(false, "register default metal libarary failed: " + e.localizedDescription)
        }
    }
    
}
