//
//  ViewController.swift
//  OfflineHLS
//
//  Created by William Archimède on 10/04/2018.
//  Copyright © 2018 William Archimede. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    setupAssetDownload()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  let downloadIdentifier = "downloadIdentifier"
  let assetPathKey = "assetPath"

  func setupAssetDownload() {
    // Create new background session configuration
    let configuration = URLSessionConfiguration.background(withIdentifier: downloadIdentifier)

    // Create a new AVAssetDownloadURLSession with background configuration, delegate, and queue
    let downloadSession = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: self, delegateQueue: .main)

    let url = URL(string: "https://tungsten.aaplimg.com/VOD/bipbop_adv_fmp4_example/master.m3u8")!
    let asset = AVURLAsset(url: url)

    // Create new AVAssetDownloadTask for the desired asset
    //    let downloadTask = downloadSession.makeAssetDownloadTask(asset: asset, destinationURL: URL, options: nil) // iOS 9 only, deprecated in iOS 10+
    let downloadTask = downloadSession.makeAssetDownloadTask(asset: asset, assetTitle: "Bipbop", assetArtworkData: nil, options: nil)

    // Start task and begin download
    downloadTask?.resume()
  }

  func playOfflineAsset() {
    guard let assetPath = UserDefaults.standard.value(forKey: assetPathKey) as? String
      else {
        // Present Error: No offline version of this asset available
        print("Error: No offline version of this asset available")
        return
    }

    let baseURL = URL(fileURLWithPath: NSHomeDirectory())
    let assetURL = baseURL.appendingPathComponent(assetPath)
    let asset = AVURLAsset(url: assetURL)

    if let cache = asset.assetCache, cache.isPlayableOffline {
      // Set up player item and player and begin playback
      let item = AVPlayerItem(asset: asset)
      let player = AVPlayer(playerItem: item)
      let playerVC = AVPlayerViewController()
      playerVC.player = player
      present(playerVC, animated: true, completion: nil)
    } else {
      // Present Error: No offline version of this asset available
      print("Error: No offline version of this asset available")
    }
  }

  func deleteOfflineAsset() {
    do {
      let userDefaults = UserDefaults.standard
      if let assetPath = userDefaults.value(forKey: "assetPath") as? String {
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        let assetURL = baseURL.appendingPathComponent(assetPath)
        try FileManager.default.removeItem(at: assetURL)
        userDefaults.removeObject(forKey: assetPathKey)
      }
    } catch {
      print("An error occured deleting offline asset: \(error)")
    }
  }
}

extension ViewController: AVAssetDownloadDelegate {
  func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
    var percentComplete = 0.0

    // Iterate through the loaded time ranges
    for value in loadedTimeRanges {
      // Unwrap the CMTimeRange from the NSValue
      let loadedTimeRange = value.timeRangeValue
      // Calculate the percentage of the total expected asset duration
      percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
    }
    percentComplete *= 100

    // Update UI state: post notification, update KVO state, invoke callback, etc.
    print("\(percentComplete)%")
  }

  func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
    // Do not move the asset from the download location
    UserDefaults.standard.set(location.relativePath, forKey: assetPathKey)

    print("FINISHED \(location)")
    playOfflineAsset()
  }
}
