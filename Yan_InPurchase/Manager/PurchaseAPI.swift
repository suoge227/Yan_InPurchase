//
//  PurchaseAPI.swift
//  Yan_InPurchase
//
//  Created by suoge on 2023/3/8.
//

import Foundation
import SwiftyStoreKit

class PurchaseAPI: NSObject {

    static let shared = PurchaseAPI()

    #if DEBUG
    let service = AppleReceiptValidator.VerifyReceiptURLType.sandbox
    #else
    let service = AppleReceiptValidator.VerifyReceiptURLType.production
    #endif

    static var weekPrice: String {
        set {
            UserDefaults.standard.set(newValue, forKey: ProductUserdefaultKeys.WeekPrice)
        }
        get {
            if let price = UserDefaults.standard.string(forKey: ProductUserdefaultKeys.WeekPrice) {
                return price
            } else {
                return "328"
            }
        }
    }

    static var yearPrice: String {
        set {
            UserDefaults.standard.set(newValue, forKey: ProductUserdefaultKeys.YearPrice)
        }
        get {
            if let price = UserDefaults.standard.string(forKey: ProductUserdefaultKeys.YearPrice) {
                return price
            } else {
                return "6666"
            }
        }
    }

    /// 订阅是否过期
    var isOverdue: Bool {
        let currentDate = Date()
        guard let item = PurchaseAPI.readFromKeychain(key: ProductUserdefaultKeys.hasPurchasedItem) else {
            return false
        }
        if item.OverdueDate.compare(currentDate) == .orderedAscending {
            return true
        } else {
            return false
        }

    }

    ///在启动时添加应用程序的观察者可确保在应用程序的所有启动过程中都会持续，从而允许应用程序接收所有支付队列通知
    func completeTransactions() {
        SwiftyStoreKit.completeTransactions() { [weak self] purchases in
            guard let _ = self else { return }
            for purchase in purchases {
                if purchase.transaction.transactionState == .purchased || purchase.transaction.transactionState == .restored {
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                }
            }
        }
    }

    //获取所有产品信息
    func getProductsInfo(completion:@escaping ()-> Void, updateUIClosure: ()->Void) {
        SwiftyStoreKit.retrieveProductsInfo([ProductID.weekID, ProductID.yearID]) { result in
            if result.error == nil {
                for product in result.retrievedProducts {
                    print("ID: \(product.productIdentifier), price: \(product.localizedPrice!)")

                    if let priceString = product.localizedPrice {
                        if product.productIdentifier == ProductID.yearID {
                            PurchaseAPI.yearPrice = priceString
                        } else if product.productIdentifier == ProductID.weekID {
                            PurchaseAPI.weekPrice = priceString
                        }
                    }
                }
                if let invalidProductId = result.invalidProductIDs.first {
                    print("无效的ProductId: \(invalidProductId)")
                }
            } else {
                print("获取信息失败：\(result.error)")
            }
            completion()
        }
    }

    ///购买
    func purchaseProduct(prductID: String, completion:@escaping (Bool)-> Void, updateUI: ()->Void) {
        if SwiftyStoreKit.canMakePayments {
            SwiftyStoreKit.purchaseProduct(prductID, quantity: 1) { [weak self] purchaseResult in
                guard let self = self else { return }
                switch purchaseResult {
                case .success(purchase: let purchase):
                    if purchase.productId == ProductID.weekID ||
                        purchase.productId ==  ProductID.yearID
                    {
                        self.verifyPurchase (productID: prductID){ isSuccssed in
                            completion(isSuccssed)
                        }
                    }

                case .error(error: let error):
                    print("购买失败: \(error.localizedDescription)")
                    completion(false)
                }

            }
        }
    }

    func isWeekVip(productID: String) -> Bool {
        if productID == ProductID.weekID {
            return true
        } else {
            return false
        }
    }


    ///恢复购买
    func restorePurchase(completion: @escaping (Bool) -> Void) {
        guard let item = PurchaseAPI.readFromKeychain(key: ProductUserdefaultKeys.hasPurchasedItem) else {
            return
        }
        SwiftyStoreKit.fetchReceipt(forceRefresh: true) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.verifyPurchase(productID: item.productID) { isSuccssed in
                    completion(!self.isOverdue)
                }
            case .error(let error):
                completion(false)
            }
        }
    }


    ///验证收据信息：.production为苹果验证，.sandbox为本地验证
    func verifyPurchase(productID: String ,completion: @escaping (Bool) -> Void) {
        let appleValidator = AppleReceiptValidator(service: service, sharedSecret: ProductID.secretCode)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) {  [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let receipt):
                self.vertify(productID: productID, receipt: receipt)
                print("当前时间: \(Date().description(with: Locale.current))")
                //购买完成，发送通知刷新UI
                completion(true)
            case .error(let error):
                print("Receipt verification failed: \(error)")
                completion(false)
            }
        }
    }

    func vertify(productID: String, receipt : ReceiptInfo) {
        let purchaseResult = SwiftyStoreKit.verifySubscription(
            ofType: .autoRenewable,
            productId: productID,
            inReceipt: receipt
        )
        switch purchaseResult {
        case .purchased(let expiryDate, _): // 订阅已购买，返回过期日期和收据中的订阅项目

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            print("purchased订阅过期时间: \(expiryDate.description(with: Locale.current))----\(formatter.string(from: expiryDate))") 

            //将购买的id、价格、过期时间保存至keychain
            PurchaseAPI.setPurchsedItemPriceAndID(productID: productID, price: self.isWeekVip(productID: productID) ? PurchaseAPI.weekPrice : PurchaseAPI.yearPrice, overDueDate: expiryDate)

        case .expired(let expiryDate, _): // 订阅已过期，返回过期日期和收据中的订阅项目
            print("expired订阅过期时间: \(expiryDate.description(with: Locale.current))")

        case .notPurchased:  // 订阅未购买
            break
        }
    }

}


extension PurchaseAPI {
    /// 存储Model到钥匙串
   static func saveToKeychain(key: String, value: ProoductItem) -> Bool {
       // 定义钥匙串访问权限
       let keychainAccessible = kSecAttrAccessibleWhenUnlocked
        let encoder = JSONEncoder()
        if let encodedValue = try? encoder.encode(value) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword as String,
                kSecAttrService as String: Bundle.main.bundleIdentifier ?? "",
                kSecAttrAccount as String: key,
                kSecValueData as String: encodedValue,
                kSecAttrAccessible as String:  keychainAccessible
            ]
            SecItemDelete(query as CFDictionary) // 先删除已有的
            let status = SecItemAdd(query as CFDictionary, nil)
            return status == errSecSuccess
        }
        return false
    }

    /// 从钥匙串中读取Model
    static  func readFromKeychain(key: String) -> ProoductItem? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "",
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            let decoder = JSONDecoder()
            if let productItem = try? decoder.decode(ProoductItem.self, from: data) {
                return productItem
            }
        }
        return nil
    }

    /// 从钥匙串中删除Model
    static func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "",
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }


    /////将购买的id、价格、过期时间保存至keychain
    static func setPurchsedItemPriceAndID(productID: String, price: String, overDueDate: Date) {
        let item = ProoductItem(productID: productID, price: price, OverdueDate: overDueDate)
            _ = PurchaseAPI.saveToKeychain(key: ProductUserdefaultKeys.hasPurchasedItem, value: item)
    }

}
