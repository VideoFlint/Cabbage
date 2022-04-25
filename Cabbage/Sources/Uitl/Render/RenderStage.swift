//
//  RenderStage.swift
//  Cabbage
//
//  Created by Vito on 2022/4/24.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import CoreMedia

protocol RenderStageDelegate: AnyObject {
    func leaveRenderTimeRange(_ renderStage: RenderStage)
    func enterRenderTimeRange(_ renderStage: RenderStage)
}

class RenderStage {
    var timeTolerance: CMTime = CMTime(seconds: 0.1, preferredTimeScale: 600)
    weak var delegate: RenderStageDelegate?
    
    private var currentInRenderTimeRange = false
    private var currentTimeRange = CMTimeRange.zero
    private var toleranceTimeRange = CMTimeRange.zero
    
    func updateRenderTime(_ renderTime: CMTime, timelineTimeRange timeRange: CMTimeRange) {
        if !CMTimeRangeEqual(self.currentTimeRange, timeRange) {
            self.currentTimeRange = timeRange
            let start = max(CMTimeGetSeconds(timeRange.start) - CMTimeGetSeconds(self.timeTolerance), 0)
            let duration = CMTimeGetSeconds(CMTimeRangeGetEnd(timeRange)) + CMTimeGetSeconds(self.timeTolerance) - start
            self.toleranceTimeRange = CMTimeRange(start: CMTime(seconds: start, preferredTimeScale: 600),
                                                  duration: CMTime(seconds: duration, preferredTimeScale: 600))
        }
        
        if CMTimeRangeContainsTime(self.toleranceTimeRange, time: renderTime) {
            if !self.currentInRenderTimeRange {
                self.currentInRenderTimeRange = true
                self.delegate?.enterRenderTimeRange(self)
            }
        } else {
            if self.currentInRenderTimeRange {
                self.currentInRenderTimeRange = false
                self.delegate?.leaveRenderTimeRange(self)
            }
        }
    }
}
