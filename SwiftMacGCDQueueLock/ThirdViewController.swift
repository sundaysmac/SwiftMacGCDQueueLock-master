//
//  ThirdViewController.swift
//  SwiftMacGCDQueueLock
//
//  Created by cb_2018 on 2019/4/2.
//  Copyright © 2019 cfwf. All rights reserved.
//

import Cocoa
/***
 *获取当前运行的线程
 *class var current: Thread {get}
 *是否支持多线程
 *class func isMultiTreaded() -> Bool
 *是否是主线程的属性
 *var isMainThread: Bool {get}
 *获取主线程
 *calss var main: Thread {get}
 *线程的配置参数属性和方法如下
 *线程的local数据字典
 *var threadDictionary: NSMutableDictionary {get}
 *线程优先级
 *class func threadPriority() -> Double
 *修改优先级
 *class func setThreadPriority(_ p: Double) ->Bool
 *线程服务质量
 *var qualityOfService: QualityOfService
 *线程名称
 *var name: String?
 *栈大小
 *var stackSize: Int
 **********************
 *线程执行的各种状态属性参数
 *是否正在执行
 *var isExecuting: Bool {get}
 *是否完成
 *var isFinished: Bool {get}
 *是否取消
 *var isCancelled: Bool {get}
 ********线程的控制方法
 *取消执行
 *func cancel()
 *启动执行
 *func start
 *线程执行的主方法，子类化线程实现这个方法即可
 *func main()
 *休眠到制定日期
 *class func sleep(until date: Date)
 *定期休眠
 *class fund sleep(forTimeInterval ti:TimeInterval)
 *退出线程
 *class func exit()
 */
class ThirdViewController: NSViewController {
	/***
     *Thread是底层pthread线程的封装，提供更多的灵活性
     *可以设置线程的服务质量
     *可以设置线程栈大小
     *线程提供local数据字典，可以存储键/值数据
     *其优势  实时性高  与RunLoop结合，提供更为灵活高效的线程管理方式
     *缺点  创建线程代价较大，需要同时占有应用和内核内存
     **/
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
//    1startTread创建线程
    func startThread() {
        Thread.detachNewThreadSelector(#selector(self.compulterSum), toTarget: self, with: nil)
    }
    @objc func compulterSum() {
        var sum = 0
        for i in 0..<10 {
            sum += i
        }
        print("sum")
    }
    
    //2.直接使用Thread创建
    func createThread() {
        let thread = Thread(target: self, selector: #selector(self.compulterSum), object: nil)
        thread.name = "ThreadName1"
        thread.start()
    }
    ////////////4.线程中共享资源保护
    func shareTask() {
        let count = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        count.pointee = 2
        OSAtomicIncrement32(count)
        print("var =\(count)")
        OSAtomicDecrement32(count)
        print("var = \(count)")
    }
    /////枷锁
    func lockTask() {
        let lock = NSLock()
        if lock.try() {
            //do some work
            
            //释放资源
            lock.unlock()
        }
    }
    /////递归锁NSRecursiveLock主要用在循环和递归中，保证同一线程多次枷锁操作不产生死锁
    //在同一个类中多个方法，递归操作，循环处理中对受保护资源的访问
    func recursiveTask() {
        let theLock = NSRecursiveLock()
        for i in 0..<10 {
            theLock.lock()
            //do some work
            theLock.unlock()
        }
    }
    
}

//3. 子类化Thread 封装成Thread的子类进行独立处理，完成的结果可以通知或代理通知到主线程
//通过重载main方法实现子类化，加上autoreleasepool自动释放池,确保线程中国及时释放
protocol ImageDownloaddelegate :class {
    func didFinishDown(_ image: NSImage?)
}

class WrokThread: Thread {
    var url: URL!
    weak var delegate: ImageDownloaddelegate?
    convenience init(imageURL url: URL?) {
        self.init()
        self.url = url!
    }
    override func main() {
        print("start main")
        autoreleasepool {
            let image = NSImage(contentsOf: url)
            if let downloadDelegate = delegate {
                downloadDelegate.didFinishDown(image)
                print("end mian")
            }
        }
    }
}




//5//NSConditionLock条件锁
//condition为一个整数参数，满足条件时获得锁，解锁时可以设置condition条件
//lock、lockWhenCondition与unlock、unlockWhenCondition可以任意组合
class NSConditionLockTest: NSObject {
    lazy var condition : NSConditionLock = {
        let c = NSConditionLock()
        return c
    }()
    
    var queue = [String]()
    
    @objc func doWork1() {
        print("work1 begin")
        while true {
            sleep(1)
            self.condition.lock()
            print("do lock work 1")
            self.queue.append("a1")
            self.queue.append("a2")
            self.condition.unlock(withCondition: 2)
        }
        print("doWork1 end")
    }
    
    @objc func doWork2() {
        print("work2 begin")
        while true {
            sleep(1)
            self.condition.lock(whenCondition: 2)
            print("do lock work 2")
            self.queue.removeAll()
            self.condition.unlock()
        }
        print("doWork1 end")
    }
    
    func doWrok() {
        self.performSelector(inBackground: #selector(self.doWork1), with: nil)
        self.perform(#selector(self.doWork2), with: nil, afterDelay: 1)
    }
}

/*****
*6 NSCondition 通过一些条件控制多个线程协作完成任务，当条件不满足时线程等待，条件满足时通过
*发送signal信号来通知等待的线程继续处理
 **/
class NSConditionTest: NSObject {
    var completed = false
    lazy var condition: NSCondition = {
        let c = NSCondition()
        return c
    }()
    func clearCondition() {
        self.completed = false
    }
    @objc func doWork1() {
    	print("doWork1 Begin")
        self.condition.lock()
        while !self.completed {
            self.condition.wait()
        }
        print("doWork1 End")
        self.condition.unlock()
    }
    @objc func doWork2() {
        print("doWork2 Begin")
        //do somework
        self.condition.lock()
        self.completed = true
        self.condition.signal()
        self.condition.unlock()
        print("doWork2 End")
        self.condition.unlock()
    }
    
    func doWork() {
        self.performSelector(inBackground: #selector(self.doWork1), with: nil)
        self.perform(#selector(self.doWork2), with: nil, afterDelay: 1)
    }
    /***
     *doWork1 begin
     *doWork2 begin
     *doWork2 end
     *doWork1 end
     **/
}
