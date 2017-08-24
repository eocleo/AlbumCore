//
//  LimitRightsOverlayerView.swift
//  FileMail
//
//  Created by leo on 2017/5/27.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit

class LimitRightsOverlayerView: OverlayerView {

    @IBOutlet weak var imageView: UIImageView!

    static func createWith(image: UIImage?) -> LimitRightsOverlayerView? {
        let overlayerView: LimitRightsOverlayerView? = Bundle.main.loadNibNamed("LimitRightsOverlayerView", owner: nil, options: nil)?.first as? LimitRightsOverlayerView
        overlayerView?.setup(image: image)
        return overlayerView
    }
    
    func setup(image: UIImage?) -> Void {
        self.imageView.image = image
    }
 
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
