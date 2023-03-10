//
//  Date.swift
//  Yan_InPurchase
//
//  Created by suoge on 2023/3/10.
//

import Foundation

extension Date {
    public func daysSince(date: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: self, to: date)
        return -1 * (components.day ?? 0)
    }
}
