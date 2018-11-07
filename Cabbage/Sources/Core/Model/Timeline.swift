//
//  Timeline.swift
//  Cabbage
//
//  Created by Vito on 22/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

public class Timeline {
    
    public init() {}

    // MARK: - Main content, support transition.
    
    /*
     videoChannel and audioChannel support transition, but you are responsible for update provider's time range.
     The transition is only valid when there is an intersection of the time ranges of the two providers.
     Usually, you may call reloadVideoStartTime(providers:) after you update videoChannel, call reloadAudioStartTime(providers:) after you update audioChannel, these two methods will update provider's timeRange based on provider's time range and transition duration.
     */
    public var videoChannel: [TransitionableVideoProvider] = []
    public var audioChannel: [TransitionableAudioProvider] = []
    
    // MARK: - Other content, can place anywhere in timeline
    public var overlays: [VideoProvider] = []
    public var audios: [AudioProvider] = []
    
    // MARK: - Global effect
    public var passingThroughVideoCompositionProvider: VideoCompositionProvider?
    
}

extension Timeline {
    
    public static func reloadVideoStartTime(providers: [TransitionableVideoProvider]) {
        self.reloadStartTime(providers: providers) { (index) -> CMTime? in
            return providers[index].videoTransition?.duration
        }
    }
    
    public static func reloadAudioStartTime(providers: [TransitionableAudioProvider]) {
        self.reloadStartTime(providers: providers) { (index) -> CMTime? in
            return providers[index].audioTransition?.duration
        }
    }
    
    private static func reloadStartTime(providers: [CompositionTimeRangeProvider], transitionTime: (Int) -> CMTime?) {
        var position = CMTime.zero
        var previousTransitionDuration = CMTime.zero
        for index in 0..<providers.count {
            let provider = providers[index]
            
            // Precedence: the previous transition has priority. If clip doesn't have enough time to have begin transition and end transition, then begin transition will be considered first.
            var transitionDuration: CMTime = {
                if let duration = transitionTime(index) {
                    return duration
                }
                return CMTime.zero
            }()
            let providerDuration = provider.timeRange.duration
            if providerDuration < transitionDuration {
                transitionDuration = CMTime.zero
            } else {
                if index < providers.count - 1 {
                    let nextProvider = providers[index + 1]
                    if nextProvider.timeRange.duration < transitionDuration {
                        transitionDuration = CMTime.zero
                    }
                } else {
                    transitionDuration = CMTime.zero
                }
            }
            
            position = position - previousTransitionDuration
            
            provider.timeRange.start = position
            
            previousTransitionDuration = transitionDuration
            position = position + providerDuration
        }
    }
    
}
