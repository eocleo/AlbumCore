//
//  AlbumManager.swift
//  SmartAlbum
//
//  Created by leo on 2017/5/12.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit
import Photos

class AlbumCollection: NSObject {
    var collection: PHAssetCollection

    var name: String
    
    var count: Int? {
        get {
            return self.assetsResult?.count
        }
    }
    
    var firstImage: UIImage?
    var lastImage: UIImage?

    var assetsResult: PHFetchResult<PHAsset>?
    
    func getFistImage(size: CGSize, complete: @escaping ((_ image: UIImage?) -> Void)) -> Void {
        self.fetchAssets(block: { [weak self] (result: PHFetchResult<PHAsset>) in
            self?.getImage(with: result.firstObject, size: size, complete: { [weak self] (image) in
                self?.firstImage = image
                complete(image)
            })
        })
    }
    
    func getLastImage(size: CGSize, complete: @escaping ((_ image: UIImage?) -> Void)) -> Void {
        self.fetchAssets(block: {[weak self] (result: PHFetchResult<PHAsset>) in
            self?.getImage(with: result.lastObject, size: size, complete: { [weak self] (image) in
                self?.lastImage = image
                complete(image)
            })
        })
    }
    
    fileprivate func getImage(with asset: PHAsset?, size: CGSize, complete: @escaping ((_ image: UIImage?) -> Void)) -> Void {
        if asset != nil {
            let options:PHImageRequestOptions = PHImageRequestOptions.init()
            options.resizeMode = .fast
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            asset?.requestImage(options: options, size: size, block: { (dic) in
                complete(dic[AlbumConstant.ImageKey] as? UIImage)
            })
        } else {
            complete(nil)
        }
    }
    
    func fetchAssets(block: @escaping ((_ result: PHFetchResult<PHAsset>) -> Swift.Void)) -> Void {
        let options = PHFetchOptions.init()
        options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: true)]
        self.assetsResult = PHAsset.fetchAssets(in: self.collection, options: options)
        block(self.assetsResult!)
    }
    
    
    init(with collection: PHAssetCollection) {
        self.collection = collection
        self.name = collection.localizedTitle ?? "相册"
        super.init()
    }
    
    func clearCache() -> Void {
        self.firstImage = nil
        self.assetsResult = nil
    }
}

