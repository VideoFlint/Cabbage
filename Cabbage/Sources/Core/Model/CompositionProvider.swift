//
//  CompositionProvider.swift
//  Cabbage
//
//  Created by Vito on 2018/6/23.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreImage
import AVFoundation

public protocol CompositionTimeRangeProvider: class {
    var timeRange: CMTimeRange { get set }
}

public protocol VideoCompositionTrackProvider: CompositionTimeRangeProvider {
    func numberOfVideoTracks() -> Int
    func videoCompositionTrack(for composition: AVMutableComposition, at index: Int, preferredTrackID: Int32) -> AVCompositionTrack?
}

public protocol AudioCompositionTrackProvider: CompositionTimeRangeProvider {
    func numberOfAudioTracks() -> Int
    func audioCompositionTrack(for composition: AVMutableComposition, at index: Int, preferredTrackID: Int32) -> AVCompositionTrack?
}

public protocol AudioMixProvider {
    func configure(audioMixParameters: AVMutableAudioMixInputParameters)
}

public protocol VideoCompositionProvider: class {
    
    /// Apply effect to sourceImage
    ///
    /// - Parameters:
    ///   - sourceImage: sourceImage is the original image from resource
    ///   - time: time in timeline
    ///   - renderSize: the video canvas size
    /// - Returns: result image after apply effect
    func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage
    
}

public protocol VideoProvider: VideoCompositionTrackProvider, VideoCompositionProvider {}
public protocol AudioProvider: AudioCompositionTrackProvider, AudioMixProvider { }

public protocol TransitionableVideoProvider: VideoProvider {
    var videoTransition: VideoTransition? { get }
}
public protocol TransitionableAudioProvider: AudioProvider {
    var audioTransition: AudioTransition? { get }
}
