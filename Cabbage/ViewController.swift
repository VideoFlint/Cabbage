//
//  ViewController.swift
//  Cabbage
//
//  Created by Vito on 2018/7/28.
//  Copyright © 2018 Vito. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func showPlayerAction(_ sender: Any) {
        if let playerItem = fetchPlayerItem() {
            let controller = AVPlayerViewController.init()
            controller.player = AVPlayer.init(playerItem: playerItem)
            controller.view.backgroundColor = UIColor.white
            present(controller, animated: true, completion: nil)
        }
    }
    
    func fetchPlayerItem() -> AVPlayerItem? {
        guard let url = Bundle.main.url(forResource: "Marvel Studios", withExtension: "mp4") else {
            return nil
        }
        
        let asset = AVAsset.init(url: url)
        
        let resource = AVAssetTrackResource(asset: asset)
        
        let trackItem = TrackItem(resource: resource)
        trackItem.configuration.videoConfiguration.baseContentMode = .aspectFill
        trackItem.configuration.speed = 2.0
        
        trackItem.reloadTimelineDuration()
        
        let timeline = Timeline()
        timeline.videoChannel = [trackItem]
        timeline.audioChannel = [trackItem]
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        compositionGenerator.renderSize = CGSize(width: 1080, height: 1080)
        let playerItem = compositionGenerator.buildPlayerItem()
        return playerItem
    }

}

