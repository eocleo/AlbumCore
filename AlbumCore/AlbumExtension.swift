//
//  PHAssetExtension.swift
//  FileMail
//
//  Created by leo on 2017/5/26.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AVKit

func AlbumDebug(_ items: Any..., file: String = #file, function: String = #function, line: UInt = #line) {
    var msg: String = "";
    for item in items {
        msg.append(String.init(describing: item))
    }
    NSLog("\(file)\n\(function):\(line)\n\(msg)")
}

struct AlbumConstant {
    static let ImageKey = "ImageKey"
    static let ImageInfoKey = "ImageInfoKey"
}

extension PHAssetCollection {

    //获取相册
    class func fetchAlbum(with: PHAssetCollectionType, subtype: PHAssetCollectionSubtype, options: PHFetchOptions?) -> PHFetchResult<PHAssetCollection> {
        return PHAssetCollection.fetchAssetCollections(with: with, subtype: subtype, options: options)
    }
    
    //获取相册中所有元素
    func fetchAssets(block: @escaping ((_ result: PHFetchResult<PHAsset>) -> Swift.Void)) -> Void {
        block(PHAsset.fetchAssets(in: self, options: nil))
    }
    
    func fetchAssets(options: PHFetchOptions?, block: @escaping ((_ result: PHFetchResult<PHAsset>) -> Swift.Void)) -> Void {
        block(PHAsset.fetchAssets(in: self, options: options))
    }    
}

extension PHAsset {
    
    class func createWith(identifier: String) -> PHAsset? {
        return PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
    }
    
    @discardableResult
    func requestURL(block: @escaping ((URL?, AVAsset?) -> Void)) -> PHImageRequestID {
        if self.mediaType != .video {
            AlbumDebug("requestURL 只能针对video，非video总是返回nil")
            block(nil, nil)
            return 0
        }
        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .automatic
        return PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: { (asset, audioMix, info) in
            if let urlAsset: AVURLAsset = asset as? AVURLAsset {
                block(urlAsset.url, asset)
            } else {
                block(nil, nil)
            }
        })
    }
    
    
    @discardableResult
    func requestImage(size: CGSize, block: @escaping ((Dictionary<String, Any>) -> Void)) -> PHImageRequestID {
        let options = PHImageRequestOptions.init()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        return self.requestImage(options: options, size: size, block: block)
    }
    
    @discardableResult
    func requestImage(options: PHImageRequestOptions, size: CGSize, block: @escaping ((Dictionary<String, Any>) -> Void)) -> PHImageRequestID {
        return PHCachingImageManager.default().requestImage(for: self, targetSize: size, contentMode: PHImageContentMode.aspectFill, options: options) { (image, info) in
            var dic:Dictionary<String, Any> = Dictionary.init()
            if let image = image {
                dic.updateValue(image, forKey: AlbumConstant.ImageKey)
            }
            if let info = info {
                dic.updateValue(info, forKey: AlbumConstant.ImageInfoKey)
            }
            block(dic)
        }
    }
    
    //仅对图片校验有效，视频未测试
    func isICloudImageAsset() -> Bool {
        let options = PHImageRequestOptions.init()
        options.resizeMode = .fast
        options.isSynchronous = true
        
        var isICloudImageAsset = false
        PHImageManager.default().requestImage(for: self, targetSize: CGSize.init(width: 60, height: 60), contentMode: PHImageContentMode.aspectFill, options: options) { (image, info) in
            if (info?[PHImageResultIsInCloudKey] as? Bool) == true {
                isICloudImageAsset = true
            }
        }
        return isICloudImageAsset
    }

    //文件路径，大小, id
    func requestAllInfo(block: @escaping (_ path: String, _ size: Double, _ identifier: String) -> Void) -> Void {
        if self.mediaType == .image {
            let options = PHImageRequestOptions.init()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImageData(for: self, options: options, resultHandler: { (data, string, orient, info) in
                AlbumDebug("requestImageData:\(String(describing: data?.count))")
                var filePath: String?, fileSize: Double?, identitier: String?
                identitier = self.localIdentifier
                if data != nil {
                    fileSize = Double(data?.count ?? 0)
                    if let newInfo = info {
                        if let imageUrl = newInfo["PHImageFileURLKey"] as? URL {
                            filePath = imageUrl.path
                            
                            if filePath != nil , fileSize != nil, identitier != nil {
                                block(filePath!, fileSize!, identitier!)
                            } else {
                                AlbumDebug("requestAllInfo：获取失败, \(String(describing: filePath)),\(String(describing: fileSize)),\(String(describing: identitier))")
                            }
                        } else {
                            AlbumDebug("requestAllInfo： 获取失败，imageUrl 为空")
                        }
                        
                    } else {
                        AlbumDebug("requestAllInfo： 获取失败，info 为空")
                    }
                }
            })
            
        } else if self.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .current
            options.deliveryMode = .automatic
            
            PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: { (asset, audioMix, info) in
                var filePath: String?, fileSize: Double?, identitier: String?
                if let urlAsset: AVURLAsset = asset as? AVURLAsset {
                    filePath = urlAsset.url.path
                    fileSize = self.getFileSize(url: urlAsset.url)
                    identitier = self.localIdentifier
                    if filePath != nil , fileSize != nil, identitier != nil {
                        block(filePath!, fileSize!, identitier!)
                    } else {
                        AlbumDebug("requestAllInfo：获取失败, \(String(describing: filePath)),\(String(describing: fileSize)),\(String(describing: identitier))")
                    }
                } else {
                    AlbumDebug("requestAllInfo: 获取urlAasset 失败")
                }
            })
        } else {
            AlbumDebug("requestAllInfo： 获取失败，文件类型超出处理范围")
        }
    }
    
    fileprivate func getFileSize(url: URL) -> Double {
        do {
            let handle: FileHandle = try FileHandle.init(forReadingFrom: url)
            handle.seekToEndOfFile()
            let size = Double(handle.offsetInFile)
            handle.closeFile()
            AlbumDebug("filesize: \(size)")
            return size
        } catch {
            AlbumDebug("\(error)")
            return 0.0
        }
    }
}
