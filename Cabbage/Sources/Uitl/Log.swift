//
//  Log.swift
//  Cabbage
//
//  Created by Vito on 2018/6/24.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation
import os

private let subsystem = "com.vito.cabbage"

public class Log {
    
    public struct Output: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let info = Output(rawValue: 1 << 0)
        public static let debug = Output(rawValue: 1 << 1)
        public static let warning = Output(rawValue: 1 << 2)
        public static let error = Output(rawValue: 1 << 3)
        
        public static let all: Output = [.info, .debug, .warning, .error]
    }
    
    public static var output: Output = [.debug, .warning, .error]
    
    @available(iOS 10.0, *)
    static let infoLog = OSLog(subsystem: subsystem, category: "INFO")
    public static func info(_ string: String) {
        #if DEBUG
        if output.contains(.info) {
            if #available(iOS 10.0, *) {
                os_log("%@", log: infoLog, type: .info, string)
            } else {
                print("<INFO>: %@", string)
            }
        }
        #endif
    }
    
    @available(iOS 10.0, *)
    static let debugLog = OSLog(subsystem: subsystem, category: "DEBUG")
    public static func debug(_ string: String) {
        #if DEBUG
        if output.contains(.debug) {
            if #available(iOS 10.0, *) {
                os_log("%@", log: debugLog, type: .debug, string)
            } else {
                print("<DEBUG>: %@", string)
            }
        }
        #endif
    }
    
    @available(iOS 10.0, *)
    static let warningLog = OSLog(subsystem: subsystem, category: "WARNING")
    public static func warning(_ string: String) {
        if output.contains(.warning) {
            if #available(iOS 10.0, *) {
                os_log("%@", log: warningLog, type: .fault, string)
            } else {
                print("<WARNING>: %@", string)
            }
        }
    }
    
    @available(iOS 10.0, *)
    static let errorLog = OSLog(subsystem: subsystem, category: "ERROR")
    public static func error(_ string: String) {
        if output.contains(.error) {
            if #available(iOS 10.0, *) {
                os_log("%@", log: errorLog, type: .error, string)
            } else {
                print("<ERROR>: %@", string)
            }
        }
    }
}
