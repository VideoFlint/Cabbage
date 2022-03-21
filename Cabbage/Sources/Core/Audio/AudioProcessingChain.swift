//
//  AudioProcessingChain.swift
//  Cabbage
//
//  Created by Vito on 2018/6/30.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

public protocol AudioProcessingNode: AnyObject {
    func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>)
}

public class AudioProcessingChain: NSObject, NSCopying {
    public var nodes: [AudioProcessingNode] = []
    
    public func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>) {
        nodes.forEach { (node) in
            node.process(timeRange: timeRange, bufferListInOut: bufferListInOut)
        }
    }
    
    // MARK: - NSCopying
    public required override init() {
        super.init()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let chain = type(of: self).init()
        chain.nodes = nodes
        return chain
    }
}
