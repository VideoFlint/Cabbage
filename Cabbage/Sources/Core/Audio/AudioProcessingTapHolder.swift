//
//  AudioProcessingTapHolder.swift
//  Cabbage
//
//  Created by Vito on 2018/5/9.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

public class AudioProcessingTapHolder: NSObject, NSCopying {
    
    fileprivate(set) var tap: MTAudioProcessingTap?
    public var audioProcessingChain = AudioProcessingChain()
    
    public required override init() {
        super.init()
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passRetained(self.audioProcessingChain).toOpaque()),
            init: tapInit,
            finalize: tapFinalize,
            prepare: tapPrepare,
            unprepare: tapUnprepare,
            process: tapProcess)
        var tap: Unmanaged<MTAudioProcessingTap>?
        let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        if err != noErr {
            Log.error("error: failed to create audioProcessingTap")
        }
        self.tap = tap?.takeRetainedValue()
        
    }
    
    // MARK: - Handler
    fileprivate var tapInit: MTAudioProcessingTapInitCallback = {
        (tap, clientInfo, tapStorageOut) in
        Log.info("init \(tap), \(String(describing: clientInfo)), \(tapStorageOut)\n")
        tapStorageOut.pointee = clientInfo
    }
    
    fileprivate var tapFinalize: MTAudioProcessingTapFinalizeCallback = {
        (tap) in
        Log.info("finalize \(tap)\n")
        let storage = MTAudioProcessingTapGetStorage(tap)
        let unmangedStorage = Unmanaged<AudioProcessingChain>.fromOpaque(storage)
        unmangedStorage.release()
    }
    
    fileprivate var tapPrepare: MTAudioProcessingTapPrepareCallback = {
        (tap, maxFrames, processingFormat) in
        Log.info("prepare: \(tap) \(maxFrames) \(processingFormat) \n")
    }
    
    fileprivate var tapUnprepare: MTAudioProcessingTapUnprepareCallback = {
        (tap) in
        Log.info("unprepare \(tap)\n")
    }
    
    fileprivate var tapProcess: MTAudioProcessingTapProcessCallback = {
        (tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut) in
        Log.info("callback \(tap) \(numberFrames) \(flags) \(bufferListInOut) \(numberFramesOut) \(flagsOut)\n")
        var timeRange: CMTimeRange = CMTimeRange.zero
        let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, &timeRange, numberFramesOut)
        if status != noErr {
            Log.error("error: failed to get source audio")
            return;
        }
        let storage = MTAudioProcessingTapGetStorage(tap)
        let unmangedStorage = Unmanaged<AudioProcessingChain>.fromOpaque(storage)
        let audioProcessingChain = unmangedStorage.takeUnretainedValue()
        audioProcessingChain.process(timeRange: timeRange, bufferListInOut: bufferListInOut)
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let holder = type(of: self).init()
        holder.audioProcessingChain = audioProcessingChain.copy() as! AudioProcessingChain
        return holder
    }
}
