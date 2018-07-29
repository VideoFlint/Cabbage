//
//  Timeline.swift
//  Cabbage
//
//  Created by Vito on 22/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

public class Timeline {

    public init() {
    }
    // MARK: - Global effect
    public var passingThroughVideoCompositionProvider: PassingThroughVideoCompositionProvider?
    
    // MARK: - Main content, support transition.
    public var videoChannel: [TransitionableVideoProvider] = []
    public var audioChannel: [TransitionableAudioProvider] = []
    
    // MARK: - Other content, can place anywhere in timeline
    public var overlays: [VideoProvider] = []
    public var audios: [AudioProvider] = []
    
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
        var position = kCMTimeZero
        var previousTransitionDuration = kCMTimeZero
        for index in 0..<providers.count {
            var provider = providers[index]
            
            // Precedence: the previous transition has priority. If clip doesn't have enough time to have begin transition and end transition, then begin transition will be considered first.
            var transitionDuration: CMTime = {
                if let duration = transitionTime(index) {
                    return duration
                }
                return kCMTimeZero
            }()
            let providerDuration = provider.timeRange.duration
            if providerDuration < transitionDuration {
                transitionDuration = kCMTimeZero
            } else {
                if index < providers.count - 1 {
                    let nextProvider = providers[index + 1]
                    if nextProvider.timeRange.duration < transitionDuration {
                        transitionDuration = kCMTimeZero
                    }
                } else {
                    transitionDuration = kCMTimeZero
                }
            }
            
            position = position - previousTransitionDuration
            
            provider.timeRange.start = position
            
            previousTransitionDuration = transitionDuration
            position = position + providerDuration
        }
    }
    
}
