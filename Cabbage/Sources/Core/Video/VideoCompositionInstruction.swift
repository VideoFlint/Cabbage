//
//  VIVideoCompositionInstruction.swift
//  Cabbage
//
//  Created by Vito on 10/02/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation
import CoreImage

open class VideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    
    open var timeRange: CMTimeRange = CMTimeRange()
    open var enablePostProcessing: Bool = false
    open var containsTweening: Bool = false
    open var requiredSourceTrackIDs: [NSValue]?
    open var passthroughTrackID: CMPersistentTrackID = 0
    
    open var layerInstructions: [VideoCompositionLayerInstruction] = []
    open var mainTrackIDs: [Int32] = []
    public var passingThroughVideoCompositionProvider: VideoCompositionProvider?
    
    public var backgroundColor: CIColor = CIColor(red: 0, green: 0, blue: 0)
    
    public init(thePassthroughTrackID: CMPersistentTrackID, forTimeRange theTimeRange: CMTimeRange) {
        super.init()
        
        passthroughTrackID = thePassthroughTrackID
        timeRange = theTimeRange
        
        requiredSourceTrackIDs = [NSValue]()
        containsTweening = false
        enablePostProcessing = false
    }
    
    public init(theSourceTrackIDs: [NSValue], forTimeRange theTimeRange: CMTimeRange) {
        super.init()
        
        requiredSourceTrackIDs = theSourceTrackIDs
        timeRange = theTimeRange
        
        passthroughTrackID = kCMPersistentTrackID_Invalid
        containsTweening = true
        enablePostProcessing = false
    }
    
    open func apply(request: AVAsynchronousVideoCompositionRequest) -> CIImage? {
        let time = request.compositionTime
        let renderSize = request.renderContext.size
        
        var otherLayerInstructions: [VideoCompositionLayerInstruction] = []
        var mainLayerInstructions: [VideoCompositionLayerInstruction] = []
        
        for layerInstruction in layerInstructions {
            if mainTrackIDs.contains(layerInstruction.trackID) {
                mainLayerInstructions.append(layerInstruction)
            } else {
                otherLayerInstructions.append(layerInstruction)
            }
        }
        
        var image: CIImage?
        
        if mainLayerInstructions.count == 2 {
            let layerInstruction1: VideoCompositionLayerInstruction
            let layerInstruction2: VideoCompositionLayerInstruction
            if mainLayerInstructions[0].timeRange.end < mainLayerInstructions[1].timeRange.end {
                layerInstruction1 = mainLayerInstructions[0]
                layerInstruction2 = mainLayerInstructions[1]
            } else {
                layerInstruction1 = mainLayerInstructions[1]
                layerInstruction2 = mainLayerInstructions[0]
            }
            
            if let sourcePixel1 = request.sourceFrame(byTrackID: layerInstruction1.trackID),
                let sourcePixel2 = request.sourceFrame(byTrackID: layerInstruction2.trackID) {
                
                let image1 = generateImage(from: sourcePixel1)
                let sourceImage1 = layerInstruction1.apply(sourceImage: image1, at: time, renderSize: renderSize)
                if let transition = layerInstruction1.transition {
                    let image2 = generateImage(from: sourcePixel2)
                    let sourceImage2 = layerInstruction2.apply(sourceImage: image2, at: time, renderSize: renderSize)
                    
                    let transitionTimeRange = layerInstruction1.timeRange.intersection(layerInstruction2.timeRange)
                    let tweenFactor = factorForTimeInRange(time, range: transitionTimeRange)
                    let transitionImage = transition.renderImage(foregroundImage: sourceImage2, backgroundImage: sourceImage1, forTweenFactor: tweenFactor, renderSize: renderSize)
                    image = transitionImage
                } else {
                    image = sourceImage1
                }
            }
        } else {
            mainLayerInstructions.forEach { (layerInstruction) in
                if let sourcePixel = request.sourceFrame(byTrackID: layerInstruction.trackID) {
                    let sourceImage = layerInstruction.apply(sourceImage: CIImage(cvPixelBuffer: sourcePixel), at: time, renderSize: renderSize)
                    if let previousImage = image {
                        image = sourceImage.composited(over: previousImage)
                    } else {
                        image = sourceImage
                    }
                }
            }
        }
        
        otherLayerInstructions.forEach { (layerInstruction) in
            if let sourcePixel = request.sourceFrame(byTrackID: layerInstruction.trackID) {
                let sourceImage = layerInstruction.apply(sourceImage: CIImage(cvPixelBuffer: sourcePixel), at: time, renderSize: renderSize)
                if let previousImage = image {
                    image = sourceImage.composited(over: previousImage)
                } else {
                    image = sourceImage
                }
            }
        }
        
        if let passingThroughVideoCompositionProvider = passingThroughVideoCompositionProvider, image != nil {
            image = passingThroughVideoCompositionProvider.applyEffect(to: image!, at: time, renderSize: renderSize)
        }
        
        return image
    }
    
    /* 0.0 -> 1.0 */
    private func factorForTimeInRange( _ time: CMTime, range: CMTimeRange) -> Float64 {
        let elapsed = CMTimeSubtract(time, range.start)
        return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration)
    }
    
    private func generateImage(from pixelBuffer: CVPixelBuffer) -> CIImage {
        var image = CIImage(cvPixelBuffer: pixelBuffer)
        let attr = CVBufferGetAttachments(pixelBuffer, .shouldPropagate) as? [ String : Any ]
        if let attr = attr, !attr.isEmpty {
            if let aspectRatioDict = attr[kCVImageBufferPixelAspectRatioKey as String] as? [ String : Any ], !aspectRatioDict.isEmpty {
                let width = aspectRatioDict[kCVImageBufferPixelAspectRatioHorizontalSpacingKey as String] as? CGFloat
                let height = aspectRatioDict[kCVImageBufferPixelAspectRatioVerticalSpacingKey as String] as? CGFloat
                if let width = width, let height = height,  width != 0 && height != 0 {
                    image = image.transformed(by: CGAffineTransform.identity.scaledBy(x: width / height, y: 1))
                }
            }
        }
        return image
    }
    
    open override var debugDescription: String {
        return "<VideoCompositionInstruction, timeRange: {start: \(timeRange.start.seconds), duration: \(timeRange.duration.seconds)}, requiredSourceTrackIDs: \(String(describing: requiredSourceTrackIDs))}>"
    }
}

open class VideoCompositionLayerInstruction: CustomDebugStringConvertible {
    
    public var trackID: Int32
    public var videoCompositionProvider: VideoCompositionProvider
    public var timeRange: CMTimeRange = CMTimeRange.zero
    public var transition: VideoTransition?
    public var prefferdTransform: CGAffineTransform?
    
    public init(trackID: Int32, videoCompositionProvider: VideoCompositionProvider) {
        self.trackID = trackID
        self.videoCompositionProvider = videoCompositionProvider
    }
    
    open func apply(sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        var sourceImage = sourceImage
        if let prefferdTransform = prefferdTransform {
            sourceImage = sourceImage.flipYCoordinate().transformed(by: prefferdTransform).flipYCoordinate()
        }
        let finalImage = videoCompositionProvider.applyEffect(to: sourceImage, at: time, renderSize: renderSize)
        
        return finalImage
    }
    
    public var debugDescription: String {
        return "<VideoCompositionLayerInstruction, trackID: \(trackID), timeRange: {start: \(timeRange.start.seconds), duration: \(timeRange.duration.seconds)}>"
    }
    
}

private extension CIImage {
    func flipYCoordinate() -> CIImage {
        let flipYTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: extent.origin.y * 2 + extent.height)
        return transformed(by: flipYTransform)
    }
}

