//
//  CMTimeExtensition.swift
//  Cabbage
//
//  Created by Vito on 2018/7/19.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreMedia

// MARK: Initialization
public extension CMTime {
    init(value: Int64, _ timescale: Int = 1) {
        self = CMTimeMake(value: value, timescale: Int32(timescale))
    }
    init(value: Int64, _ timescale: Int32 = 1) {
        self = CMTimeMake(value: value, timescale: timescale)
    }
    init(seconds: Float64, preferredTimeScale: Int32 = 600) {
        self = CMTimeMakeWithSeconds(seconds, preferredTimescale: preferredTimeScale)
    }
    init(seconds: Float, preferredTimeScale: Int32 = 600) {
        self = CMTime(seconds: Float64(seconds), preferredTimeScale: preferredTimeScale)
    }
    func cb_time(preferredTimeScale: Int32 = 600) -> CMTime {
        return CMTime(seconds: seconds, preferredTimescale: preferredTimeScale)
    }
}

// MARK: - Arithmetic Protocol

// MARK: Add

func += ( left: inout CMTime, right: CMTime) -> CMTime {
    left = left + right
    return left
}

// MARK: Subtract

func -= ( minuend: inout CMTime, subtrahend: CMTime) -> CMTime {
    minuend = minuend - subtrahend
    return minuend
}

// MARK: Multiply
func * (time: CMTime, multiplier: Int32) -> CMTime {
    return CMTimeMultiply(time, multiplier: multiplier)
}
func * (multiplier: Int32, time: CMTime) -> CMTime {
    return CMTimeMultiply(time, multiplier: multiplier)
}
func * (time: CMTime, multiplier: Float64) -> CMTime {
    return CMTimeMultiplyByFloat64(time, multiplier: multiplier)
}
func * (time: CMTime, multiplier: Float) -> CMTime {
    return CMTimeMultiplyByFloat64(time, multiplier: Float64(multiplier))
}
func * (multiplier: Float64, time: CMTime) -> CMTime {
    return time * multiplier
}
func * (multiplier: Float, time: CMTime) -> CMTime {
    return time * multiplier
}
func *= ( time: inout CMTime, multiplier: Int32) -> CMTime {
    time = time * multiplier
    return time
}
func *= ( time: inout CMTime, multiplier: Float64) -> CMTime {
    time = time * multiplier
    return time
}
func *= ( time: inout CMTime, multiplier: Float) -> CMTime {
    time = time * multiplier
    return time
}

// MARK: Divide
func / (time: CMTime, divisor: Int32) -> CMTime {
    return CMTimeMultiplyByRatio(time, multiplier: 1, divisor: divisor)
}
func /= ( time: inout CMTime, divisor: Int32) -> CMTime {
    time = time / divisor
    return time
}

// MARK: - Comparable protocol

extension CMTime {
    var f: Float {
        return Float(self.f64)
    }
    var f64: Float64 {
        return CMTimeGetSeconds(self)
    }
}

func == (time: CMTime, seconds: Float64) -> Bool {
    return time == CMTime(seconds: seconds)
}
func == (time: CMTime, seconds: Float) -> Bool {
    return time == Float64(seconds)
}
func == (seconds: Float64, time: CMTime) -> Bool {
    return time == seconds
}
func == (seconds: Float, time: CMTime) -> Bool {
    return time == seconds
}
func != (time: CMTime, seconds: Float64) -> Bool {
    return !(time == seconds)
}
func != (time: CMTime, seconds: Float) -> Bool {
    return time != Float64(seconds)
}
func != (seconds: Float64, time: CMTime) -> Bool {
    return time != seconds
}
func != (seconds: Float, time: CMTime) -> Bool {
    return time != seconds
}

public func < (time: CMTime, seconds: Float64) -> Bool {
    return time < CMTime(seconds: seconds)
}
public func < (time: CMTime, seconds: Float) -> Bool {
    return time < Float64(seconds)
}
public func <= (time: CMTime, seconds: Float64) -> Bool {
    return time < seconds || time == seconds
}
public func <= (time: CMTime, seconds: Float) -> Bool {
    return time < seconds || time == seconds
}
public func < (seconds: Float64, time: CMTime) -> Bool {
    return CMTime(seconds: seconds) < time
}
public func < (seconds: Float, time: CMTime) -> Bool {
    return Float64(seconds) < time
}
public func <= (seconds: Float64, time: CMTime) -> Bool {
    return seconds < time || seconds == time
}
public func <= (seconds: Float, time: CMTime) -> Bool {
    return seconds < time || seconds == time
}

public func > (time: CMTime, seconds: Float64) -> Bool {
    return time > CMTime(seconds: seconds)
}
public func > (time: CMTime, seconds: Float) -> Bool {
    return time > Float64(seconds)
}
public func >= (time: CMTime, seconds: Float64) -> Bool {
    return time > seconds || time == seconds
}
public func >= (time: CMTime, seconds: Float) -> Bool {
    return time > seconds || time == seconds
}
public func > (seconds: Float64, time: CMTime) -> Bool {
    return CMTime(seconds: seconds) > time
}
public func > (seconds: Float, time: CMTime) -> Bool {
    return Float64(seconds) > time
}
public func >= (seconds: Float64, time: CMTime) -> Bool {
    return seconds > time || seconds == time
}
public func >= (seconds: Float, time: CMTime) -> Bool {
    return seconds > time || seconds == time
}
