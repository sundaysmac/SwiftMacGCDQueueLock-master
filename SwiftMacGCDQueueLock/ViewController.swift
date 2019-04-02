//
//  ViewController.swift
//  SwiftMacGCDQueueLock
//
//  Created by cb_2018 on 2019/4/2.
//  Copyright © 2019 cfwf. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

//    public static let userInitiated: DispatchQoS
//    public static let 'default': DispatchQoS
//    public static let utility: DispatchQoS
//    public static let background: DispatchQoS
    //根据优先级获取队列
    let queue4 = DispatchQueue.global(qos: .userInitiated)
    //创建串行分发队列
    let queue1 = DispatchQueue(label: "macdev.io.exam")	//创建私有
    let main = DispatchQueue.main	//获取主线程分发队列
    //创建并行分发队列
    let queue = DispatchQueue(label: "macdev.io.exam", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //延时执行
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            print("do some work after 3s!")
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
	//添加异步任务到队列
    func asyncTask() {
        let queue = DispatchQueue(label: "macdev.io.exam")
        queue.async {
            print("1do some tasks")
        }
        print("2")
        //2 1
    }
    //添加同步队列
    func syncTask() {
        let queue = DispatchQueue(label: "name")
        queue.sync {
            print("1")
        }
        queue.sync {
            print("2")
        }
        print("3")
        // 1 2 3
    }
	//线程切换 执行完成后将计算结果或状态通知到主线程或其他队列进异步处理
    func singleTask() {
        let textFiled = NSTextField.init()
        let queue = DispatchQueue(label: "name")
        queue.async {
            var sum = 0
            for i in 1...10 {
                sum += i
            }
            DispatchQueue.main.async {
                //更新计算过
                textFiled.integerValue = sum
            }
        }
    }
    //多线程组
    func groupTask() {
        let group = DispatchGroup() //创建组
        let queue = DispatchQueue(label: "name")
        queue.async {
            print("do work 1 here")
        }
        queue.async {
            print("do work 2 here")
        }
        //创建一个任务
        let workItem = DispatchWorkItem(qos: .userInitiated, flags: .assignCurrentContext) {
            print("3group comlete")
        }
        group.notify(queue: queue, work: workItem)
        // 1 2 3
    }
    //动态控制组任务 多个网络请求完成后进行统一UI更新
    //发起前调用 dispatch_group_enter(group)  接收后调用dispatch_group_leave(group)
    let kServerBaseUrl = "http:www.iosxhelper.com/SAPI"
    func groupEnterLeaveTask() {
        let group = DispatchGroup()
        let httpClient = HTTPClient()
        let urlString = "\(kServerBaseUrl)\("/VersionCheck")"
        let url = URL(string: urlString)
        group.enter()
        httpClient.get(url!, parameters: nil, success: { (responseObject: Any?) ->Void in
            print("1 first get data = \(responseObject)")
            group.leave()
        }) { (error: Error?) -> Void in
            
        }
        
        group.enter()
        httpClient.get(url!, parameters: nil, success: { (responseObject: Any?) ->Void in
            print("2 first get data = \(responseObject)")
            group.leave()
        }) { (error: Error?) -> Void in
            
        }
        let workItem = DispatchWorkItem(qos: .userInitiated, flags: .assignCurrentContext) {
            print("3group complete")
        }
        group.notify(queue: DispatchQueue.main, work: workItem)
        // 1 2 3
    }
    
    //优化循环性能 dispatch_apply
    func gcdapply() {
        for i in 0..<10 {
            print("ad\(i)")
        }
        //优化
        DispatchQueue.concurrentPerform(iterations: 2) { (i) in
            print("i")
        }
    }
    
    let queue_sus_resum = DispatchQueue(label: "quene.name")
    //任务暂停和唤醒
    func suspendQueue() {
        queue_sus_resum.suspend()
    }
    func resumeQueue() {
        queue_sus_resum.resume()
    }
    
    //使用信号量控制首先资源
    //初始化信号量
    var semahore = DispatchSemaphore(value: 10)
    @IBAction func waitAction(_ sender: AnyObject){
        self.queue.async {
            self.semahore.wait()
            print("begin work!")
        }
    }
    @IBAction func signalAciton(_ sender: AnyObject){
        semahore.signal()
    }
    
    //使用barrier控制并发任务
    func barrierControlTask() {
        let queue = DispatchQueue(label: "myBackgroundQueue", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        queue.async {
            print("Do some work 1 here")
        }
        queue.async {
            print("Do some work 2 here")
        }
        queue.async {
            print("Do some work 3 here")
        }
        queue.async(flags: .barrier) {
            print("do some barrire 4")
        }
        queue.async {
            print("Do some work 5 here")
        }
        //(231不定)  、定顺序4 5
    }
    
}

//MARK:- HTTPClient工具类的实现
typealias HTTPSesionDataTaskCompetionBlock = (_ response: URLResponse?, _ responseObject: Any?, _ error: Error) -> ()
class HTTPClientSessionDelegate: NSObject, URLSessionDataDelegate {
    var taskCompletionHandler: HTTPSesionDataTaskCompetionBlock?
    var buffer: Data = Data()
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        //缓存接收到的数据
        self.buffer.append(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let responseStr = String(data: self.buffer, encoding: String.Encoding.utf8)
        print("didReceive data =\(String(describing: responseStr))")
        if let callback = taskCompletionHandler {
            callback(task.response,responseStr,error!)
        }
        //释放session资源
        session.finishTasksAndInvalidate()
    }
}
//HTTPClient类 定义外部访问接口GET/POST,穿件URLSessionDataTask任务实例，实现代理功能路由到具体的协议代理处理类
class HTTPClient: NSObject {
    var sessionConfiguration = URLSessionConfiguration.default
    lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    lazy var session: URLSession = {
        return URLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue: self.operationQueue)
    }()
    
    //代理缓存
    var taskDelegates = [AnyHashable: HTTPClientSessionDelegate?]()
    //资源保护锁
    var lock = NSLock()
    
    func get(_ url: URL, parameters: Any?, success:@escaping (_ responseData: Any) -> Void,failure:@escaping (_ error: Error?) -> Void) {
        var request: URLRequest
        let postStr = self.formatParas(paras: parameters!)
        if let paras = postStr {
            let baseURLString = url.path + "?" + paras
            request = URLRequest(url: URL(string: baseURLString)!)
        }
        else
        {
            request = URLRequest(url: url)
        }
        let task = self.dataTask(with: request, success: success, failure: failure)
        task.resume()
    }
    
    func post(_ url: URL, parameters: Any?, success: @escaping(_ responseData: Any?) -> Void, failure: @escaping(_ error: Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postStr = self.formatParas(paras: parameters!)
        if let str = postStr {
            let postData = str.data(using: String.Encoding.utf8)!
            request.httpBody = postData
        }
        let task = self.dataTask(with: request, success: success, failure: failure)
        task.resume()
    }
    //参数格式化
    func formatParas(paras parameters: Any) -> String? {
        var postStr: String?
        if (parameters is String) {
            postStr = parameters as? String
        }
        if (parameters is [AnyHashable: Any]) {
            let keyValues = parameters as! [AnyHashable: Any]
            var tempStr = String()
            var index = 0
            for(key, obj) in keyValues {
                if index > 0 {
                    tempStr += "&"
                }
                let kv = "\(key)=\(obj)"
                tempStr += kv
                index += 1
            }
            postStr = tempStr
        }
        return postStr
    }
    
    func add(_ completionHandler: @escaping HTTPSesionDataTaskCompetionBlock, for task: URLSessionDataTask) {
        let sessionDelegate = HTTPClientSessionDelegate()
        sessionDelegate.taskCompletionHandler = completionHandler
        self.lock.lock()
        self.taskDelegates[(task.taskIdentifier)] = sessionDelegate
        self.lock.unlock()
    }
    
    func dataTask(with request: URLRequest, success: @escaping(_ responseData: Any?) -> Void,failure: @escaping(_ error: Error?) -> Void) -> URLSessionDataTask {
        let dataTask = self.session.dataTask(with: request)
        let complectionHandler = {
            (response: URLResponse?, responseObject: Any?, error: Error?) -> (Void) in
            if error != nil {
                failure(error)
            }
            else
            {
                success(responseObject)
            }
            
        }
        self.add(complectionHandler, for:dataTask)
        return dataTask
    }
}
//代理协议
extension HTTPClient: URLSessionDataDelegate {
    //数据接收
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let sessionDelegate = self.taskDelegates[(dataTask.taskIdentifier)]
        if let delegate = sessionDelegate {
            delegate?.urlSession(session, dataTask: dataTask, didReceive: data)
        }
    }
    //请求完成的
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let sessionDelegate = self.taskDelegates[(task.taskIdentifier)]
        if let delegate = sessionDelegate {
            delegate?.urlSession(session, task: task, didCompleteWithError: error)
        }
    }
}




//MARK:- gcd的使用
class MyObject: NSObject {
    private var internalState: Int
    private let queue:DispatchQueue
    override init() {
        queue = DispatchQueue(label: "queue.name")
        internalState = 0
        super.init()
    }
    var state: Int {
        get {
            return queue.sync { internalState }
        }
        set (newState) {
            queue.sync {
                internalState = newState
            }
        }
    }
}
//防止线程死锁
class MyCalss {
    var interface: String?
    var key = DispatchSpecificKey<Void>()
    lazy var queue: DispatchQueue = {
        let queue = DispatchQueue(label: "queue.name")
        queue.setSpecific(key: self.key, value: ())
        return queue
    }()
    func readInterface() -> String? {
        var result: String?
        if DispatchQueue.getSpecific(key: self.key) != nil {
            //已经是当前队列，则直接返回值
            return self.interface
        }
        self.queue.sync {
            result = self.interface
        }
        return result
    }
    
    func updateInterface(_ newInterface: String?) {
        let value = newInterface
        self.queue.sync {
            self.interface = value
        }
    }
}
