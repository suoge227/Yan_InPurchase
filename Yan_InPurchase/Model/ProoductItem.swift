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


struct ProoductItem: Encodable, Decodable {
    var productID: String
    var price: String
    var OverdueDate: Date
}


class UserItem: NSObject {
    
}
