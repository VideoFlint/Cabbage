//
//  CompositionGenerator.swift
//  Cabbage
//
//  Created by Vito on 13/02/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

public class CompositionGenerator {
    
    // MARK: - Public
    public var timeline: Timeline {
        didSet {
            needRebuildComposition = true
            needRebuildVideoComposition = true
            needRebuildAudioMix = true
        }
    }
    public var renderSize: CGSize? {
        didSet {
            needRebuildVideoComposition = true
        }
    }
    
    private var composition: AVComposition?
    private var videoComposition: AVVideoComposition?
    private var audioMix: AVAudioMix?
    
    private var needRebuildComposition: Bool = true
    private var needRebuildVideoComposition: Bool = true
    private var needRebuildAudioMix: Bool = true
    
    public init(timeline: Timeline) {
        self.timeline = timeline
    }
    
    public func buildPlayerItem() -> AVPlayerItem {
        let composition = buildComposition()
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = buildVideoComposition()
        playerItem.audioMix = buildAudioMix()
        return playerItem
    }
    
    public func buildImageGenerator() -> AVAssetImageGenerator {
        let composition = buildComposition()
        let imageGenerator = AVAssetImageGenerator(asset: composition)
        imageGenerator.videoComposition = buildVideoComposition()
        
        return imageGenerator
    }
    
    public func buildExportSession(presetName: String) -> AVAssetExportSession? {
        let composition = buildComposition()
        let exportSession = AVAssetExportSession.init(asset: composition, presetName: presetName)
        exportSession?.videoComposition = buildVideoComposition()
        exportSession?.audioMix = buildAudioMix()
        exportSession?.outputURL = {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
            let filename = ProcessInfo.processInfo.globallyUniqueString + ".mp4"
            return documentDirectory.appendingPathComponent(filename)
        }()
        exportSession?.outputFileType = AVFileType.mp4
        return exportSession
    }
    
    // MARK: - Build Composition
    
    public func buildComposition() -> AVComposition {
        if let composition = self.composition, !needRebuildComposition {
            return composition
        }
        
        resetSetupInfo()
        
        let composition = AVMutableComposition(urlAssetInitializationOptions: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        timeline.videoChannel.forEach({ (provider) in
            for index in 0..<provider.numberOfVideoTracks() {
                let trackID: Int32 = generateNextTrackID()
                if let compositionTrack = provider.videoCompositionTrack(for: composition, at: index, preferredTrackID: trackID) {
                    self.mainVideoTrackInfo[compositionTrack] = provider
                }
            }
        })
        
        var previousAudioTransition: AudioTransition?
        timeline.audioChannel.enumerated().forEach { (offset, provider) in
            for index in 0..<provider.numberOfAudioTracks() {
                let trackID: Int32 = generateNextTrackID()
                if let compositionTrack = provider.audioCompositionTrack(for: composition, at: index, preferredTrackID: trackID) {
                    self.mainAudioTrackInfo[compositionTrack] = provider
                    if offset == 0 {
                        if timeline.audioChannel.count > 1 {
                            audioTransitionInfo[compositionTrack] = (nil, provider.audioTransition)
                        }
                    } else if offset == timeline.audioChannel.count - 1 {
                        audioTransitionInfo[compositionTrack] = (previousAudioTransition, nil)
                    } else {
                        audioTransitionInfo[compositionTrack] = (previousAudioTransition, provider.audioTransition)
                    }
                }
            }
            previousAudioTransition = provider.audioTransition
        }
        
        timeline.overlays.forEach { (provider) in
            for index in 0..<provider.numberOfVideoTracks() {
                let trackID: Int32 = generateNextTrackID()
                if let compositionTrack = provider.videoCompositionTrack(for: composition, at: index, preferredTrackID: trackID) {
                    self.overlayTrackInfo[compositionTrack] = provider
                }
            }
        }
        
        timeline.audios.forEach { (provider) in
            for index in 0..<provider.numberOfAudioTracks() {
                let trackID: Int32 = generateNextTrackID()
                if let compositionTrack = provider.audioCompositionTrack(for: composition, at: index, preferredTrackID: trackID) {
                    self.audioTrackInfo[compositionTrack] = provider
                }
            }
        }
        
        return composition
    }
    
    public func buildVideoComposition() -> AVVideoComposition? {
        if let videoComposition = self.videoComposition, !needRebuildVideoComposition {
            return videoComposition
        }
        
        let composition = buildComposition()
        let videoTracks = composition.tracks(withMediaType: .video)
        
        var layerInstructions: [VideoCompositionLayerInstruction] = []
        videoTracks.forEach { (track) in
            if let provider = mainVideoTrackInfo[track] {
                let layerInstruction = VideoCompositionLayerInstruction.init(trackID: track.trackID, videoCompositionProvider: provider)
                layerInstruction.prefferdTransform = track.preferredTransform
                layerInstruction.timeRange = provider.timeRange
                layerInstruction.transition = provider.videoTransition
                layerInstructions.append(layerInstruction)
            } else if let provider = overlayTrackInfo[track] {
                // Other video overlay
                let layerInstruction = VideoCompositionLayerInstruction.init(trackID: track.trackID, videoCompositionProvider: provider)
                layerInstruction.prefferdTransform = track.preferredTransform
                layerInstruction.timeRange = provider.timeRange
                layerInstructions.append(layerInstruction)
            }
        }
        
        // Create multiple instructions，each instructions contains layerInstructions whose time range have insection with instruction，
        // When rendering the frame, the instruction can quickly find layerInstructions
        let layerInstructionsSlices = calculateSlices(for: layerInstructions)
        let mainTrackIDs = mainVideoTrackInfo.keys.map({ $0.trackID })
        let instructions: [VideoCompositionInstruction] = layerInstructionsSlices.map({ (slice) in
            let trackIDs = slice.1.map({ $0.trackID })
            let instruction = VideoCompositionInstruction(theSourceTrackIDs: trackIDs as [NSValue], forTimeRange: slice.0)
            instruction.layerInstructions = slice.1
            instruction.passingThroughVideoCompositionProvider = timeline.passingThroughVideoCompositionProvider
            instruction.mainTrackIDs = mainTrackIDs.filter({ trackIDs.contains($0) })
            return instruction
        })
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = {
            if let renderSize = renderSize {
                return renderSize
            }
            let size = videoTracks.reduce(CGSize.zero, { (size, track) -> CGSize in
                let trackSize = track.naturalSize.applying(track.preferredTransform)
                return CGSize(width: max(abs(trackSize.width), size.width),
                              height: max(abs(trackSize.height), size.height))
            })
            return size
        }()
        videoComposition.instructions = instructions
        videoComposition.customVideoCompositorClass = VideoCompositor.self
        
        return videoComposition
    }
    
    public func buildAudioMix() -> AVAudioMix? {
        if let audioMix = self.audioMix, !needRebuildAudioMix {
            return audioMix
        }
        
        let composition = buildComposition()
        var audioParameters = [AVMutableAudioMixInputParameters]()
        let audioTracks = composition.tracks(withMediaType: .audio)
        
        audioTracks.forEach { (track) in
            if let provider = mainAudioTrackInfo[track] {
                let inputParameter = AVMutableAudioMixInputParameters(track: track)
                provider.configure(audioMixParameters: inputParameter)
                let transitions = audioTransitionInfo[track]
                if let transition = transitions?.0 {
                    if let targetTimeRange = track.segments.first(where: { !$0.isEmpty })?.timeMapping.target {
                        transition.applyNextAudioMixInputParameters(inputParameter, timeRange: targetTimeRange)
                    }
                }
                if let transition = transitions?.1 {
                    if let targetTimeRange = track.segments.first(where: { !$0.isEmpty })?.timeMapping.target {
                        transition.applyPreviousAudioMixInputParameters(inputParameter, timeRange: targetTimeRange)
                    }
                }
                
                audioParameters.append(inputParameter)
            } else if let provider = audioTrackInfo[track] {
                let inputParameter = AVMutableAudioMixInputParameters(track: track)
                provider.configure(audioMixParameters: inputParameter)
                audioParameters.append(inputParameter)
            }
        }
        
        if audioParameters.count == 0 {
            return nil
        }
        
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = audioParameters
        return audioMix
    }
    
    // MARK: - Helper
    
    private var increasementTrackID: Int32 = 0
    private func generateNextTrackID() -> Int32 {
        let trackID = increasementTrackID + 1
        increasementTrackID = trackID
        return trackID
    }
    
    private var mainVideoTrackInfo: [AVCompositionTrack: TransitionableVideoProvider] = [:]
    private var mainAudioTrackInfo: [AVCompositionTrack: TransitionableAudioProvider] = [:]
    private var overlayTrackInfo: [AVCompositionTrack: VideoProvider] = [:]
    private var audioTrackInfo: [AVCompositionTrack: AudioProvider] = [:]
    private var audioTransitionInfo = [AVCompositionTrack: (AudioTransition?, AudioTransition?)]()
    
    private func resetSetupInfo() {
        increasementTrackID = 0
        mainVideoTrackInfo = [:]
        mainAudioTrackInfo = [:]
        overlayTrackInfo = [:]
        audioTrackInfo = [:]
        audioTransitionInfo = [:]
    }
    
    private func calculateSlices(for layerInstructions: [VideoCompositionLayerInstruction]) -> [(CMTimeRange, [VideoCompositionLayerInstruction])] {
        var layerInstructionsSlices: [(CMTimeRange, [VideoCompositionLayerInstruction])] = []
        layerInstructions.forEach { (layerInstruction) in
            var slices = layerInstructionsSlices
            
            var leftTimeRanges: [CMTimeRange] = [layerInstruction.timeRange]
            layerInstructionsSlices.enumerated().forEach({ (offset, slice) in
                let intersectionTimeRange = slice.0.intersection(layerInstruction.timeRange)
                if intersectionTimeRange.duration.seconds > 0 {
                    slices.remove(at: offset)
                    let sliceTimeRanges = CMTimeRange.sliceTimeRanges(for: layerInstruction.timeRange, timeRange2: slice.0)
                    sliceTimeRanges.forEach({ (timeRange) in
                        if slice.0.containsTimeRange(timeRange) && layerInstruction.timeRange.containsTimeRange(timeRange) {
                            let newSlice = (timeRange, slice.1 + [layerInstruction])
                            slices.append(newSlice)
                            leftTimeRanges = leftTimeRanges.flatMap({ (leftTimeRange) -> [CMTimeRange] in
                                return leftTimeRange.substruct(timeRange)
                            })
                        } else if slice.0.containsTimeRange(timeRange) {
                            let newSlice = (timeRange, slice.1)
                            slices.append(newSlice)
                        }
                    })
                }
            })
            
            leftTimeRanges.forEach({ (timeRange) in
                slices.append((timeRange, [layerInstruction]))
            })
            
            layerInstructionsSlices = slices
        }
        return layerInstructionsSlices
    }
}

// MARK: -

extension AVMutableAudioMixInputParameters {
    private static var audioProcessingTapHolderKey: UInt8 = 0
    var audioProcessingTapHolder: AudioProcessingTapHolder? {
        get {
            return objc_getAssociatedObject(self, &AVMutableAudioMixInputParameters.audioProcessingTapHolderKey) as? AudioProcessingTapHolder
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AVMutableAudioMixInputParameters.audioProcessingTapHolderKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            audioTapProcessor = newValue?.tap
        }
    }
    
    func appendAudioProcessNode(_ node: AudioProcessingNode) {
        if audioProcessingTapHolder == nil {
            audioProcessingTapHolder = AudioProcessingTapHolder()
        }
        audioProcessingTapHolder?.audioProcessingChain.nodes.append(node)
    }
}

