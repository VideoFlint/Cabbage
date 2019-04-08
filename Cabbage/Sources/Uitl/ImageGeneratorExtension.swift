//
//  ImageGeneratorExtension.swift
//  Cabbage
//
//  Created by Vito on 2018/7/23.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation
import UIKit

public extension AVAssetImageGenerator {
    
    static func create(from items: [TrackItem], renderSize: CGSize) -> AVAssetImageGenerator? {
        let timeline = Timeline()
        timeline.videoChannel = items
        timeline.renderSize = renderSize;
        let generator = CompositionGenerator(timeline: timeline)
        let imageGenerator = generator.buildImageGenerator()
        
        return imageGenerator
    }
    
    static func create(fromAsset asset: AVAsset) -> AVAssetImageGenerator {
        let ge = AVAssetImageGenerator(asset: asset)
        ge.requestedTimeToleranceBefore = CMTime.zero
        ge.requestedTimeToleranceAfter = CMTime.zero
        ge.appliesPreferredTrackTransform = true
        return ge
    }
    
    func updateAspectFitSize(_ size: CGSize) {
        var maximumSize = size
        if !maximumSize.equalTo(.zero) {
            let tracks = asset.tracks(withMediaType: .video)
            if tracks.count > 0 {
                let videoTrack = tracks[0]
                let width = videoTrack.naturalSize.width
                let height = videoTrack.naturalSize.height
                var side: CGFloat
                if width > height {
                    side = maximumSize.width / height * width
                } else {
                    side = maximumSize.width / width * height
                }
                side = side * UIScreen.main.scale
                maximumSize = CGSize(width: side, height: side)
            }
        }
        
        self.maximumSize = maximumSize
    }
    
    func makeCopy() -> AVAssetImageGenerator {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = appliesPreferredTrackTransform
        generator.maximumSize = maximumSize
        generator.apertureMode = apertureMode
        generator.videoComposition = videoComposition
        generator.requestedTimeToleranceBefore = requestedTimeToleranceBefore
        generator.requestedTimeToleranceAfter = requestedTimeToleranceAfter
        return generator
    }
    
}
