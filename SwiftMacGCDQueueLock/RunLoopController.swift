//
//  RunLoopController.swift
//  SwiftMacGCDQueueLock
//
//  Created by cb_2018 on 2019/4/2.
//  Copyright © 2019 cfwf. All rights reserved.
//

import Cocoa
/****
 *RunLoopModel中属性
 *connectionReplay-Mode系统内部监控NSConection
 *defalutRunLoopModel
 *commonModes
 *modelPaneRunLoopMode
 *eventTrackingRunLoopMode 键盘外设 触控
 ***/
class RunLoopController: NSViewController {

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init() {
        self.init()
        
    }

    var timer: Timer?
    var timeCount: Int32 = 100
    override func viewDidLoad() {
        super.viewDidLoad()
//        //获取runloop
//        let runLoop = RunLoop.current
//        let runLoop2 = CFRunLoopGetCurrent
//        CFRunLoopStop(runLoop as! CFRunLoop)
//        CFRunLoopStop(CFRunLoopGetCurrent())
//        //
//        runLoop.run()
//        runLoop.run(until: Date())
//        runLoop.run(mode: RunLoop.Mode, before: Date) -> Bool
        
        //设置time的mode为Common 防止其他高优先级Mode事件影响定时器的运行
        timer = Timer(timeInterval: 1, target: self, selector:#selector(self.doFireTimer), userInfo: nil, repeats: true)
    }
    @objc func doFireTimer() {
        if timeCount <= 0 {
            return
        }
        timeCount -= 1
        //赋值UI
    }
    //GCDTimer不受界面滑动的影响
    var gcdTimer: DispatchSourceTimer?
    func gcdTimerTest() {
        gcdTimer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags.init(rawValue: 1), queue: DispatchQueue.main)
        gcdTimer?.setEventHandler(handler: {
            //定时器
            print("timer out")
        })
        //配置为重复执行的定时器
        gcdTimer?.scheduleRepeating(deadline: .now() + 1, interval: 1)
        //单次定时
        gcdTimer?.scheduleOneshot(deadline: .now() + 1)
        //启动定时器
        gcdTimer?.resume()
    }
    
    func addRunLoopObserver() {
        var _self = self
        //定义观察者的context
        var observerContext = CFRunLoopObserverContext(version: 0, info: &_self, retain: nil, release: nil, copyDescription: nil)
        //创建观察者
        let observer = CFRunLoopObserverCreate(kCFAllocatorDefault, CFRunLoopActivity.allActivities.rawValue, true, 0, self.observerCallBackFunc(), &observerContext)
        if observer != nil {
            //增加当前RunLoop观察者
            CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, CFRunLoopMode.defaultMode)
        }
    }
    //观察者的状态回调s函数
    func observerCallBackFunc() -> CFRunLoopObserverCallBack {
        return {(observer, activity, context) -> Void in
            switch activity {
            case CFRunLoopActivity.entry:	//开始进入
                print("RunLoop entry")
                break
            case CFRunLoopActivity.beforeTimers:  //定时器即将到时
                print("RunLoop beforeTimers")
                break
            case CFRunLoopActivity.beforeSources: //原事件即将触发
                print("RunLoop beforeSources")
                break
            case CFRunLoopActivity.beforeWaiting: //即将进入休眠
                print("RunLoop beforeWaiting")
                break
            case CFRunLoopActivity.afterWaiting: //即将唤醒
                print("RunLoop afterWaiting")
                break
            case CFRunLoopActivity.exit: 			//退出
                print("RunLoop exit")
                break
            case CFRunLoopActivity.allActivities: //所有活动状态
                print("RunLoop allActivities")
                break
            default:
                break
            }
        }
    }
    
}
