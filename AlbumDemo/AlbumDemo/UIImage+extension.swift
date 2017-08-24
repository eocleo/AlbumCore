//
//  UIImage+extension.swift
//  AlbumDemo
//
//  Created by leo on 2017/8/23.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit

extension UIImage {
    func zoom(toSize: CGSize, cornerRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(toSize, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        let path: UIBezierPath = UIBezierPath(roundedRect: CGRect.init(origin: CGPoint.zero, size: toSize), cornerRadius: cornerRadius)
        
        context?.addPath(path.cgPath)
        context?.clip()
        self.draw(in: CGRect.init(origin: CGPoint.zero, size: toSize))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    class func imageWith(color: UIColor, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, true, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect.init(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
