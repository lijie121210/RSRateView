//
//  RSTimer.swift
//  RollingStone
//
//  Created by jie on 2017/1/8.
//  Copyright © 2017年 HTIOT.Inc. All rights reserved.
//

import Foundation
import UIKit

public class RSRepeatedTimer {
    
    private var timeInterval: TimeInterval
    private var taskBlock: ((RSRepeatedTimer) -> ())?
    private var timer: Timer!
    private var isReleased: Bool
    
    public init(timeInterval interval: TimeInterval, runNow isRun: Bool = true, block: @escaping (RSRepeatedTimer) -> ()) {
        timeInterval = interval
        taskBlock = block
        isReleased = false
        
        if isRun {
            valid()
        }
    }
    
    @objc func timerAction() {
        if let task = self.taskBlock {
            task(self)
        }
    }
    
    @discardableResult
    public func invalid() -> RSRepeatedTimer {
        if let _ = timer {
            timer.invalidate()
            timer = nil
        }
        return self
    }
    
    @discardableResult
    public func valid() -> RSRepeatedTimer {
        guard isReleased == false, timer == nil else { return self }
        
        timer = Timer(timeInterval: timeInterval, target: self, selector: #selector(RSRepeatedTimer.timerAction), userInfo: nil, repeats: true)
        
        RunLoop.main.add(timer, forMode: .commonModes)
        
        return self
    }
    
    /// if there is a timer already, fire the timer immediately, 
    /// if not, create a new timer and fire it, the new timer will keep alive.
    public func fireNow() {
        guard isReleased == false else { return }
        
        if let t = timer {
            t.fire()
        } else {
            valid()
            fireNow()
        }
    }
    
    /// After calling this method, do not use the instance anymore
    public func releaseSource() {
        guard isReleased == false else { return }
        
        invalid()
        taskBlock = nil
        
        isReleased = true
    }
}



public class RSActionTimeCounter {
    
    private var timer: RSRepeatedTimer!
    private var _timeInterval: Double
    
    public var timeInterval: Double {
        return _timeInterval
    }
    
    deinit {
        print("RSActionTimeCounter.deinit")
    }
    public init() {
        _timeInterval = 0.0
        
        timer = RSRepeatedTimer(timeInterval: 0.1, runNow: false, block: { [weak self] (_) in
            guard let sself = self else { return }
            sself._timeInterval += 0.1
        })
    }
    
    public func startCounting() {
        _timeInterval = 0.0
        timer.valid()
    }
    
    public func stopCounting() {
        timer.invalid()
    }
    
    /// Must Call!
    public func releaseCounter() {
        timer.releaseSource()
        timer = nil
    }
}






final public class RSRateAnimator {
    
    private var _timer: RSRepeatedTimer!
    
    deinit {
        print("RSRateAnimator.deinit")
    }
    
    public convenience init?(timeInterval: TimeInterval, updateClosure: @escaping (_ newProgress: Float) -> (), completion: (() -> ())? = nil ) {
        self.init(timeInterval: timeInterval, targetProgress: 1.0, updateClosure: updateClosure, completion: completion)
    }
    
    public init?(timeInterval: TimeInterval, targetProgress: Float, updateClosure: @escaping (_ newProgress: Float) -> (), completion: (() -> ())? = nil ) {
        guard timeInterval > 0, targetProgress >= 0, targetProgress <= 1.0 else {
            return nil
        }
        
        var progress: Float = 0.0
        
        _timer = RSRepeatedTimer(timeInterval: 0.1, runNow: false, block: { t in
            progress += ( targetProgress / Float(timeInterval * 10) )
            updateClosure( max( min( progress, 1.0 ), 0.0) )
            if progress >= targetProgress {
                t.invalid()
                if let complete = completion { complete() }
            }
            
        })
    }
    
    public func run() {
        _timer.fireNow()
    }
    
    public func cancel() {
        _timer.invalid()
    }
    
    public func clear() {
        _timer.releaseSource()
        _timer = nil
    }
}
