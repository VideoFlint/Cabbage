//
//  AVMutableAudioMixInputParametersExtension.swift
//  Cabbage
//
//  Created by Vito on 2022/4/10.
//  Copyright © 2022 Vito. All rights reserved.
//

import AVFoundation

extension AVMutableAudioMixInputParameters {
    private static var audioProcessingTapHolderKey: UInt8 = 0
    var audioProcessingTapHolder: AudioProcessingTapHolder? {
        get {
            return objc_getAssociatedObject(self, &AVMutableAudioMixInputParameters.audioProcessingTapHolderKey) as? AudioProcessingTapHolder
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AVMutableAudioMixInputParameters.audioProcessingTapHolderKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
