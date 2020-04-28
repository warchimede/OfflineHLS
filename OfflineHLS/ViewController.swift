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

  let downloadIdentifier = "POC-downloadIdentifier"
  let assetPathKey = "assetPath"

  @IBAction func onDownloadButtonTapped(_ sender: Any) {
    setupAssetDownload()
  }

  func setupAssetDownload() {
    // Create new background session configuration
    let configuration = URLSessionConfiguration.background(withIdentifier: downloadIdentifier)

    // Create a new AVAssetDownloadURLSession with background configuration, delegate, and queue
    let downloadSession = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: self, delegateQueue: .main)

    let url = URL(string: "https://tungsten.aaplimg.com/VOD/bipbop_adv_fmp4_example/master.m3u8")!
    let asset = AVURLAsset(url: url)

    // Create new AVAssetDownloadTask for the desired asset
    let downloadTask: AVAssetDownloadTask!
    if #available(iOS 10.0, *) {
      downloadTask = downloadSession.makeAssetDownloadTask(asset: asset, assetTitle: "Bipbop", assetArtworkData: nil, options: nil)
    } else {
      // Fallback on earlier versions
      downloadTask = downloadSession.makeAssetDownloadTask(asset: asset, destinationURL: URL(fileURLWithPath: NSHomeDirectory()), options: nil) // iOS 9 only, deprecated in iOS 10+
    }

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

    if #available(iOS 10.0, *) {
      if let cache = asset.assetCache, cache.isPlayableOffline {
        presentPlayer(using: asset)
      } else {
        // Present Error: No offline version of this asset available
        print("Error: No offline version of this asset available")
      }
    } else {
      // Fallback on earlier versions
      presentPlayer(using: asset)
    }
  }

  private func presentPlayer(using asset: AVAsset) {
    // Set up player item and player and begin playback
    let item = AVPlayerItem(asset: asset)
    let player = AVPlayer(playerItem: item)
    let playerVC = AVPlayerViewController()
    playerVC.player = player
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
