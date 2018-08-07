//
//  Resource.swift
//  Cabbage
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import CoreImage

open class Resource: NSObject, NSCopying {

    required override public init() {
    }
    
    /// Max duration of this resource
    open var duration: CMTime = CMTime.zero
    
    /// Selected time range, indicate how many resources will be inserted to AVCompositionTrack
    open var selectedTimeRange: CMTimeRange = CMTimeRange.zero
    
    /// Natural frame size of this resource
    open var size: CGSize = .zero
    
    
    /// Provide tracks for specific media type
    ///
    /// - Parameter type: specific media type, currently only support AVMediaTypeVideo and AVMediaTypeAudio
    /// - Returns: tracks
    open func tracks(for type: AVMediaType) -> [AVAssetTrack] {
        return []
    }
    
    // MARK: - Load content
    
    public enum ResourceStatus: Int {
        case unavaliable
        case avaliable
    }
    
    /// Resource's status, indicate weather the tracks are avaiable. Default is avaliable
    public var status: ResourceStatus = .unavaliable
    public var statusError: Error?
    
    /// Load content makes it available to get tracks. When use load resource from PHAsset or internet resource, it's your responsibility to determinate when and where to load the content.
    ///
    /// - Parameters:
    ///   - progressHandler: loading progress
    ///   - completion: load completion
    @discardableResult
    open func prepare(progressHandler:((Double) -> Void)? = nil, completion: @escaping (ResourceStatus, Error?) -> Void) -> ResourceTask? {
        completion(status, statusError)
        return nil
    }
    
    // MARK: - NSCopying
    open func copy(with zone: NSZone? = nil) -> Any {
        let resource = type(of: self).init()
        resource.duration = duration
        resource.selectedTimeRange = selectedTimeRange
        return resource
    }
    
}

public class ResourceTask {
    public var cancelHandler: (() -> Void)?
    
    public init(cancel: (() -> Void)? = nil) {
        self.cancelHandler = cancel
    }
    
    public func cancel() {
        cancelHandler?()
    }
}
