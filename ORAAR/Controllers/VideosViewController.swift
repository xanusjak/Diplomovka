//
//  VideosViewController.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 16/10/2019.
//  Copyright © 2019 Anušjak, Milan. All rights reserved.
//

import UIKit
import Photos

class VideosViewControllerCell: UICollectionViewCell {
    class var reuseIdentifier: String {
        return "VideoCell"
    }
    var representedAssetIdentifier: String = ""
    
    @IBOutlet weak var imageView: UIImageView!
}

class VideosViewController: UICollectionViewController {

    class var openVideoSegueIdentifier: String {
        return "OpenVideo"
    }
    
    var assets: PHFetchResult<PHAsset>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == .authorized {
                DispatchQueue.main.async {
                    self.loadAssetsFromLibrary()
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.recalculateItemSize()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func loadAssetsFromLibrary() {
        let assetsOptions = PHFetchOptions()
        // include all source types
        assetsOptions.includeAssetSourceTypes = [.typeCloudShared, .typeUserLibrary, .typeiTunesSynced]
        // show most recent first
        assetsOptions.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        // fecth videos
        assets = PHAsset.fetchAssets(with: .video, options: assetsOptions)
        // setup collection view
        self.recalculateItemSize()
        self.collectionView?.reloadData()
    }
    
    private func recalculateItemSize() {
        if let collectionView = self.collectionView {
            guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
            }
            let desiredItemCount = self.traitCollection.horizontalSizeClass == .compact ? 4 : 6
            var availableSize = collectionView.bounds.width
            let insets = layout.sectionInset
            availableSize -= (insets.left + insets.right)
            availableSize -= layout.minimumInteritemSpacing * CGFloat((desiredItemCount - 1))
            let itemSize = CGFloat(floorf(Float(availableSize) / Float(desiredItemCount)))
            if layout.itemSize.width != itemSize {
                layout.itemSize = CGSize(width: itemSize, height: itemSize)
                layout.invalidateLayout()
            }
        }
    }

    private func asset(identifier: String) -> PHAsset? {
        var foundAsset: PHAsset? = nil
        self.assets?.enumerateObjects({ (asset, _, stop) in
            if asset.localIdentifier == identifier {
                foundAsset = asset
                stop.pointee = true
            }
        })
        return foundAsset
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == VideosViewController.openVideoSegueIdentifier {
            guard let avAsset = sender as? AVAsset else {
                fatalError("Unexpected sender type")
            }
            guard let videoController = segue.destination as? VideoViewController else {
                fatalError("Unexpected destination view controller type")
            }
            videoController.videoAsset = avAsset
        }
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let assets = self.assets else {
            return 0
        }
        return assets.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let asset = assets?[indexPath.item] else {
            fatalError("Failed to find asset at index \(indexPath.item)")
        }

        let genericCell = collectionView.dequeueReusableCell(withReuseIdentifier: VideosViewControllerCell.reuseIdentifier,
                                                             for: indexPath)
        guard let cell = genericCell as? VideosViewControllerCell else {
            return genericCell
        }
        cell.representedAssetIdentifier = asset.localIdentifier
        let imgMgr = PHImageManager()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        imgMgr.requestImage(for: asset, targetSize: cell.bounds.size, contentMode: .aspectFill, options: options) { (image, options) in
            if asset.localIdentifier == cell.representedAssetIdentifier {
                cell.imageView.image = image
            }
        }
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? VideosViewControllerCell else {
            fatalError("Failed to find cell as index path \(indexPath)")
        }
        let assetId = cell.representedAssetIdentifier
        guard let asset = self.asset(identifier: assetId) else {
            fatalError("Failed to find asset with identifier \(assetId)")
        }
        let imgMgr = PHImageManager.default()
        let videoOptions = PHVideoRequestOptions()
        videoOptions.isNetworkAccessAllowed = true
        videoOptions.deliveryMode = .highQualityFormat
        imgMgr.requestAVAsset(forVideo: asset, options: videoOptions) { (avAsset, _, _) in
            guard let videoAsset = avAsset else {
                return
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: VideosViewController.openVideoSegueIdentifier, sender: videoAsset)
            }
        }
    }
}
