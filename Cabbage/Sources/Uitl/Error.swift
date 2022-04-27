//
//  Error.swift
//  Cabbage
//
//  Created by Vito on 2022/4/26.
//  Copyright © 2022 Vito. All rights reserved.
//

import Foundation

enum ErrorDomain: String {
    case common = "com.cabbage"
    case render = "com.cabbage.render"
}

enum ErrorCode: Int {
    case common = 100
}

