//
//  ViewController.swift
//  ContinuTimer
//
//  Created by 首藤典宏 on 2015/05/31.
//  Copyright (c) 2015年 首藤典宏. All rights reserved.
//

import UIKit
import AVFoundation
import iAd

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, AVAudioPlayerDelegate, AVAudioRecorderDelegate{
    
    let timePicker : UIPickerView = UIPickerView()
    let timeLbl = UILabel()
    let startBtn = UIButton()
    let pauseBtn = UIButton()
    var displayLink : CADisplayLink?
    
    // timer
    let times : NSArray = [13, 1, 60, 1, 60, 1]
    var hh12Arr = ["00"]
    var mm60Arr = ["00"]
    
    // totalTime
    var totalTime : Double = 0.0
    var tempTotalTime : Double = 0
    
    // Notification Time
    var enterBackgroundTime = NSDate().timeIntervalSince1970
    var enterForegroundTime = NSDate().timeIntervalSince1970
    
    // flag
    var startFlag = false
    var finishFlag = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enterBackground:", name:"applicationDidEnterBackground", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enterForeground:", name:"applicationWillEnterForeground", object: nil)
        
        // Logic
        makePickerTitle(hh12Arr, mmArr: mm60Arr)
        
        // View
        cleateTimePicker()
        cleateStartBtn()
        cleateTimeLbl()
        cleatePauseBtn()
        
        // iAd(バナー)の自動表示
        self.canDisplayBannerAds = true
    }
    
    // background enter 通知
    func enterBackground(notification: NSNotification){
        enterBackgroundTime = NSDate().timeIntervalSince1970
        
        // カウントダウン中は通知設定
        if (!finishFlag && startFlag){
            let notification = UILocalNotification()
            notification.fireDate = NSDate(timeIntervalSinceNow: totalTime)
            notification.timeZone = NSTimeZone.defaultTimeZone()
            notification.alertBody = "終わりの時間だよ"
            
            //            notification.soundName = "popopo01.mp3"
            notification.soundName = UILocalNotificationDefaultSoundName
            
            UIApplication.sharedApplication().scheduleLocalNotification(notification);
        }
        
        //        println(date)
        //        println(totalTime)
    }
    
    // foreground enter 通知
    func enterForeground(notification: NSNotification){
        //        println("applicationWillEnterForeground")
        enterForegroundTime = NSDate().timeIntervalSince1970
        if let disInit = displayLink?.paused {
            if (!displayLink!.paused){
                finishFlag ?
                    (totalTime += (enterForegroundTime - enterBackgroundTime))
                    : (totalTime -= (enterForegroundTime - enterBackgroundTime))
                if (totalTime > 60 * 60 * 12){
                    totalTime = 0
                }
            }
        }
        
        let total = 60 * 60 * 12
        
        // 通知全削除
        UIApplication.sharedApplication().cancelAllLocalNotifications();
        
    }
    
    func cleateTimeLbl(){
        timeLbl.frame = CGRectMake(view.bounds.width * 0.1, view.bounds.height * 0.3, view.bounds.width * 0.8, view.bounds.height * 0.2)
        timeLbl.font = UIFont.systemFontOfSize(130)
        timeLbl.text = "00:00:00.00"
        
        view.addSubview(timeLbl)
        
        timeLbl.hidden = true
    }
    
    func cleatePauseBtn(){
        pauseBtn.frame = CGRectMake(view.frame.width * 0.1, view.frame.height * 0.7, 300, 200)
        pauseBtn.backgroundColor = UIColor.redColor()
        pauseBtn.setTitle("Pause", forState: [])
        pauseBtn.titleLabel?.font = UIFont.systemFontOfSize(60)
        pauseBtn.layer.masksToBounds = true
        pauseBtn.layer.cornerRadius = 20.0
        self.view.addSubview(pauseBtn)
        
        pauseBtn.addTarget(self, action: "pushPauseBtn", forControlEvents: .TouchUpInside)
    }
    
    func pushPauseBtn(){
        if (!startFlag){
            return
        }
        
        // 一時停止、再開切り替え
        displayLink!.paused = !displayLink!.paused
        if (displayLink!.paused){
            pauseBtn.setTitle("Restart", forState: [])
        } else {
            pauseBtn.setTitle("Pause", forState: [])
        }
    }
    
    func cleateStartBtn(){
        startBtn.frame = CGRectMake(view.bounds.width * 0.5, view.bounds.height * 0.7, 300, 200)
        startBtn.backgroundColor = UIColor.redColor()
        startBtn.setTitle("Start", forState: [])
        startBtn.titleLabel?.font = UIFont.systemFontOfSize(60)
        startBtn.layer.masksToBounds = true
        startBtn.layer.cornerRadius = 20.0
        self.view.addSubview(startBtn)
        
        startBtn.addTarget(self, action: "pushStartBtn", forControlEvents: .TouchUpInside)
    }
    
    func pushStartBtn(){
        if(totalTime == 0){
            return
        }
        
        // start,stop切り替え
        startFlag = !startFlag
        
        // Start押下
        // Stop押下
        if (startFlag){
            startBtn.setTitle("Stop", forState: [])
            
            timePicker.hidden = true
            timeLbl.hidden = false
            
            totalTime = tempTotalTime
            startTimer()
        } else {
            startBtn.setTitle("Start", forState: [])
            pauseBtn.setTitle("Pause", forState: [])
            
            timePicker.hidden = false
            timeLbl.hidden = true
            displayLink!.invalidate()
            
            finishFlag = false
        }
    }
    
    func startTimer(){
        displayLink = CADisplayLink(target: self, selector: "update:")
        displayLink!.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    func update(displayLink: CADisplayLink){
        if (totalTime <= 0) {
            finishFlag = true
            displayEndAlert()
            endSound()
            
            totalTime *= -1
        }
        
        if (totalTime >= 60 * 60 * 13){
            totalTime = 0
        }
        
        if (finishFlag){
            totalTime += Double(displayLink.duration)
        } else {
            totalTime -= Double(displayLink.duration)
        }
        
        let hh = totalTime / (60 * 60)
        let mm = (totalTime / 60) % 60
        let ss = totalTime % 60
        let ms = (totalTime - floor(totalTime)) * 10
        
        timeLbl.text = NSString(format: "%02d:%02d:%02d.%01d", Int(hh), Int(mm), Int(ss), Int(ms)) as String
        //        println(displayLink.duration)
    }
    
    func makePickerTitle(hhArr: NSArray, mmArr: NSArray){
        // 00,1...12mathMake
        for i in 1...12 {
            hh12Arr.append(String(i))
        }
        
        // 00,1...59mathMake
        for i in 1...59 {
            mm60Arr.append(String(i))
        }
    }
    
    func cleateTimePicker(){
        timePicker.delegate = self
        timePicker.dataSource = self
        timePicker.frame = CGRectMake(view.bounds.width * 0.1, view.bounds.height * 0.3, view.bounds.width * 0.8, view.bounds.height * 0.8)
        timePicker.showsSelectionIndicator = true
        
        view.addSubview(timePicker)
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return times.count
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return times[component] as! Int
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        switch component {
        case 0:
            return hh12Arr[row] as String
        case 1:
            return "時間"
        case 2:
            return mm60Arr[row] as String
        case 3:
            return "分"
        case 4:
            return mm60Arr[row] as String
        case 5:
            return "秒"
        default:
            return "0"
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let hhInt = pickerView.selectedRowInComponent(0) as Int
        let mmInt = pickerView.selectedRowInComponent(2) as Int
        let ssInt = pickerView.selectedRowInComponent(4) as Int
        
        totalTime = Double((hhInt * 60 * 60) + (mmInt * 60) + ssInt)
        tempTotalTime = totalTime
    }
    
    func displayEndAlert(){
        let endAlert = UIAlertView(title: "終了", message: "時間だよ", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "OK")
        
        endAlert.show()
    }
    
    func endSound(){
        AudioServicesPlaySystemSound(1304)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
