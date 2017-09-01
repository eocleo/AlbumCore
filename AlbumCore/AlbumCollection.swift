//
//  AlbumManager.swift
//  SmartAlbum
//
//  Created by leo on 2017/5/12.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit
import Photos

protocol CollectionChangeDetailObserver {
    func didReceiveChange(_ detail: PHObjectChangeDetails<PHAssetCollection>?, collection: AlbumCollection) -> Void
}

protocol FetchResultChangeDetailObserver {
    func didReceiveChange(_ detail: PHFetchResultChangeDetails<PHAsset>?, collection: AlbumCollection) -> Void
}

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
        PHPhotoLibrary.shared().register(self)
    }
    
    func clearCache() -> Void {
        self.firstImage = nil
        self.lastImage = nil
        self.assetsResult = nil
    }
    
    // MARK: - PHChange
    fileprivate var collectionChangeObservers: NSHashTable<AnyObject> = NSHashTable.init(options: NSPointerFunctions.Options.weakMemory)
    fileprivate var fetchResultChangeObservers: NSHashTable<AnyObject> = NSHashTable.init(options: NSPointerFunctions.Options.weakMemory)
    
    //注册变化通知
    func registerCollectionChange(_ observer: CollectionChangeDetailObserver) -> Void {
        if self.collectionChangeObservers.contains(observer as AnyObject) {
            return
        }
        self.collectionChangeObservers.add(observer as AnyObject)
    }
    
    func registerFetchResultChange(_ observer: FetchResultChangeDetailObserver) -> Void {
        if self.fetchResultChangeObservers.contains(observer as AnyObject) {
            return
        }
        self.fetchResultChangeObservers.add(observer as AnyObject)
    }
}

extension AlbumCollection: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let collectionChangeDetail = changeInstance.changeDetails(for: self.collection)  {
            for observer in self.collectionChangeObservers.allObjects {
                if let observer = observer as? CollectionChangeDetailObserver {
                    observer.didReceiveChange(collectionChangeDetail, collection: self)
                }
            }
        }
        
        guard let fetchResults = self.assetsResult else {
            return
        }

        if let fetchResultChangeDetail = changeInstance.changeDetails(for: fetchResults) {
            for observer in self.fetchResultChangeObservers.allObjects {
                if let observer = observer as? FetchResultChangeDetailObserver {
                    self.assetsResult = fetchResultChangeDetail.fetchResultAfterChanges
                    observer.didReceiveChange(fetchResultChangeDetail, collection: self)
                }
            }
        }
    }
}

