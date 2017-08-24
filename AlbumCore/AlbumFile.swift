//
//  AlbumFile.swift
//  FileMail
//
//  Created by leo on 2017/5/16.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit
import Photos

enum FileFromType {
    case sandbox
    case album
    case other
}

class AlbumFile: NSObject {
    var fileFrom: FileFromType?      //来自相册或者沙盒
    var fileSize: Double?
    var fileName: String? {
        get {
            return filePath?.components(separatedBy: "/").last
        }
    }
    var fileIdentifier: String?
    var filePath: String?
    var asset: PHAsset?
    
    init(with asset: PHAsset) {
        super.init()
        self.fileFrom = .album
        self.asset = asset
        self.fileIdentifier = asset.localIdentifier
    }
}
