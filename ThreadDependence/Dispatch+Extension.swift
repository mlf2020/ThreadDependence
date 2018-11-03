//
//  Dispatch+Extension.swift
//  AppShareKit
//
//  Created by menglingfeng on 2018/1/23.
//  Copyright © 2018年 Moglo. All rights reserved.
//

import Foundation


public extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    public class func once(file: String = #file, function: String = #function, line: Int = #line, block:()->Void) {
        let token = file + ":" + function + ":" + String(line)
        once(token: token, block: block)
    }
    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    public class func once(token: String, block:()->Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
    

    //delay
    
    typealias Task = (_ cancel : Bool) -> Void
    
    @discardableResult
    static func delay(time : TimeInterval, task: @escaping () -> ()) -> Task? {
        
        func dispatch_later(block : @escaping () -> ()) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time , execute: block)
        }
        
        var closure : (() -> ())? = task
        var result : Task?
        
        let delayedClosure : Task = {
            cancel in
            if let internalClosure = closure {
                if cancel == false {
                    DispatchQueue.main.async(execute: internalClosure)
                }
            }
            
            closure = nil
            result = nil
        }
        
        result = delayedClosure
        
        dispatch_later { () -> () in
            if let delayedClosure = result {
                delayedClosure(false)
            }
        }
        
        return result
    }
    
    static func cancel(task : Task?) {
        task?(true)
    }
    
}



