//
//  ViewController.swift
//  RSRateView
//
//  Created by jie on 2017/1/16.
//  Copyright © 2017年 HTIOT.Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var line: RSRateView!
    var line2: RSRateView!
    var solidCircle: RSRateView!
    var borderline: RSRateView!
    var concentric: RSRateView!
    
    var timer: RSRepeatedTimer!
    var progress: Float = 0.0
    
    var animator: RSRateAnimator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        
        line = RSRateView(frame: CGRect(x: 20, y: 30, width: view.bounds.width - 40, height: 10))
        view.addSubview(line)
        let lineShadow = RSShadow(offset: CGSize(width: 0, height: 3), blurRadius: 5, color: UIColor.lightGray.cgColor)
        let linestroke = RSStrokeAttr(width: 0, color: UIColor.green.cgColor, shadow: lineShadow)
        let lineMode = RSRateModel(shape: .line, orientation: .auto, strokeAttr: linestroke)
        line.setLayerModel(lineMode)
        
        var lineMode2 = RSRateModel(shape: .line,
                                    orientation: .auto,
                                    strokeAttr: RSStrokeAttr(width: 0, color: UIColor.green.cgColor))
        lineMode2.backgroundColor = UIColor.lightGray
        line2 = RSRateView(frame: CGRect(x: 20, y: view.bounds.height - 50, width: view.bounds.width - 40, height: 10),
                           model: lineMode2)
        view.addSubview(line2)
        line2.animate(withDuration: 5)
        
        solidCircle = RSRateView(frame: CGRect(x: (view.bounds.width - 100) / 2.0, y: 50, width: 100, height: 100))
        view.addSubview(solidCircle)
        
        let circleFill = RSFillAttr(color: UIColor.lightGray.cgColor)
        var circleModel = RSRateModel(shape: .solidArc, orientation: .counterClockwise, fillAttr: circleFill)
        circleModel.backgroundColor = UIColor(white: 0.96, alpha: 1)
        solidCircle.setLayerModel(circleModel)
        
        borderline = RSRateView(frame: CGRect(x: (view.bounds.width - 60) / 2.0, y: 200, width: 60, height: 60))
        borderline.setLayerModel(RSRateModel(shape: .hollowArc(width: 4), orientation: .counterClockwise, strokeAttr: RSStrokeAttr(width: 0, color: UIColor.green.cgColor)))
        view.addSubview(borderline)
        borderline.progressLayer.shadowColor = UIColor.blue.cgColor
        borderline.progressLayer.shadowOffset = CGSize(width: 0, height: 3)
        borderline.progressLayer.shadowRadius = 1
        borderline.progressLayer.shadowOpacity = 1.0
        
        
        concentric = RSRateView(frame: CGRect(x: (view.bounds.width - 60) / 2.0, y: 280, width: 60, height: 60))
        view.addSubview(concentric)
        var concentricModel = RSRateModel(shape: .concentricArc(borderWidth: 4, gap: 3),
                                          orientation: .counterClockwise,
                                          strokeAttr: RSStrokeAttr(width: 0, color: UIColor.green.cgColor, shadow: nil),
                                          fillAttr: RSFillAttr(color: UIColor.purple.cgColor, shadow: nil))
        concentricModel.backgroundColor = UIColor(white: 0.96, alpha: 1)
        concentric.setLayerModel(concentricModel)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let main = DispatchQueue.main
        
        let halfRate = DispatchWorkItem {
            self.line.progressLayer.progress = 0.5
            self.solidCircle.progressLayer.progress = 0.5
            self.borderline.progressLayer.progress = 0.5
        }
        let finishRate = DispatchWorkItem {
            self.line.progressLayer.progress = 1.0
            self.solidCircle.progressLayer.progress = 1.0
            self.borderline.progress = 1.0
        }
        main.asyncAfter(deadline: DispatchTime.now() + 2, execute: halfRate)
        main.asyncAfter(deadline: DispatchTime.now() + 4, execute: finishRate)
        main.asyncAfter(deadline: DispatchTime.now() + 6) {
            self.line.progressLayer.progress = RSRateModel.Init.value
            self.solidCircle.progressLayer.progress = RSRateModel.Init.value
            self.borderline.progress = RSRateModel.Init.value
        }
        main.asyncAfter(deadline: DispatchTime.now() + 8) {
            self.startTimer()
        }
        
        self.concentric.progress = 0.3
        self.concentric.animate(withDuration: 4)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func startTimer() {
        timer = RSRepeatedTimer(timeInterval: 0.1, block: { (_) in
            self.progress += 0.01
            self.line.progressLayer.progress = self.progress
            self.solidCircle.progress = self.progress
            self.borderline.progress = self.progress
            
            if self.progress >= 1.0 {
                self.progress = 0.001
                self.line.frame = CGRect(x: 20, y: 20, width: 10, height: 100)
                self.line.progressLayer.model.orientation = .vertical
            }
        })
    }
    
}

