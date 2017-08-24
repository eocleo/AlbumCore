//
//  Utils.swift
//  AlbumDemo
//
//  Created by leo on 2017/8/23.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit
import Toast_Swift

let SCREEN_HEIGHT = UIScreen.main.bounds.height
let SCREEN_WIDTH = UIScreen.main.bounds.width

func IsEmpty(string:String?) -> Bool {
    guard (string != nil) else {
        return true
    }
    return string!.isEmpty
}

func isString(_ string: String?, equalTo: String?) -> Bool {
    if string == nil && equalTo == nil {
        return true
    } else if string == nil || equalTo == nil {
        return false
    } else {
        return string?.compare(equalTo!) == .orderedSame
    }
}

func runInMain(block: @escaping () -> Void) -> Void {
    if Thread.current.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}

func Toast(message:String!) {
    if IsEmpty(string: message) { return }
    DispatchQueue.main.async {
        ToastView()?.makeToast(message, duration: 1.5, position: CGPoint.init(x: SCREEN_WIDTH/2.0, y: SCREEN_HEIGHT - 85.0))
    }
}

func ToastIn(view: UIView, message: String?) {
    DispatchQueue.main.async {
        var offset: CGFloat = 85.0
        if view.frame.size.height == SCREEN_HEIGHT - 64.0 {
            offset += 64.0
        }
        view.makeToast(message ?? "", duration: 1.5, position: CGPoint.init(x: SCREEN_WIDTH/2.0, y: SCREEN_HEIGHT - offset))
        
    }
}

func Toast(message:String!, duration:TimeInterval) {
    DispatchQueue.main.async {
        ToastView()?.makeToast(message, duration: duration, position:(.center))
    }
}

func ToastView() -> UIView? {
    return UIApplication.shared.delegate?.window??.rootViewController?.view
}

func ToastStartLoading() -> Void {
    DispatchQueue.main.async {
        ToastView()?.makeToastActivity(.center)
    }
}

func ToastStopLoading() {
    DispatchQueue.main.async {
        ToastView()?.hideToastActivity()
    }
}

func topWindow() -> UIWindow? {
    var top: UIWindow? = UIApplication.shared.keyWindow
    for wind in UIApplication.shared.windows {
        if let key = top {
            if wind.windowLevel > key.windowLevel {
                top = wind
            }
        } else {
            top = wind
        }
    }
    return top
}

class Utils: NSObject {

}
