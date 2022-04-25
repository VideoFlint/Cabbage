//
//  ObjectReferenceCahce.swift
//  Cabbage
//
//  Created by Vito on 2022/4/24.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation

class ObjectReferenceCache {
    
    static let shared = ObjectReferenceCache()
    
    let imageCacheTable: NSMapTable<AnyObject, AnyObject>
    
    private init() {
        imageCacheTable = NSMapTable<AnyObject, AnyObject>(keyOptions: .copyIn,
                                     valueOptions: .weakMemory,
                                     capacity: 64)
    }
    
    func saveObject(_ object: AnyObject?, forKey: AnyObject) {
        self.imageCacheTable.setObject(object, forKey: forKey)
    }
    
    func object(for key: AnyObject) -> AnyObject? {
        return self.imageCacheTable.object(forKey: key)
    }
    
}
