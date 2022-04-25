//
//  FileImageResource.swift
//  Cabbage
//
//  Created by Vito on 2022/4/17.
//  Copyright © 2022 Vito. All rights reserved.
//

import CoreMedia
import CoreGraphics
import CoreImage

open class FileImageResource: Resource {
    
    public var filePath: String
    private var tempImage: CIImage?
    private let semaphore = DispatchSemaphore(value: 1)
    
    public init(filePath: String, duration: CMTime) {
        self.filePath = filePath
        super.init()
        self.duration = duration
        self.selectedTimeRange = CMTimeRange(start: CMTime.zero, duration: duration)
    }
    
    required public init() {
        fatalError("init() has not been implemented")
    }
    
    open override func image(at time: CMTime, renderSize: CGSize) -> CIImage? {
        self.loadImage()
        return self.tempImage
    }
    
    private func loadImage() {
        self.semaphore.wait()
        var image = self.tempImage
        if image == nil {
            image = ObjectReferenceCache.shared.object(for: self.filePath as NSString) as? CIImage
            if image == nil {
                let url = URL(fileURLWithPath: self.filePath)
                image = CIImage(contentsOf: url)
                ObjectReferenceCache.shared.saveObject(image, forKey: self.filePath as NSString)
            }
        }
        self.tempImage = image
        self.semaphore.signal()
    }
    
    public override func cleanCache() {
        self.semaphore.wait()
        self.tempImage = nil
        self.semaphore.signal()
    }
    
}
