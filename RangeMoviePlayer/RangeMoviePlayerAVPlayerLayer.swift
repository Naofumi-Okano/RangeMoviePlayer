//
//  RangeMoviePlayerAVPlayerLayer.swift
//  RangeMoviePlayer
//
//  Created by 岡野 直史 on 2019/04/12.
//  Copyright © 2019年 岡野 直史. All rights reserved.
//

import RxSwift
import RxCocoa

import UIKit
import AVFoundation

internal final class RangeMoviePlayerAVPlayerLayer: UIView {
    public var playerItemStatus:BehaviorRelay<AVPlayerItem.Status> = BehaviorRelay.init(value: .unknown)
    public var duration:BehaviorRelay<Float64> = BehaviorRelay.init(value: 0)
    public var periodicTime:BehaviorRelay<Float64> = BehaviorRelay.init(value: 0)
    public var isSeeking:BehaviorRelay<Bool> = BehaviorRelay.init(value: false)
    public var isPause:BehaviorRelay<Bool> = BehaviorRelay.init(value: true)
    public var isPlaying:BehaviorRelay<Bool> = BehaviorRelay.init(value: false)
    public var rate: BehaviorRelay<Float> = BehaviorRelay.init(value: 0)
    
    private var player : AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "status") {
            guard let player = self.player else { return }
            switch (player.status) {
            case .unknown:
                self.playerItemStatus.accept(.unknown)
            case .readyToPlay:
                self.playerItemStatus.accept(.readyToPlay)
            case .failed:
                self.playerItemStatus.accept(.failed)
            }
        }
    }
}

/// Public Methods
extension RangeMoviePlayerAVPlayerLayer {
    internal func loadMovie(url:URL) {
        self.player = AVPlayer(url: url)
        guard let player = self.player else { return }
        player.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        addPeriodicTimeObserver()
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        bind()
    }
    
    internal func seek(to: Float64) {
        guard let player = self.player else { return }
        isSeeking.accept(true)
        player.seek(to: CMTimeMakeWithSeconds(to, preferredTimescale: 1)) { [weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.isSeeking.accept(false)
        }
    }
    
    internal func play() {
        guard let player = self.player else { return }
        player.play()
    }
    
    internal func pause() {
        guard let player = self.player else { return }
        player.pause()
    }
}

/// Private Methods
extension RangeMoviePlayerAVPlayerLayer {
    private func bind() {
        let _ = rate.asObservable()
        .subscribe(onNext: { [weak self] rate in
            guard let weakSelf = self else { return }
            weakSelf.isPause.accept(rate == 0)
            weakSelf.isPlaying.accept(rate != 0)
        })
    }
    
    private func addPeriodicTimeObserver() {
        guard let player = self.player else { return }
        
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds:1.0, preferredTimescale:500), queue: nil, using: { [weak self] (periodicTime) in
            guard let weakSelf = self else { return }
            guard let currentItem = player.currentItem else { return }
            
            switch (currentItem.status) {
            case .unknown:
                weakSelf.playerItemStatus.accept(.unknown)
            case .readyToPlay:
                weakSelf.playerItemStatus.accept(.readyToPlay)
                weakSelf.periodicTime.accept(CMTimeGetSeconds(periodicTime))
                weakSelf.duration.accept(CMTimeGetSeconds(currentItem.asset.duration))
                weakSelf.rate.accept(player.rate)
            case .failed:
                weakSelf.playerItemStatus.accept(.failed)
            }
        })
    }
    
    @objc private func playerItemDidReachEnd(_ notification: Notification) {
        guard let player = self.player else { return }
        player.seek(to: CMTime.zero)
    }
}

/// Debug Tools
extension RangeMoviePlayerAVPlayerLayer {
    private func showLog() {
        print("@@@@@ " +
        "duration:" + String(self.duration.value) + "\n" +
        "periodicTime:" + String(self.periodicTime.value) + "\n" +
        "rate:" + String(self.rate.value) + "\n" +
        "isPause:" + String(self.isPause.value) + "\n" +
        "isPlaying:" + String(self.isPlaying.value) + "\n")
    }
}

