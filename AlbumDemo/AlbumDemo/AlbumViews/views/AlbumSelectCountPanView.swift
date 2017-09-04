//
//  AlbumSelectCountPanView.swift
//  FileMail
//
//  Created by leo on 2017/5/17.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit
import QuartzCore

class AlbumSelectCountPanView: UIView {

    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    
    var doneCallBack:(() -> Void)?

    class func createFromXib() -> AlbumSelectCountPanView? {
        return Bundle.main.loadNibNamed("AlbumSelectCountPanView", owner: nil, options: nil)?.first as? AlbumSelectCountPanView
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.doneButton.layer.cornerRadius = 4.0
        self.doneButton.layer.masksToBounds = true
        
        self.doneButton.setBackgroundImage(UIImage.imageWith(color: UIColor.mainScheme, size: self.doneButton.frame.size), for: .normal)
        self.doneButton.setBackgroundImage(UIImage.imageWith(color: UIColor.placeholderText, size: self.doneButton.frame.size), for: .disabled)
    }
    
    @IBAction func doneAction(_ sender: UIButton) {
        if let done = doneCallBack {
            done()
        }
    }
}
