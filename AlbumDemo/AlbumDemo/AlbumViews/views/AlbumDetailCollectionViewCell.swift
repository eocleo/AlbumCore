//
//  AlbumDetailCollectionViewCell.swift
//  FileMail
//
//  Created by leo on 2017/5/13.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit
import Photos

class AlbumDetailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var disableView: UIView!
    
    var localIdentify: String?
    
    var onClick: ((_ cell: AlbumDetailCollectionViewCell, _ button: UIButton) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func selectAction(_ sender: UIButton) {
//        sender.isSelected = !sender.isSelected
        AlbumDebug("selectAction")
        if nil != onClick {
            onClick! (self, sender)
        }
    }
}
