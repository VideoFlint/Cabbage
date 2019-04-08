//
//  CGMathFunctions.swift
//  Cabbage
//
//  Created by Vito on 28/02/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation
import CoreGraphics

public extension CGRect {
    func aspectFit(in rect: CGRect) -> CGRect {
        let size = self.size.aspectFit(in: rect.size)
        let x = rect.origin.x + (rect.size.width - size.width) / 2
        let y = rect.origin.y + (rect.size.height - size.height) / 2
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
    
    func aspectFill(in rect: CGRect) -> CGRect {
        let size = self.size.aspectFill(in: rect.size)
        let x = rect.origin.x + (rect.size.width - size.width) / 2
        let y = rect.origin.y + (rect.size.height - size.height) / 2
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}

public extension CGSize {
    func aspectFit(in size: CGSize) -> CGSize {
        var aspectFitSize = size
        let widthRatio = size.width / width
        let heightRatio = size.height / height
        if(heightRatio < widthRatio) {
            aspectFitSize.width = round(heightRatio * width)
        } else if(widthRatio < heightRatio) {
            aspectFitSize.height = round(widthRatio * height)
        }
        return aspectFitSize
    }
    
    func aspectFill(in size: CGSize) -> CGSize {
        var aspectFillSize = size
        let widthRatio = size.width / width
        let heightRatio = size.height / height
        if(heightRatio > widthRatio) {
            aspectFillSize.width = heightRatio * width
        } else if(widthRatio > heightRatio) {
            aspectFillSize.height = widthRatio * height
        }
        return aspectFillSize
    }
}

public extension CGAffineTransform {
    static func transform(by sourceRect: CGRect, aspectFitInRect fitTargetRect: CGRect) -> CGAffineTransform {
        let fitRect = sourceRect.aspectFit(in: fitTargetRect)
        let xRatio = fitRect.size.width / sourceRect.size.width
        let yRatio = fitRect.size.height / sourceRect.size.height
        return CGAffineTransform(translationX: fitRect.origin.x - sourceRect.origin.x * xRatio, y: fitRect.origin.y - sourceRect.origin.y * yRatio).scaledBy(x: xRatio, y: yRatio)
    }
    
    static func transform(by size: CGSize, aspectFitInSize fitSize: CGSize) -> CGAffineTransform {
        let sourceRect = CGRect(origin: .zero, size: size)
        let fitTargetRect = CGRect(origin: .zero, size: fitSize)
        return transform(by: sourceRect, aspectFitInRect: fitTargetRect)
    }
    
    static func transform(by sourceRect: CGRect, aspectFillRect fillTargetRect: CGRect) -> CGAffineTransform {
        let fillRect = sourceRect.aspectFill(in: fillTargetRect)
        let xRatio = fillRect.size.width / sourceRect.size.width
        let yRatio = fillRect.size.height / sourceRect.size.height
        return CGAffineTransform(translationX: fillRect.origin.x - sourceRect.origin.x * xRatio, y: fillRect.origin.y - sourceRect.origin.y * yRatio).scaledBy(x: xRatio, y: yRatio)
    }
    
    static func transform(by size: CGSize, aspectFillSize fillSize: CGSize) -> CGAffineTransform {
        let sourceRect = CGRect(origin: .zero, size: size)
        let fillTargetRect = CGRect(origin: .zero, size: fillSize)
        return transform(by: sourceRect, aspectFillRect: fillTargetRect)
    }
}

public extension CGAffineTransform {
    func rotationRadians() -> CGFloat {
        return atan2(b, a)
    }
    
    func translation() -> CGPoint {
        return CGPoint(x: tx, y: ty)
    }
    
    func scaleXY() -> CGPoint {
        let scalex = sqrt(a * a + c * c)
        let scaley = sqrt(d * d + b * b)
        return CGPoint(x: scalex, y: scaley)
    }
}


