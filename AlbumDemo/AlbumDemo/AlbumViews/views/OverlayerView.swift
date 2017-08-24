//
//  OverlayerView.swift
//  FileMail
//
//  Created by leo on 2017/5/27.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit

class OverlayerView: UIView {

    var showFrame: CGRect?

    func showOn(view: UIView) -> Void {
        if self.showFrame != nil {
            self.frame = self.showFrame!
        } else {
            self.frame = view.bounds
        }
        self.isOpaque = false
        runInMain {
            view.addSubview(self)
        }
//        self.alpha = 0.1
//        UIView.animate(withDuration: 0.3) {
//            self.alpha = 1.0
//        }
        AlbumDebug("showOn: \(self)")
    }
    
    func dismiss() -> Void {
        DispatchQueue.main.async {
            AlbumDebug("dismiss: \(self)")
            self.removeFromSuperview()
        }
    }

}
