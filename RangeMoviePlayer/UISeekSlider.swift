//
//  UISeekSlider.swift
//  RangeMoviePlayer
//
//  Created by 岡野 直史 on 2019/04/17.
//  Copyright © 2019年 岡野 直史. All rights reserved.
//

import RxSwift
import RxCocoa

import UIKit

class UISeekSlider: UISlider {
    @IBOutlet private weak var baseSeekSlider:UISlider!
    
    public var seekStatus:BehaviorRelay<UIGestureRecognizer.State> = BehaviorRelay.init(value: .possible)
    public var isSeeking:BehaviorRelay<Bool> = BehaviorRelay.init(value: false)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if setup {}
    }
    
    private lazy var setup: Bool = {
        initGestureRecognizer()
        return true
    }()
}


extension UISeekSlider {
    func initGestureRecognizer() {
        let seekGesture:UISeekGestureRecognizer = UISeekGestureRecognizer(target: self, action: #selector(UISeekSlider.seekGesture(_:)))
        self.addGestureRecognizer(seekGesture)
    }
    
    @objc func seekGesture(_ recognizer: UIGestureRecognizer) {
        let value = self.calculateLimit(self.calculateValue(recognizer))
        
        switch(recognizer.state) {
        case .possible:
            break
        case .began:
            /// isSeeking -> value -> seekStatusの順に更新する
            self.isSeeking.accept(true)
            self.value = value
            self.seekStatus.accept(.began)
        case .changed:
            self.value = value
            self.seekStatus.accept(.changed)
        case .ended:
            self.seekStatus.accept(.ended)
            self.value = value
            self.isSeeking.accept(false)
        case .cancelled:
            break
        case .failed:
            break
        }
    }
    
    private func calculateValue(_ recognizer: UIGestureRecognizer) -> Float {
        let point:CGPoint = recognizer.location(in: self.superview);
        guard let width:CGFloat = self.superview?.bounds.width else { return 0 }
        let percent:CGFloat = point.x / width
        let value:Float = self.baseSeekSlider.maximumValue * Float(percent)
        return value
    }
    
    private func calculateLimit(_ value: Float) -> Float {
        return max(self.minimumValue, min(self.maximumValue, value))
    }
}

// Long
class UISeekGestureRecognizer: UILongPressGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if (self.state == .possible) {
            self.state = .began
        }
    }
}
