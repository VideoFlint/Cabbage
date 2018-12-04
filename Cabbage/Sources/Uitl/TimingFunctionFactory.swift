//
//  TimingFunctionFactory.swift
//  Cabbage
//
//  Created by Vito on 2018/7/5.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation

public class TimingFunctionFactory {
    // Modeled after the line y = x
    static public func linearInterpolation(p: Float) -> Float {
        return p
    }
    
    // Modeled after the parabola y = x^2
    static public func quadraticEaseIn(p: Float) -> Float {
        return p * p
    }
    
    // Modeled after the parabola y = -x^2 + 2x
    static public func quadraticEaseOut(p: Float) -> Float {
        return -(p * (p - 2))
    }
    
    // Modeled after the piecewise quadratic
    // y = (1/2)((2x)^2)             ; [0, 0.5)
    // y = -(1/2)((2x-1)*(2x-3) - 1) ; [0.5, 1]
    static public func quadraticEaseInOut(p: Float) -> Float {
        if(p < 0.5) {
            return 2 * p * p;
        } else {
            return (-2 * p * p) + (4 * p) - 1;
        }
    }
    
    // Modeled after the cubic y = x^3
    static public func cubicEaseIn(p: Float) -> Float {
        return p * p * p
    }
    
    // Modeled after the cubic y = (x - 1)^3 + 1
    static public func cubicEaseOut(p: Float) -> Float {
        let f: Float = (p - 1)
        return f * f * f + 1
    }
    
    // Modeled after the piecewise cubic
    // y = (1/2)((2x)^3)       ; [0, 0.5)
    // y = (1/2)((2x-2)^3 + 2) ; [0.5, 1]
    static public func cubicEaseInOut(p: Float) -> Float {
        if(p < 0.5) {
            return 4 * p * p * p
        } else {
            let f = ((2 * p) - 2)
            return 0.5 * f * f * f + 1
        }
    }
    
    // Modeled after the quartic x^4
    static public func quarticEaseIn(p: Float) -> Float {
        return p * p * p * p
    }
    
    // Modeled after the quartic y = 1 - (x - 1)^4
    static public func quarticEaseOut(p: Float) -> Float {
        let f = (p - 1)
        return f * f * f * (1 - p) + 1
    }
    
    // Modeled after the piecewise quartic
    // y = (1/2)((2x)^4)        ; [0, 0.5)
    // y = -(1/2)((2x-2)^4 - 2) ; [0.5, 1]
    static public func quarticEaseInOut(p: Float) -> Float {
        if(p < 0.5)
        {
            return 8 * p * p * p * p;
        }
        else
        {
            let f = (p - 1);
            return -8 * f * f * f * f + 1;
        }
    }
    
    // Modeled after the quintic y = x^5
    static public func quinticEaseIn(p: Float) -> Float {
        return p * p * p * p * p;
    }
    
    // Modeled after the quintic y = (x - 1)^5 + 1
    static public func quinticEaseOut(p: Float) -> Float {
        let f = (p - 1);
        return f * f * f * f * f + 1;
    }
    
    // Modeled after the piecewise quintic
    // y = (1/2)((2x)^5)       ; [0, 0.5)
    // y = (1/2)((2x-2)^5 + 2) ; [0.5, 1]
    static public func quinticEaseInOut(p: Float) -> Float {
        if(p < 0.5)
        {
            return 16 * p * p * p * p * p;
        }
        else
        {
            let f = ((2 * p) - 2);
            return  0.5 * f * f * f * f * f + 1;
        }
    }
    
    // Modeled after quarter-cycle of sine wave
    static public func SineEaseIn(p: Float) -> Float {
        return sin((p - 1) * Float.pi / 2) + 1;
    }
    
    // Modeled after quarter-cycle of sine wave (different phase)
    static public func SineEaseOut(p: Float) -> Float {
        return sin(p * Float.pi / 2);
    }
    
    // Modeled after half sine wave
    static public func SineEaseInOut(p: Float) -> Float {
        return 0.5 * (1 - cos(p * Float.pi));
    }
    
    // Modeled after shifted quadrant IV of unit circle
    static public func circularEaseIn(p: Float) -> Float {
        return 1 - sqrt(1 - (p * p));
    }
    
    // Modeled after shifted quadrant II of unit circle
    static public func circularEaseOut(p: Float) -> Float {
        return sqrt((2 - p) * p);
    }
    
    // Modeled after the piecewise circular function
    // y = (1/2)(1 - sqrt(1 - 4x^2))           ; [0, 0.5)
    // y = (1/2)(sqrt(-(2x - 3)*(2x - 1)) + 1) ; [0.5, 1]
    static public func circularEaseInOut(p: Float) -> Float {
        if(p < 0.5)
        {
            return 0.5 * (1 - sqrt(1 - 4 * (p * p)));
        }
        else
        {
            return 0.5 * (sqrt(-((2 * p) - 3) * ((2 * p) - 1)) + 1);
        }
    }
    
    // Modeled after the exponential function y = 2^(10(x - 1))
    static public func exponentialEaseIn(p: Float) -> Float {
        return (p == 0.0) ? p : pow(2, 10 * (p - 1));
    }
    
    // Modeled after the exponential function y = -2^(-10x) + 1
    static public func exponentialEaseOut(p: Float) -> Float {
        return (p == 1.0) ? p : 1 - pow(2, -10 * p);
    }
    
    // Modeled after the piecewise exponential
    // y = (1/2)2^(10(2x - 1))         ; [0,0.5)
    // y = -(1/2)*2^(-10(2x - 1))) + 1 ; [0.5,1]
    static public func exponentialEaseInOut(p: Float) -> Float {
        if(p == 0.0 || p == 1.0) {
            return p;
        }
        
        if(p < 0.5)
        {
            return 0.5 * pow(2, (20 * p) - 10);
        }
        else
        {
            return -0.5 * pow(2, (-20 * p) + 10) + 1;
        }
    }
    
    // Modeled after the damped sine wave y = sin(13pi/2*x)*pow(2, 10 * (x - 1))
    static public func elasticEaseIn(p: Float) -> Float {
        return sin(13 * Float.pi / 2 * p) * pow(2, 10 * (p - 1));
    }
    
    // Modeled after the damped sine wave y = sin(-13pi/2*(x + 1))*pow(2, -10x) + 1
    static public func elasticEaseOut(p: Float) -> Float {
        return sin(-13 * Float.pi / 2 * (p + 1)) * pow(2, -10 * p) + 1;
    }
    
    // Modeled after the piecewise exponentially-damped sine wave:
    // y = (1/2)*sin(13pi/2*(2*x))*pow(2, 10 * ((2*x) - 1))      ; [0,0.5)
    // y = (1/2)*(sin(-13pi/2*((2x-1)+1))*pow(2,-10(2*x-1)) + 2) ; [0.5, 1]
    static public func elasticEaseInOut(p: Float) -> Float {
        if(p < 0.5)
        {
            return 0.5 * sin(13 * Float.pi / 2 * (2 * p)) * pow(2, 10 * ((2 * p) - 1));
        }
        else
        {
            return 0.5 * (sin(-13 * Float.pi / 2 * ((2 * p - 1) + 1)) * pow(2, -10 * (2 * p - 1)) + 2);
        }
    }
    
    // Modeled after the overshooting cubic y = x^3-x*sin(x*pi)
    static public func backEaseIn(p: Float) -> Float {
        return p * p * p - p * sin(p * Float.pi);
    }
    
    // Modeled after overshooting cubic y = 1-((1-x)^3-(1-x)*sin((1-x)*pi))
    static public func backEaseOut(p: Float) -> Float {
        let f = (1 - p);
        return 1 - (f * f * f - f * sin(f * Float.pi));
    }
    
    // Modeled after the piecewise overshooting cubic function:
    // y = (1/2)*((2x)^3-(2x)*sin(2*x*pi))           ; [0, 0.5)
    // y = (1/2)*(1-((1-x)^3-(1-x)*sin((1-x)*pi))+1) ; [0.5, 1]
    static public func backEaseInOut(p: Float) -> Float {
        if(p < 0.5)
        {
            let f = 2 * p;
            return 0.5 * (f * f * f - f * sin(f * Float.pi));
        }
        else
        {
            let f = (1 - (2*p - 1));
            return 0.5 * (1 - (f * f * f - f * sin(f * Float.pi))) + 0.5;
        }
    }
    
    static public func bounceEaseIn(p: Float) -> Float {
        return 1 - bounceEaseOut(p: 1 - p);
    }
    
    static public func bounceEaseOut(p: Float) -> Float {
        if(p < 4/11.0)
        {
            return (121 * p * p)/16.0;
        }
        else if(p < 8/11.0)
        {
            return (363/40.0 * p * p) - (99/10.0 * p) + 17/5.0;
        }
        else if(p < 9/10.0)
        {
            return (4356/361.0 * p * p) - (35442/1805.0 * p) + 16061/1805.0;
        }
        else
        {
            return (54/5.0 * p * p) - (513/25.0 * p) + 268/25.0;
        }
    }
    
    static public func bounceEaseInOut(p: Float) -> Float {
        if(p < 0.5)
        {
            return 0.5 * bounceEaseIn(p: p*2);
        }
        else
        {
            return 0.5 * bounceEaseOut(p: p * 2 - 1) + 0.5;
        }
    }
    
    static public func bounceTwice(p: Float) -> Float {
        let cutoff1: Float = 4.0/6.0;
        
        if(p < cutoff1)
        {
            return sinf(p/cutoff1*Float.pi);
        }
        else
        {
            return (1.0 - cutoff1) * sinf((p-cutoff1)/(1.0-cutoff1)*Float.pi);
        }
    }
}


