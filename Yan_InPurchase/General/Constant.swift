//
//  Constant.swift
//  Yan_InPurchase
//
//  Created by suoge on 2023/3/8.
//

import Foundation

struct ProductID {
    static let weekID = "com.air.share.weekly"
    static let yearID = "com.air.share.yearly"
    static let secretCode = "412e7ac9a6ce43438a4c3192764a267a"//生成内购项目之后所生成的安全码
}

struct ProductUserdefaultKeys {
    static let WeekPrice = "WeelPrice"
    static let YearPrice = "YearPrice"
    static let hasPurchasedItem = "hasPurchasedItem"
}
