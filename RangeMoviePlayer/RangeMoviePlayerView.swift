//
//  RangeMoviePlayerView.swift
//  RangeMoviePlayer
//
//  Created by 岡野 直史 on 2019/04/12.
//  Copyright © 2019年 岡野 直史. All rights reserved.
//

import RxSwift
import RxCocoa

import UIKit
import AVKit

internal final class RangeMoviePlayerView: UIView {
    @IBOutlet private weak var avPlayerLayer: RangeMoviePlayerAVPlayerLayer!
    @IBOutlet private weak var ui: RangeMoviePlayerUIView!
    
    private var url: URL? = nil
    private var isLoop: Bool = false
    private var startTime: BehaviorRelay<Float64> = BehaviorRelay.init(value: 0)
    private var endTime: BehaviorRelay<Float64> = BehaviorRelay.init(value: Float64.greatestFiniteMagnitude)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        loadNib()
    }
    
    func loadNib() {
        let nib = Bundle.main.loadNibNamed("RangeMoviePlayer", owner: self, options: nil)
        let view = nib?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
        initView()
    }
    
    func initView() {
    }
}

/// Public Methods
extension RangeMoviePlayerView {
    internal func source(url:URL) {
        self.url = url
    }
    
    internal func isLoop(enable:Bool) {
        self.isLoop = enable
    }
    
    internal func startTime(time:Float64) {
        self.startTime.accept(time)
    }
    
    internal func endTime(time:Float64) {
        self.endTime.accept(time)
    }
    
    internal func play() {
        guard let url:URL = self.url else {
            return
        }
        
        bindUI()
        bindControl()
        self.avPlayerLayer.loadMovie(url: url)
        self.avPlayerLayer.seek(to: self.startTime.value)
        self.avPlayerLayer.play()
    }
    
    internal func stop() {
        
    }
}

extension RangeMoviePlayerView {
    /// UIの描画更新系
    private func bindUI() {
        /// 一時停止ボタンが押された処理
        let _ = ui.pauseButton.drive(onNext: { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.avPlayerLayer.pause()
        })
        
        /// 再生ボタンが押された処理
        let _ = ui.playButton.drive(onNext: { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.avPlayerLayer.play()
        })
        
        /// 一時停止ボタンの表示を更新
        let _ = avPlayerLayer.isPause.asObservable().subscribe(onNext: { [weak self] isPause in
            guard let weakSelf = self else { return }
            weakSelf.ui.pauseUIButton.isHidden = isPause
        })
        
        /// 再生ボタンの表示を更新
        let _ = avPlayerLayer.isPlaying.asObservable().subscribe(onNext: { [weak self] isPlaying in
            guard let weakSelf = self else { return }
            weakSelf.ui.playUIButton.isHidden = isPlaying
        })
        
        /// 動画長のテキストを更新する
        let _ = avPlayerLayer.periodicTime.asObservable().subscribe(onNext: { [weak self] periodicTime in
            guard let weakSelf = self else { return }
            weakSelf.ui.periodicTimeLabel.text = weakSelf.toPositionalFormat(time: periodicTime)
        })
        
        /// 現在の再生時間を更新する
        let _ = avPlayerLayer.duration.asObservable().subscribe(onNext: { [weak self] durationTime in
            guard let weakSelf = self else { return }
            weakSelf.ui.durationTimeLabel.text = weakSelf.toPositionalFormat(time: durationTime)
        })
        
        /// 再生中、シークバーの位置を現在の秒数で自動更新
        let _ = avPlayerLayer.periodicTime.asObservable()
            .filter { [weak self] _ -> Bool in
                guard let weakSelf = self else { return false }
                return weakSelf.ui.seekSlider.isSeeking.value == false && weakSelf.avPlayerLayer.isSeeking.value == false
            }
            .subscribe(onNext: { [weak self] periodicTime in
                guard let weakSelf = self else { return }
                weakSelf.ui.seekSlider.value = Float(periodicTime)
            })
        
        /// シークバーから手が離されたらシークする
        let _ = ui.seekSlider.seekStatus.asObservable()
            .distinctUntilChanged()
            .filter { seekStatus -> Bool in
                return seekStatus == .ended
            }
            .subscribe(onNext: { [weak self] seekStatus in
                guard let weakSelf = self else { return }
                let value = weakSelf.ui.seekSlider.value
                weakSelf.avPlayerLayer.seek(to: Double(value))
            })
        
        /// 動画長、再生時間、再生開始位置、再生終了位置が更新された際にUIを更新する
        let _ = Observable.combineLatest(avPlayerLayer.periodicTime.asObservable(), avPlayerLayer.duration.asObservable(), startTime.asObservable(), endTime.asObservable())
            .subscribe(onNext: { [weak self] (periodicTime, duration, startTime, endTime) in
                guard let weakSelf = self else { return }
                
                // UI向けのUISlider
                weakSelf.ui.baseSeekSlider.minimumValue = 0
                weakSelf.ui.baseSeekSlider.maximumValue = Float(duration)
                
                // 実質的なUISlider
                let fixedStartTime:Float = max(0, Float(startTime))
                let fixedEndTime:Float = min(Float(duration), Float(endTime))
                weakSelf.ui.seekSlider.minimumValue = fixedStartTime
                weakSelf.ui.seekSlider.maximumValue = fixedEndTime
                
                /// startTime, endTimeが指定されている場合、seekSliderの表示は前後を詰めたものにする
                if (0 < duration) {
                    let baseWidth = weakSelf.ui.baseSeekSlider.bounds.width
                    let leadingConstraint = baseWidth * CGFloat(fixedStartTime / Float(duration))
                    let trailingConstraint = baseWidth - (baseWidth * CGFloat(fixedEndTime / Float(duration)))
                    weakSelf.ui.seekSliderLeft.constant = leadingConstraint
                    weakSelf.ui.seekSliderRight.constant = trailingConstraint
                    
                    if false {
                        print("periodicTime:" + periodicTime.description + "\n" +
                            "duration:" + duration.description + "\n" +
                            "startTime:" + startTime.description + "\n" +
                            "endTime:" + endTime.description + "\n" +
                            "baseWidth:" + baseWidth.description + "\n" +
                            "fixedStartTime:" + fixedStartTime.description + "\n" +
                            "fixedEndTime:" + fixedEndTime.description + "\n" +
                            "leadingConstraint:" + leadingConstraint.description + "\n" +
                            "trailingConstraint:" + trailingConstraint.description
                        )
                    }
                }
            })
    }
    
    /// UIとは異なる内部実行処理系
    private func bindControl() {
        /// 指定されたendTimeまで再生が完了した
        let _ = avPlayerLayer.periodicTime.asObservable()
            .filter({ [weak self] periodicTime -> Bool in
                guard let weakSelf = self else { return false }
                if (weakSelf.endTime.value <= periodicTime) {
                    return true
                }
                return false
            })
            .subscribe(onNext: { [weak self] periodicTime in
                guard let weakSelf = self else { return }
                if (weakSelf.isLoop) {
                    weakSelf.avPlayerLayer.seek(to: weakSelf.startTime.value)
                } else {
                    weakSelf.avPlayerLayer.pause()
                }
        })
    }
}

extension RangeMoviePlayerView {
    private var formatter:DateComponentsFormatter {
        get {
            let _formatter = DateComponentsFormatter()
            _formatter.unitsStyle = .positional
            _formatter.allowedUnits = [.hour, .minute, .second]
            _formatter.zeroFormattingBehavior = .pad
            return _formatter
        }
    }
    
    func toPositionalFormat(time: Float64) -> String {
        return formatter.string(from: time) ?? ""
    }
}
