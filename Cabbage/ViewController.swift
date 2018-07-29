//
//  ViewController.swift
//  Cabbage
//
//  Created by Vito on 2018/7/28.
//  Copyright © 2018 Vito. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func simpleDemo() {
        let asset = AVAsset()
        
        let resource = AVAssetTrackResource(asset: asset)
        
        let trackItem = TrackItem(resource: resource)
        trackItem.configuration.videoConfiguration.baseContentMode = .aspectFill
        
        let timeline = Timeline()
        timeline.videoChannel = [trackItem]
        timeline.audioChannel = [trackItem]
        
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        compositionGenerator.renderSize = CGSize(width: 1920, height: 1080)
        let exportSession = compositionGenerator.buildExportSession(presetName: AVAssetExportPresetMediumQuality)
        let playerItem = compositionGenerator.buildPlayerItem()
        let imageGenerator = compositionGenerator.buildImageGenerator()
    }

}

