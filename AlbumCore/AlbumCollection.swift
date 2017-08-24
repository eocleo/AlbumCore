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

    var assetsResult: PHFetchResult<PHAsset>?
    
    func getFistImage(size: CGSize, complete: @escaping ((_ image: UIImage?) -> Void)) -> Void {
        self.collection.getFirstImage(size: size, block: { [weak self] (imageInfo) in
            self?.firstImage = imageInfo[AlbumConstant.ImageKey] as? UIImage
            complete(self?.firstImage)
        })
    }
    
    func fetchAssets(block: @escaping ((_ result: PHFetchResult<PHAsset>) -> Swift.Void)) -> Void {
        self.assetsResult = PHAsset.fetchAssets(in: self.collection, options: nil)
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

