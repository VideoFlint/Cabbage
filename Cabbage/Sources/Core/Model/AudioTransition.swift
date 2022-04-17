//
//  AudioTransition.swift
//  Cabbage
//
//  Created by Vito on 2018/7/3.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation
import UIKit

public class AudioTransitionEffectParam {
    
    ///  The parameters for inputs to the mix
    var audioMixInputParameters: AVMutableAudioMixInputParameters
    /// The source track's time range
    var timeRange: CMTimeRange
    /// Transition duration
    var duration: CMTime
    
    /// Create a param for processing to the audio transition effect
    /// - Parameters:
    ///   - audioMixInputParameters: The parameters for inputs to the mix
    ///   - timeRange: The source track's time range
    ///   - duration: Transition duration
    public init(audioMixInputParameters: AVMutableAudioMixInputParameters, timeRange: CMTimeRange, duration: CMTime) {
        self.audioMixInputParameters = audioMixInputParameters
        self.timeRange = timeRange
        self.duration = duration
        
    }
}

public protocol AudioTransitionEffect {
    /// Configure AVMutableAudioMixInputParameters for audio that is about to disappear
    ///
    /// - Parameters:
    ///   - param: parameters for configure
    func applyPreviousAudioMixInputParametersWithParam(_ param: AudioTransitionEffectParam)
    
    /// Configure AVMutableAudioMixInputParameters for upcoming audio
    ///
    /// - Parameters:
    ///   - param: parameters for configure
    func applyNextAudioMixInputParametersWithParam(_ param: AudioTransitionEffectParam)
}


public class PassthroughAudioTransitionEffect: AudioTransitionEffect {
    public func applyPreviousAudioMixInputParametersWithParam(_ param: AudioTransitionEffectParam) {
    }
    
    public func applyNextAudioMixInputParametersWithParam(_ param: AudioTransitionEffectParam) {
    }
}

public class FadeInOutAudioTransitionEffect: AudioTransitionEffect {
    public func applyPreviousAudioMixInputParametersWithParam(_ param: AudioTransitionEffectParam) {
        let effectTimeRange = CMTimeRange.init(start: param.timeRange.end - param.duration, end: param.timeRange.end)
        let node = VolumeAudioConfiguration.init(timeRange: effectTimeRange, startVolume: 1, endVolume: 0)
        node.timingFunction = { (percent: Double) -> Double in
            return Double(TimingFunctionFactory.quarticEaseOut(p: Float(percent)))
        }
        param.audioMixInputParameters.appendAudioProcessNode(node)
    }
    
    public func applyNextAudioMixInputParametersWithParam(_ param: AudioTransitionEffectParam) {
        let effectTimeRange = CMTimeRange(start: param.timeRange.start, end: param.timeRange.start + param.duration)
        let node = VolumeAudioConfiguration.init(timeRange: effectTimeRange, startVolume: 0, endVolume: 1)
        node.timingFunction = { (percent: Double) -> Double in
            return Double(TimingFunctionFactory.quarticEaseIn(p: Float(percent)))
        }
        param.audioMixInputParameters.appendAudioProcessNode(node)
    }
}
