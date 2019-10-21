//
//  AppDelegate.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/17.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import UIKit
import SQLite3

extension AppDelegate {
    private static var rootPath: String = NSSearchPathForDirectoriesInDomains(
        .documentDirectory,
        .userDomainMask,
        true
    ).first!

    fileprivate func path(for userId: Int64) throws -> String {
        let userPath: String = "\(AppDelegate.rootPath)/\(userId)"
        if !FileManager.default.fileExists(atPath: userPath) {
            try FileManager.default .createDirectory(atPath: userPath, withIntermediateDirectories: true, attributes: nil)
        }
        return "\(userPath)/db.sqlite3"
    }

}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        let pointer: OpaquePointer? = nil
        print("strstr: \(String(cString: sqlite3_errmsg(pointer)))")

        sqlite3_close(pointer)

        let count = 2
        let alignment = MemoryLayout<Int>.alignment
        let stride = MemoryLayout<Int>.stride
        let byteCount = stride * count

        // Using Raw Pointers
        do {
            let rawPointer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: alignment)
            defer {
                rawPointer.deallocate()
            }
            rawPointer.storeBytes(of: 42, as: Int.self)
            rawPointer.advanced(by: stride).storeBytes(of: 31, as: Int.self)
            let v1 = rawPointer.load(as: Int.self)
            print(v1)
            let v2 = rawPointer.load(fromByteOffset: stride, as: Int.self)
            print(v2)
        }

        // Using Typed Pointers
        do {
            let intPointer = UnsafeMutablePointer<Int>.allocate(capacity: 2)
            defer {
                intPointer.deinitialize(count: 2)
                intPointer.deallocate()
            }
            intPointer.initialize(to: 42)
            (intPointer + 1).initialize(to: 31)

            let v1: Int = intPointer.pointee
            print(v1)
            let v2: Int = (intPointer + 1).pointee
            print(v2)
        }

        // Converting Raw Pointers to Typed Pointers
        do {
            let rawPointer = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: alignment)
            defer {
                rawPointer.deallocate()
            }
            rawPointer.storeBytes(of: 42, as: Int.self)
            rawPointer.advanced(by: stride).storeBytes(of: 31, as: Int.self)

            let intPointer: UnsafeMutablePointer<Int> = rawPointer.bindMemory(to: Int.self, capacity: 2)
            let v1 = intPointer.pointee
            print(v1)
            let v2 = (intPointer + 1).pointee
            print(v2)
        }

        if let path = try? path(for: 1004),
            let db = try? Database(path: path)
        {
            print("connecting datapath succeed")
            try! db.exec(sql: "create table if not exists conversation (id integer primary key not null, name)")
            try! db.exec(sql: "insert into conversation(name) values ('王琰')")
            try! db.exec(sql: "insert into conversation(name) values (1234)")
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

