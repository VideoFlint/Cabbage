//
//  Transition.swift
//  Cabbage
//
//  Created by Vito on 2022/4/17.
//  Copyright © 2022 Vito. All rights reserved.
//

import CoreMedia

public class AudioTransition {
    public var duration: CMTime
    public var audioTransitionEffect: AudioTransitionEffect
    public init(duration: CMTime, audioTransitionEffect: AudioTransitionEffect) {
        self.duration = duration
        self.audioTransitionEffect = audioTransitionEffect
    }
}

public class VideoTransition {
    public var duration: CMTime
    public var videoTransitionEffect: VideoTransitionEffect
    public init(duration: CMTime, videoTransitionEffect: VideoTransitionEffect) {
        self.duration = duration
        self.videoTransitionEffect = videoTransitionEffect
    }
}

public class Transition {
    public var duration: CMTime
    public var videoTransitionEffect: VideoTransitionEffect = PassthroughVideoTransitionEffect()
    public var audioTransitionEffect: AudioTransitionEffect = PassthroughAudioTransitionEffect()
    
    public init(duration: CMTime) {
        self.duration = duration
    }
}

extension Transition {
    var videoTransition: VideoTransition {
        return VideoTransition(duration: duration, videoTransitionEffect: videoTransitionEffect)
    }
    
    var audioTransition: AudioTransition {
        return AudioTransition(duration: duration, audioTransitionEffect: audioTransitionEffect)
    }
}
