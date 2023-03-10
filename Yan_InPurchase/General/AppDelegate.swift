//
//  AppDelegate.swift
//  Yan_InPurchase
//
//  Created by suoge on 2023/3/8.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        DispatchQueue.global().async {
            PurchaseAPI.shared.completeTransactions()
        }

        PurchaseAPI.getUserItem()
//        _ = PurchaseAPI.deleteFromKeychain()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: ViewController())
        window?.makeKeyAndVisible()

        return true
    }


    func applicationDidBecomeActive(_ application: UIApplication) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NetworkAPI.shared.fetchNetworkStatus { isReachable in
                if isReachable {
                    NetworkAPI.shared.NoNetworkViewHide()
                } else {
                    NetworkAPI.shared.NoNetworkViewShow()
                }
            }
        }
    }
}

