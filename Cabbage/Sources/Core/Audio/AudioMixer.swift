//
//  AudioMixer.swift
//  Cabbage
//
//  Created by Vito on 2018/6/30.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation
import Accelerate

public class AudioMixer {
    public static func changeVolume(for bufferList: UnsafeMutablePointer<AudioBufferList>, volume: Float) {
        let bufferList = UnsafeMutableAudioBufferListPointer(bufferList)
        for bufferIndex in 0..<bufferList.count {
            let audioBuffer = bufferList[bufferIndex]
            if let rawBuffer = audioBuffer.mData {
                let floatRawPointer = rawBuffer.assumingMemoryBound(to: Float.self)
                let frameCount = UInt(audioBuffer.mDataByteSize) / UInt(MemoryLayout<Float>.size)
                var volume = volume
                vDSP_vsmul(floatRawPointer, 1, &volume, floatRawPointer, 1, frameCount)
            }
        }
    }
}
