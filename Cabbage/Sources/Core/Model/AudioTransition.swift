//
//  AudioTransition.swift
//  Cabbage
//
//  Created by Vito on 2018/7/3.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

public protocol AudioTransition {
    var identifier: String { get }
    var duration: CMTime { get }
    
    /// Configure AVMutableAudioMixInputParameters for audio that is about to disappear
    ///
    /// - Parameters:
    ///   - audioMixInputParameters: The parameters for inputs to the mix
    ///   - timeRange: The source track's time range
    func applyPreviousAudioMixInputParameters(_ audioMixInputParameters: AVMutableAudioMixInputParameters, timeRange: CMTimeRange)
    
    /// Configure AVMutableAudioMixInputParameters for upcoming audio
    ///
    /// - Parameters:
    ///   - audioMixInputParameters: The parameters for inputs to the mix
    ///   - timeRange: The source track's time range
    func applyNextAudioMixInputParameters(_ audioMixInputParameters: AVMutableAudioMixInputParameters, timeRange: CMTimeRange)
}

public class FadeInOutAudioTransition: AudioTransition {
    
    public var identifier: String {
        return String(describing: self)
    }
    
    open var duration: CMTime
    
    public init(duration: CMTime = CMTime.zero) {
        self.duration = duration
    }
    
    public func applyPreviousAudioMixInputParameters(_ audioMixInputParameters: AVMutableAudioMixInputParameters, timeRange: CMTimeRange) {
        let effectTimeRange = CMTimeRange.init(start: timeRange.end - duration, end: timeRange.end)
        let node = VolumeAudioConfiguration.init(timeRange: effectTimeRange, startVolume: 1, endVolume: 0)
        node.timingFunction = { (percent: Double) -> Double in
            return Double(TimingFunctionFactory.quarticEaseOut(p: Float(percent)))
        }
        audioMixInputParameters.appendAudioProcessNode(node)
    }
    
    public func applyNextAudioMixInputParameters(_ audioMixInputParameters: AVMutableAudioMixInputParameters, timeRange: CMTimeRange) {
        let effectTimeRange = CMTimeRange(start: timeRange.start, end: timeRange.start + duration)
        let node = VolumeAudioConfiguration.init(timeRange: effectTimeRange, startVolume: 0, endVolume: 1)
        node.timingFunction = { (percent: Double) -> Double in
            return Double(TimingFunctionFactory.quarticEaseIn(p: Float(percent)))
        }
        audioMixInputParameters.appendAudioProcessNode(node)
    }
    
}
