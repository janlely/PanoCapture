//
//  Channel.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/24.
//

import Foundation

class Channel<T> {
    private var queue = DispatchQueue(label: "channelQueue", attributes: .concurrent)
    private var semaphore = DispatchSemaphore(value: 0)
    private var items: [T?] = []

    func send(_ item: T?) {
        queue.async(flags: .barrier) {
            self.items.append(item)
            self.semaphore.signal()
        }
    }

    func receive() -> T? {
        semaphore.wait()
        return queue.sync(flags: .barrier) {
            self.items.removeFirst()
        }
    }
}
