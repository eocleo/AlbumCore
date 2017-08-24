//
//  UIViewController+extension.swift
//  AlbumDemo
//
//  Created by leo on 2017/8/23.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit

extension UIViewController {
    
    open func createNavButton(image: UIImage?, title: String?) -> UIButton {
        let button = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 44.0))
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setImage(image, for: .normal)
        button.setTitle(title, for: .normal)
        button.contentHorizontalAlignment = .left
        return button
    }
    
    open func addRightNav(button: UIButton) -> Void {
        let barButtonItem = UIBarButtonItem.init(customView: button)
        self.navigationItem.setRightBarButton(barButtonItem, animated: true)
    }
    
    open func addLeftNav(button: UIButton) -> Void {
        let barButtonItem = UIBarButtonItem.init(customView: button)
        self.navigationItem.setLeftBarButton(barButtonItem, animated: true)
    }
    
    open func addLeftNavButton(image: UIImage?, title: String?, sel: Selector) -> Void {
        let button = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 44.0))
        button.setTitleColor(UIColor.white, for: .normal)
        button.setImage(image, for: .normal)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: sel, for: .touchUpInside)
        let barItem = UIBarButtonItem.init(customView: button)
        self.navigationItem.setLeftBarButton(barItem, animated: true)
    }
    
    open func addRightNavButton(image: UIImage?, title: String?, sel: Selector) -> Void {
        let button = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 44.0))
        button.setTitleColor(UIColor.white, for: .normal)
        button.setImage(image, for: .normal)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.contentHorizontalAlignment = .right
        button.addTarget(self, action: sel, for: .touchUpInside)
        let barItem = UIBarButtonItem.init(customView: button)
        self.navigationItem.setRightBarButton(barItem, animated: true)
    }
}
