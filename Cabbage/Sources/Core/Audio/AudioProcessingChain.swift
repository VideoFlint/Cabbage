//
//  AudioProcessingChain.swift
//  Cabbage
//
//  Created by Vito on 2018/6/30.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

public protocol AudioProcessingNode: class {
    func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>)
}

public class VolumeAudioProcessingNode: NSObject, NSCopying, AudioProcessingNode {
    
    public var timeRange: CMTimeRange
    public var startVolume: Float
    public var endVolume: Float
    public var timingFunction: ((Double) -> Double)?
    public required init(timeRange: CMTimeRange, startVolume: Float, endVolume: Float) {
        self.timeRange = timeRange
        self.startVolume = startVolume
        self.endVolume = endVolume
        super.init()
    }
    
    public func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>) {
        if timeRange.duration.isValid {
            if self.timeRange.intersection(timeRange).duration.seconds > 0 {
                var percent = (timeRange.end.seconds - self.timeRange.start.seconds) / self.timeRange.duration.seconds
                if let timingFunction = timingFunction {
                    percent = timingFunction(percent)
                }
                let volume = startVolume + (endVolume - startVolume) * Float(percent)
                AudioMixer.changeVolume(for: bufferListInOut, volume: volume)
            }
        }
    }
    
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let node = type(of: self).init(timeRange: timeRange, startVolume: startVolume, endVolume: endVolume)
        node.timingFunction = timingFunction
        return node
    }
    
}

public class AudioProcessingChain: NSObject, NSCopying {
    var nodes: [AudioProcessingNode] = []
    
    func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>) {
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
