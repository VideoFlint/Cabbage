//
//  RenderContext.swift
//  Cabbage
//
//  Created by Vito on 2022/4/24.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation
import CoreMedia

protocol RenderContextRealTimeRenderObserver: AnyObject {
    func renderContextDidChange(renderTime: CMTime)
}

class RenderContext {
    
    static let shared = RenderContext()
    
//    private let observerList = NSHashTable<RenderContextRealTimeRenderObserver>.weakObjects()
//    private let semaphore = DispatchSemaphore(value: 1)
    
    private init() {}
    
//    func registerObserver(_ observer: RenderContextRealTimeRenderObserver) {
//        self.semaphore.wait()
//        if !self.observerList.contains(observer) {
//            self.observerList.add(observer)
//        }
//        self.semaphore.signal()
//    }
//
//    func unregisterObserver(_ observer: RenderContextRealTimeRenderObserver) {
//        self.semaphore.wait()
//        self.observerList.remove(observer)
//        self.semaphore.signal()
//    }
//
//    func updateRenderTime(_ renderTime: CMTime) {
//        self.semaphore.wait()
//        self.observerList.allObjects.forEach { observer in
//            observer.renderContextDidChange(renderTime: renderTime)
//        }
//        self.semaphore.signal()
//    }
}
