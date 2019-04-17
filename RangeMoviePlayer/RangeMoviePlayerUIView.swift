//
//  RangeMoviePlayerUIView.swift
//  RangeMoviePlayer
//
//  Created by 岡野 直史 on 2019/04/12.
//  Copyright © 2019年 岡野 直史. All rights reserved.
//

import RxSwift
import RxCocoa

import UIKit

internal final class RangeMoviePlayerUIView: UIView {
    @IBOutlet public weak var playUIButton: UIButton!
    @IBOutlet public weak var pauseUIButton: UIButton!
    @IBOutlet public weak var periodicTimeLabel: UILabel!
    @IBOutlet public weak var durationTimeLabel: UILabel!
    /// 動画の全長を示すためのUIのみのSeekSlider
    @IBOutlet public weak var baseSeekSlider: UISlider!
    @IBOutlet public weak var seekSlider: UISeekSlider!
    @IBOutlet public weak var seekSliderLeft: NSLayoutConstraint!
    @IBOutlet public weak var seekSliderRight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initView()
    }
}

extension RangeMoviePlayerUIView {
    internal var playButton: Driver<Void> {
        return playUIButton.rx.tap.asDriver()
    }
    
    internal var pauseButton: Driver<Void> {
        return pauseUIButton.rx.tap.asDriver()
    }
}

/// Private Methods
extension RangeMoviePlayerUIView {
    private func initView() {
        initSeekSliderView()
        bindButton()
    }

    private func initSeekSliderView() {
        let thumbImage = UIColor.white.circleImage(width:16, height:16)
        seekSlider.setThumbImage(thumbImage, for: .normal)
        seekSlider.setThumbImage(thumbImage, for: .selected)
        seekSlider.setThumbImage(thumbImage, for: .highlighted)
    }
    
    private func bindButton() {
        
    }
}
