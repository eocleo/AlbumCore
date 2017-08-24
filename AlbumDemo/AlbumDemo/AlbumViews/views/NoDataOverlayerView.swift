//
//  NoDataOverlayerView.swift
//  FileMail
//
//  Created by leo on 2017/5/27.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit

class NoDataOverlayerView: OverlayerView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!

    static func createWith(image: UIImage?, message: String?) -> NoDataOverlayerView? {
        
        let overlayerView: NoDataOverlayerView? = Bundle.main.loadNibNamed("NoDataOverlayerView", owner: nil , options: nil)?.first as? NoDataOverlayerView
        overlayerView?.setup(image: image, message: message)
        if (overlayerView == nil) {
            AlbumDebug("NoDataOverlayerView 创建失败")
        }
        return overlayerView
    }
    
    func setup(image: UIImage?, message: String?) -> Void {
        self.imageView.image = image
        self.descriptionLabel.text = message
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        AlbumDebug("\(String(describing: imageView.image)),\(String(describing: descriptionLabel.text))")
    }
}
