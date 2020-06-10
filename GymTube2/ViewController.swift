//
//  ViewController.swift
//  GymTube2
//
//  Created by FumikoYamamoto on 2020/06/05.
//  Copyright © 2020 FumikoYamamoto. All rights reserved.
//

import UIKit
import YouTubePlayer
import CoreMotion
import Instructions


class ViewController: UIViewController, YouTubePlayerDelegate, UITextFieldDelegate {
    
    // MotionManager
    let motionManager = CMMotionManager()
    //0がゲーム始まる前、1が始まったあと
    var isWorking = 0
    //0が縦、1が横
    var screenDirection = 0
    // 3 axes 縦：X0,Y1のときが姿勢良いとする / 横：X-1,Y0のときが姿勢良いとする
    @IBOutlet var accelerometerX: UILabel!
    @IBOutlet var accelerometerY: UILabel!
    
    var videoIDString = "FjL-8gvdXTQ"
    //https://youtu.be/FjL-8gvdXTQ
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var returnURLButton: UIButton!
    
    @IBOutlet var playerView: YouTubePlayerView!
    
    @IBOutlet var judgeLabel: UILabel!
    @IBOutlet weak var inputURLField: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    //for a tutorial
    let coachMarksController = CoachMarksController()
    //pointOfInterestが指し示されます。スポットライトが当たるみたいに
    private var pointOfInterest:UIView!
    
    @IBAction func tapPlay(_ sender: Any) {
        
        self.playerView.playerVars = ["playsinline": 1 as AnyObject, "autohide": 1 as AnyObject, "autoplay": 1 as AnyObject]
        self.playerView.play()
        
        isWorking = 1
        judgeLabel.isHidden = false
        startButton.isHidden = true
        }
        @IBAction func tapPause(_ sender: Any){
            self.playerView.pause()
        }
        @IBAction func tapStop(_ sender: Any){
            self.playerView.stop()
        }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        let videoURL = NSURL(string: "https://www.youtube.com/watch?v=wQg3bXrVLtg")
        
        self.inputURLField.delegate = self
        
        startButton.layer.cornerRadius = 10.0
        startButton.layer.borderColor = UIColor.white.cgColor
        startButton.layer.borderWidth = 0.5
        
        
        returnURLButton.setTitle("🔍", for: .normal)
        returnURLButton.backgroundColor = UIColor.white
        returnURLButton.layer.cornerRadius = 3.0
        errorMessageLabel.isHidden = true
        
        judgeLabel.isHidden = true
        playerView.delegate = self;
        
        playerView.loadVideoID(videoIDString)
        self.playerView.playerVars = ["playsinline": 1 as AnyObject, "autohide": 1 as AnyObject, "autoplay": 1 as AnyObject]
        
        if motionManager.isAccelerometerAvailable {
            // intervalの設定 [sec]
            motionManager.accelerometerUpdateInterval = 0.5 //何秒に一回呼び出すか
            // センサー値の取得開始
            motionManager.startAccelerometerUpdates(
                to: OperationQueue.current!,
                withHandler: {(accelData: CMAccelerometerData?, errorOC: Error?) in
                        self.outputAccelData(acceleration: accelData!.acceleration)
                   })
        }
        
        //for a tutorial
        self.coachMarksController.dataSource = self
        self.pointOfInterest = self.playerView
        self.coachMarksController.overlay.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
    }
    
    @IBAction func tapReturn(_ sender: UIButton) {
            //検索ボタン
            inputURLField.endEditing(true)
            
            if inputURLField.text!.count == 28 {
                errorMessageLabel.isHidden = true
                
                let videoideoURL: String = inputURLField.text!
                videoIDString = String(videoideoURL.suffix(11))
                
                isWorking = 1
                judgeLabel.isHidden = false
                startButton.isHidden = true
                screenDirection = 0
                
                playerView.loadVideoID(videoIDString)
                self.playerView.playerVars = ["playsinline": 1 as AnyObject, "autohide": 1 as AnyObject, "autoplay": 1 as AnyObject]
                playerView.play()
 
 
            } else {
                errorMessageLabel.isHidden = false
            }
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            // 改行をタップでキーボードを消す
            textField.resignFirstResponder()
            return true
        }
        
        override func viewDidAppear(_ animated: Bool) {
            
            super.viewDidAppear(animated)
                    
            //初回起動判定
            let ud = UserDefaults.standard
            if ud.bool(forKey: "firstLaunch") {
            // 初回起動時の処理 tutorialを再生
            self.coachMarksController.start(in: .currentWindow(of: self))
            // 2回目以降の起動では「firstLaunch」のkeyをfalseに
            ud.set(false, forKey: "firstLaunch")
            }
            
            
            // 画面回転を検知
            NotificationCenter.default.addObserver(self,
                                                   selector:#selector(didChangeOrientation(_:)),
                                                   name: UIDevice.orientationDidChangeNotification,
                                                   object: nil)
        }
         
        @objc private func didChangeOrientation(_ notification: Notification) {
            //画面回転時の処理
            //0が縦、1が横
            switch screenDirection {
            case 0:
                screenDirection = 1
                
                playerView.loadVideoID(videoIDString)
                self.playerView.playerVars = ["playsinline": 0 as AnyObject, "autohide": 1 as AnyObject, "autoplay": 1 as AnyObject]
                                
            case 1:
                screenDirection = 0
                
                playerView.loadVideoID(videoIDString)
                self.playerView.playerVars = ["playsinline": 1 as AnyObject, "autohide": 1 as AnyObject, "autoplay": 1 as AnyObject]
            default:
                break
            }
        }
        

        func outputAccelData(acceleration: CMAcceleration){
                // 加速度センサー [G]
                accelerometerX.text = String(format: "x= %0.1f", acceleration.x)
                accelerometerY.text = String(format: "y= %0.1f", acceleration.y)
    //            accelerometerZ.text = String(format: "%0.1f", acceleration.z)

            switch screenDirection {
            case 0:
                //縦
                if (acceleration.x >= -0.05 && acceleration.x <= 0.05 && acceleration.y <= -0.95 && isWorking == 1){
                    //姿勢が良い
                    self.tapPlay((Any).self)
                    judgeLabel.text = "GOOD💙"
                    judgeLabel.textColor = UIColor.white
                    judgeLabel.backgroundColor = UIColor.clear
                    
                    }else{
                    //姿勢悪い
                    self.tapPause((Any).self)
                    judgeLabel.text = "BAD🙅‍♂️"
                    judgeLabel.textColor = UIColor.white
                    judgeLabel.backgroundColor = UIColor.clear
                }
            case 1:
                //横
                if (acceleration.y >= -0.05 && acceleration.y <= 0.1 && acceleration.x <= -0.95 && isWorking == 1){
                    //姿勢が良い
                    self.tapPlay((Any).self)
                    }else{
                    //姿勢悪い
                    self.tapPause((Any).self)
                }
            default:
                break
            }
            
        }
}


//for a tutorial
extension ViewController:CoachMarksControllerDataSource, CoachMarksControllerDelegate{
        
        func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
    //表示するスポットライトの数。チュートリアルの数。
            return 5
        }

        func coachMarksController(_ coachMarksController: CoachMarksController,
                                      coachMarkAt index: Int) -> CoachMark {
    //指し示す場所を決める。　今回はpointOfInterestすなわちButtonga指し示される
//            return coachMarksController.helper.makeCoachMark(for: pointOfInterest)
            
            switch index {
            case 0:
                return coachMarksController.helper.makeCoachMark(for: self.playerView)
            case 1:
                return coachMarksController.helper.makeCoachMark(for: self.inputURLField)
            case 2:
                return coachMarksController.helper.makeCoachMark(for: self.accelerometerX)
            case 3:
                return coachMarksController.helper.makeCoachMark(for: self.accelerometerY)
            case 4:
                return coachMarksController.helper.makeCoachMark(for: self.startButton)
            default:
                return CoachMark()
        }
    }


    //tableview　でいうreturn cellに似てるのかなってイメージ。表示するチュートリアルメッセージなどがいじれる
        func coachMarksController(
            _ coachMarksController: CoachMarksController,
            coachMarkViewsAt index: Int,
            madeFrom coachMark: CoachMark
        ) -> (bodyView: (UIView & CoachMarkBodyView), arrowView: (UIView & CoachMarkArrowView)?) {
            let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, withNextText: true, arrowOrientation: coachMark.arrowOrientation)
            
            
           /*
            coachViews.bodyView.hintLabel.text = "YouTubeの共有ボタンからリンクをコピペしてください✏️"
            coachViews.bodyView.nextLabel.text = "×"
 */
            switch index {
            case 0:
                coachViews.bodyView.hintLabel.text = "自分の顔とiPhoneが平行になっている間だけ動画が再生されます📺"
                coachViews.bodyView.nextLabel.text = "→"
            case 1:
                coachViews.bodyView.hintLabel.text = "ここにはYouTubeの共有ボタンからリンクをコピペしてください✏️"
                coachViews.bodyView.nextLabel.text = "→"
            case 2:
                coachViews.bodyView.hintLabel.text = "ここを目安にiPhoneの傾きを調整しよう⏱"
                coachViews.bodyView.nextLabel.text = "×"
            case 3:
                coachViews.bodyView.hintLabel.text = "x=0.0 y=-1.0が自分と平行な状態です📱"
                coachViews.bodyView.nextLabel.text = "×"
            case 4:
                coachViews.bodyView.hintLabel.text = "とりあえずPLAYボタンを押して試してみよう💨"
                coachViews.bodyView.nextLabel.text = "OK!"
            default: break
            }

            return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
                }
}

        func coachMarksController(_ coachMarksController: CoachMarksController,
                                  willShow coachMark: inout CoachMark,
                                  beforeChanging change: ConfigurationChange, at index: Int) {
            if index == 2 && change == .nothing {
                coachMarksController.flow.pause(and: .hideInstructions)
            }
}

