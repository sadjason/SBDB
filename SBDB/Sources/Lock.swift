//
//  Lock.swift
//  SBDB
//
//  Created by zhangwei on 2019/10/28.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

/// An `os_unfair_lock` wrapper.
final class UnfairLock {
    private let unfairLock: os_unfair_lock_t

    init() {
        unfairLock = .allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock())
    }

    deinit {
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }

    public func lock() {
        os_unfair_lock_lock(unfairLock)
    }

    public func unlock() {
        os_unfair_lock_unlock(unfairLock)
    }

    func protect<T>(_ closure: () -> T) -> T {
        lock(); defer { unlock() }
        return closure()
    }

    func protect(_ closure: () -> Void) {
        lock(); defer { unlock() }
        return closure()
    }
}
