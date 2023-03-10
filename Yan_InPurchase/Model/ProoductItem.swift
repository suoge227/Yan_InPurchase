//
//  ProoductItem.swift
//  Yan_InPurchase
//
//  Created by suoge on 2023/3/8.
//

import Foundation


enum PurchaseProductType: String {
    case none
    case WeekProduct
    case YearProduct

    var productID: String? {
        switch self {
        case .none:
            return nil
        case .WeekProduct:
            return ProductID.weekID
        case .YearProduct:
            return ProductID.yearID
        }
    }
}

struct UserItem: Encodable, Decodable {
    var userID: String = UUID().uuidString
    var isPurchased: Bool
    var purchaseProductID: String?
    var OverdueDate: Date?
    var useDate: Date = Date()

    func isUseFree() -> Bool{
        guard let item = PurchaseAPI.readFromKeychain(key: ProductUserdefaultKeys.hasPurchasedItem) else {
            return true
        }

        if Date().daysSince(date: item.useDate) == 3 {
            return false
        } else {
            return true
        }
    }
}
