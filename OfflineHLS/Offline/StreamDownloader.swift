//
//  StreamDownloader.swift
//  OfflineHLS
//
//  Created by William Archimède on 28/04/2020.
//

// Son job est uniquement de télécharger un stream à partir de son url HLS
import AVFoundation
import Foundation

class StreamDownloader {
  static let downloadIdentifier = "POC-downloadIdentifier"
  static let assetPathKey = "assetPath"

  let streamURL: URL
  let session: AVAssetDownloadURLSession

  // Create new background session configuration
  init(streamURL: URL, configuration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: Self.downloadIdentifier), delegate: AVAssetDownloadDelegate? = nil, delegateQueue: OperationQueue? = nil) {
    self.streamURL = streamURL

    // Create a new AVAssetDownloadURLSession with background configuration, delegate, and queue
    self.session = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: delegate, delegateQueue: delegateQueue)
  }

  func startDownload() {
    let asset = AVURLAsset(url: streamURL)

    // Create new AVAssetDownloadTask for the desired asset and start it
    let task = downloadTask(for: asset, using: session)
    task?.resume()
  }

  private func downloadTask(for asset: AVURLAsset, using session: AVAssetDownloadURLSession) -> URLSessionTask? {
    if #available(iOS 11.2, *) {
      // Possible option [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]
      return session.aggregateAssetDownloadTask(with: asset, mediaSelections: [asset.preferredMediaSelection], assetTitle: "asset title", assetArtworkData: nil, options: nil)
    } else if #available(iOS 10, *) {
      return session.makeAssetDownloadTask(asset: asset, assetTitle: "asset title", assetArtworkData: nil, options: nil)
    } else { // iOS 9
      return session.makeAssetDownloadTask(asset: asset, destinationURL: URL(fileURLWithPath: NSHomeDirectory()), options: nil)
    }
  }
}
