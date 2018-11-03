//
//  ThreadViewController.swift
//  UITextViewPlaceholder
//
//  Created by apple on 8/13/18.
//  Copyright © 2018 mlf. All rights reserved.
//

import UIKit

#if DEBUG
var signal: DispatchSourceSignal?

private let setupSignalHandlerFor = {(object: AnyObject) in
    
    let queue = DispatchQueue.main
    signal = DispatchSource.makeSignalSource(signal: SIGSTOP, queue: queue)
    signal?.setEventHandler(handler: {
        print("HI I am: \(String(describing: object.description))")
    })
    
    signal?.resume()
}
#endif


class ThreadViewController: UIViewController {
    
    private var lock = DispatchSemaphore(value: 0)
    
    private let queueGroup = DispatchGroup()

    private var thread: CustomThread!
    
    fileprivate var globalData: UInt = 0
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        #if DEBUG
//            setupSignalHandlerFor(self)
        #endif
        title = "Test"

        thread = CustomThread(target: self, selector: #selector(persistant(thread:)), object: nil)
        thread.start()
        // Do any additional setup after loading the view.
        
        let button = UIButton(type: .system)
        button.setTitle("点我吧看下调用栈吧", for: .normal)
        button.frame = CGRect(x: 100, y: 200, width: 100, height: 60)
        button.addTarget(self, action: #selector(buttonClick(sender:)), for: .touchUpInside)
        view.addSubview(button)
        
        
        connect()
        startPreview(count: 1)
        startPreview(count: 2)
        startPreview(count: 3)
    }
    
    
    @objc func buttonClick(sender: UIButton){
        NSLog("%@", Thread.callStackSymbols)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @objc func persistant(thread: CustomThread){
        
        print("开始任务 当前线程: \(Thread.current)")
        autoreleasepool { () -> Void in
            //添加port事件使线程常驻 此时不会调用 customThread deinit 也不会调用当前vc deinit
            Thread.current.name = "mlf.customThread"
            RunLoop.current.add(Port(), forMode: RunLoop.Mode.default)
            RunLoop.current.run()
        }
        print("runloop未启动")
    }
    
    @objc func otherOperation(){
        print("其他一条任务开始 当前线程: \(Thread.current)")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        perform(#selector(otherOperation), on: thread, with: nil, waitUntilDone: false)
        perform(#selector(gcdMainQueueWillCrash), on: Thread.main, with: nil, waitUntilDone: false) //死锁
//        perform(#selector(gcdQueueSyncTask), on: Thread.main, with: nil, waitUntilDone: false)
//        perform(#selector(gcdGroupSyncTask), on: Thread.main, with: nil, waitUntilDone: false)
//        perform(#selector(gcdUserData), on: Thread.main, with: nil, waitUntilDone: false)
        
//        perform(#selector(gcdThreadSafe), on: Thread.main, with: nil, waitUntilDone: false)
        
        //GCD并发性循环
//        perform(#selector(concurrentPerform), on: Thread.main, with: nil, waitUntilDone: false)
    }
    
    

    deinit {
//        Thread.exit()
        print("-------- vc deinit")
    }
    
    
    
    @IBAction func buttonClick(_ sender: UIButton) {
        
        perform(#selector(otherOperation), on: thread, with: nil, waitUntilDone: false)
    }
    

}


extension ThreadViewController{
    
   @objc fileprivate func gcdMainQueueWillCrash(){
        print("current thread: \(Thread.current)")
        print("thread start --------")

        //同样在主队列开启任务, 导致死锁（前提 gcdMainQueueWillCrash 在main队列）
        DispatchQueue.main.sync {
            Thread.sleep(forTimeInterval: 0.4)
            print("task one --------- thread: \(Thread.current)")
        }


        DispatchQueue.main.sync {
            Thread.sleep(forTimeInterval: 0.4)
            print("task two --------- thread: \(Thread.current)")
        }


        print("thread end ---------")
    
    }
    
    
    //同一队列按顺序异步执行： 异步 + 串行队列
    @objc fileprivate func gcdQueueSyncTask(){
        
        let queue = DispatchQueue(label: "com.mlf.queue")
        
//        let queue = DispatchQueue(label: "com.mlf.queue", attributes: .concurrent)
        print("func begin ---------thread：\(Thread.current)")
        
        //串行队列 先添加的任务会先执行
        queue.async {
            for _ in 0..<3{
                Thread.sleep(forTimeInterval: 0.5)
                print("task one ----------- thread：\(Thread.current) ")
            }
        }
        
        
        queue.async {
            for _ in 0..<3{
                Thread.sleep(forTimeInterval: 0.5)
                print("task two ----------- thread：\(Thread.current)")
            }
        }
        
        
        queue.async {
            for _ in 0..<3{
                Thread.sleep(forTimeInterval: 0.5)
                print("task three ----------- thread：\(Thread.current)")
            }
        }
        
        print("func end ---------")
        
    }
    
    
    //不同队列按顺序异步执行： 队列组
    @objc fileprivate func gcdGroupSyncTask(){
        //创建队列组
        //注意 ： 下面代码如果没有 group.wait() 的话 会开启三个新的线程并发执行任务 ，
        // 如果有 group.wait() 则只开启了一个新的线程串行执行任务
        let group = DispatchGroup()
        print("func begin ---------thread：\(Thread.current)")
        group.enter()
        DispatchQueue.global().async {
            for _ in 0..<3{
                Thread.sleep(forTimeInterval: 0.5)
                print("task one ----------- thread：\(Thread.current)")
            }
            //完成离开
            group.leave()
        }
        
        group.wait()
        group.enter()
        DispatchQueue(label: "com.mlf.queque1").async {
            for _ in 0..<3{
                Thread.sleep(forTimeInterval: 0.5)
                print("task two ----------- thread：\(Thread.current)")
            }
            //完成离开
            group.leave()
        }
        
        group.wait()
        group.enter()
        DispatchQueue(label: "com.mlf.queque2").async {
            for _ in 0..<3{
                Thread.sleep(forTimeInterval: 0.5)
                print("task three ----------- thread：\(Thread.current)")
            }
            //完成离开
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.main) {
            print("all tasks perform finished -------- thread: \(Thread.current)")
        }
        
        print("func end -------------")
    }
    
    
    @objc func gcdUserData(){
        let userData = DispatchSource.makeUserDataAddSource()
        userData.setEventHandler {[weak self] in
            guard let strongSelf = self else{return}
            let pending = userData.data
            strongSelf.globalData += pending
            print("pending data is:\(pending) and now global data is :\(strongSelf.globalData)")
        }
        
        userData.resume()
        
        DispatchQueue(label: "XMWFOEWF").async {
            for _ in 1...2000 {
                userData.add(data: 1)
            }
            
            for _ in 1...1000 {
                userData.add(data: 1)
            }
        
        }
        
    }
    
    
    @objc func gcdThreadSafe(){
        
        let queue = DispatchQueue(label: "com.mlf.queue", attributes: .concurrent)
        
        queue.async {
            for _ in 0..<3{
                print("task three read ----------- thread：\(Thread.current)")
            }
        }
        
        

        
        let wirte = DispatchWorkItem(flags: .barrier) {
            // write data
            for _ in 0..<3{
                Thread.sleep(forTimeInterval: 0.5)
                print("task one write ----------- thread：\(Thread.current)")
            }
        }

        let wirteTwo = DispatchWorkItem(flags: .barrier) {
            // write data
            for _ in 0..<3{
                Thread.sleep(forTimeInterval: 0.5)
                print("task two write ----------- thread：\(Thread.current)")
            }
        }
        
        queue.async(execute: wirte)
        
        queue.async {
            for _ in 0..<3{
                print("task four read ----------- thread：\(Thread.current)")
            }
        }
        
        
        queue.async(execute: wirteTwo)
        
    }
    
    
    //并发性循环
    @objc func concurrentPerform(){
        
        //普通的循环并发
        let group = DispatchGroup()
        
//        for index in 0..<5{
//            group.enter()
//            let queue = DispatchQueue(label: "com.mlf.queue999")
//            queue.async {
//                Thread.sleep(forTimeInterval: 2)
//                //完成离开
//                print("do job-\(index) in thread: \(Thread.current)")
//                group.leave()
//            }
//        }
//
//        group.notify(queue: DispatchQueue.main) {
//            print("all job finished -------- ")
//        }
        
        
        //GCD循环并发
        let queue = DispatchQueue(label: "com.mlf.queue999ccc")
//        let _ = DispatchQueue.global(qos: .userInitiated)
        DispatchQueue.concurrentPerform(iterations: 5) { (index) in
            group.enter()
            queue.async {
                Thread.sleep(forTimeInterval: 2)
                //完成离开
                print("do job-\(index) in thread: \(Thread.current)")
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            print("all job finished -------- ")
        }
 
    }
    
    
    func connect(){
        
        queueGroup.enter()
        let queue = DispatchQueue(label: "eeeeeee");
        
        queue.async {
            print("connect current thread : \(Thread.current) label: \(queue.label)");
            //            Thread.sleep(forTimeInterval: 2)
            
            Thread.sleep(forTimeInterval: 2)
            DispatchQueue.main.async(execute: {
                
                
                print("connect finished unlock: \(Thread.current)");
                
                self.queueGroup.leave()
//                self.lock.signal();

            })
            
        }
    }
    
    func startPreview(count: NSInteger){
        
        let queue = DispatchQueue(label: "rrrrrrr");
        queue.async {
            let _ = self.queueGroup.wait(timeout: DispatchTime.distantFuture)
//            let _ = self.lock.wait(timeout: DispatchTime.distantFuture)
            print("startPreview task run :\(queue.label) count: \(count)");
            Thread.sleep(forTimeInterval: 2)
            DispatchQueue.main.async(execute: {
                print("startPreview task run on main------count: \(count)");
            })

        }

        
        
    }

    
}
