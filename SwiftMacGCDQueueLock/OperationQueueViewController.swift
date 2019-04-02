//
//  OperationQueueViewController.swift
//  SwiftMacGCDQueueLock
//
//  Created by cb_2018 on 2019/4/2.
//  Copyright © 2019 cfwf. All rights reserved.
//

import Cocoa
import CoreFoundation

//OperationQueue的属性
//open class OperaitonQueue: OperationQueue{
    //增加操作任务到队列
//    func addOperation(_ op: Operaiton);
    //增加多个操作任务到队列
//    func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool)
    //增加基于闭包块定义的操作任务队列
//    func addOperation(_ block: @escaping () -> Void)
    //队列所有的操作任务
//    var operations: [Operation] {get}
    //所有操作任务操作个数
//    var operstionCount: Int {get}
    //最大允许的并发数，设置为1时等价于GCD的串行分发队列，大于1时相当于并发队列
//    var maxConcurrentOperationCount: Int
    //队列挂起状态
//    var isSuspended: Bool
    //队列名称
//    var name: String?
    //队列服务质量
//    var qualityOfService: QualityOfService
    //队列对应的底层GCD的队列，从这里可以印证NSOperaitonQueue在GCD基础上做了封装
//    unowned(unsafe) open var underlyingQueue: DispatchQueue? /actually retain/
    //取消所有任务
    //func cancelAllOperations()
    //等待所有任务完成
//    func waitUntilAllOperationsAreFinished()
    //获取当前正在执行的任务队列
//    var current: OperationQueue? {get}
    //获取当前的主线程分发队列
//    var main: OperationQueue {get}
//}
class OperationQueueViewController: NSViewController {
	
    convenience init() {
        self.init()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    	
    }
    func OperationBlockTask() {
        let opt = BlockOperation()
        opt.addExecutionBlock {
            print("Run in block 1")
        }
        opt.addExecutionBlock {
            print("Run in block 2")
        }
        opt.addExecutionBlock {
            print("Run in block 3")
        }
        opt.addExecutionBlock {
            print("Run in block 4")
        }
        OperationQueue.current!.addOperation(opt)
        //执行结果无顺序
    }
    
    let leftImageView: NSImageView! = nil
    //使用HTTPImageOpersiotn类下载网络图片
    func downLoadTask() {
        let url1 = URL(string: "http://www.imag1.png")
        //新建操作任务
        let op1 = HTTPImageOpersiton(imageURL: url1)
        op1.downCompetionBlock = {(_ image: NSImage?) -> () in
            if let img = image {
                self.leftImageView.image = img
            }
        }
        OperationQueue.main.addOperation(op1)
    }
    
    //设置任务间的依赖
    func dependencyTask() {
        let aQueue = OperationQueue()
        let opt1 = BlockOperation()
        opt1.addExecutionBlock {
            print("run in block 1")
        }
        let opt2 = BlockOperation()
        opt2.addExecutionBlock {
            print("run in block 2")
        }
        opt2.addDependency(opt1)
        aQueue.addOperation(opt1)
        aQueue.addOperation(opt2)
        //1 2
        //设置Operation执行完的回调
        opt1.completionBlock = {
            print("run all Block opreation")
        }
        //取消单个操作
        opt2.cancel()
        //取消queue中所有的操作
        OperationQueue.current?.cancelAllOperations()
        
        //暂停或回复队列的执行
        //暂停执行
        OperationQueue.current?.isSuspended = true
        //回复执行
        OperationQueue.current?.isSuspended = false
    }
    
    //执行任务的优先级
    func prepertyTask() {
        let aQueue = OperationQueue()
        let opt1 = BlockOperation()
        opt1.queuePriority = .veryLow
        opt1.addExecutionBlock {
            print("run in block 1")
        }
        let opt2 = BlockOperation()
        opt2.queuePriority = .veryLow
        opt2.addExecutionBlock {
            print("run in block 2")
        }
        let opt3 = BlockOperation()
        opt3.queuePriority = .veryHigh
        opt3.addExecutionBlock {
            print("run in block 3")
        }
        aQueue.addOperations([opt1,opt2,opt3], waitUntilFinished: false)
    }
    
}


/***
 *Operaiton是一个抽象类 其子线程的几个关键方法
 *是否允许并发执行
 *var isAsynchronous: Bool {get}
 *kvo属性方法，表示任务执行状态
 *var isExecuting: Bool {get}
 *kvo属性方法，表示任务是否执行完成
 *var isFinished: Bool {get}
 *任务启动前的方法，满足执行条件时，启动线程执行main方法
 *func start()
 *实现具体的任务逻辑
 *func mian()
 **/
typealias DownCompletionBlock = (_ image: NSImage?) -> ()
class HTTPImageOpersiton: Operation {
    var url: URL!
    var downCompetionBlock : DownCompletionBlock?
    var _executing = false
    var _finished = false
    
    deinit {
        
    }
    override init() {
        super.init()
    }
    convenience init(imageURL url: URL?) {
        self.init()
        self.url = url!
    }
    
    //表示是否允许并发
    override var isAsynchronous: Bool {
        return true;
    }
    override var isExecuting: Bool{
        return _executing
    }
    override var isFinished: Bool{
        return _finished
    }
    override func start() {
        if self.isCancelled {
            self.willChangeValue(forKey: "isFinished")
            _finished = true
            self.didChangeValue(forKey: "isFinished")
            return
        }
        self.willChangeValue(forKey: "isExecuting")
        Thread.detachNewThreadSelector(#selector(self.main), toTarget: self, with: nil)
        _executing = true
        self.didChangeValue(forKey: "sExecuting")
    }
    func complete() {
        self.willChangeValue(forKey: "isFinished")
        self.willChangeValue(forKey: "isExecuting")
        _executing = false
        _finished = true
        self.didChangeValue(forKey: "isExecuting")
        self.didChangeValue(forKey: "isFinished")
    }
    override func main() {
        let image = NSImage(contentsOf: self.url)
        if let callback = self.downCompetionBlock {
            callback(image)
        }
        self.complete()
    }
}
