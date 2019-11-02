//
//  AppDelegate.swift
//  SBDB
//
//  Created by zhangwei on 2019/11/2.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow.init(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.white
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        return true
    }
}

