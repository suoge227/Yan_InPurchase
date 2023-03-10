//
//  NetworkAPI.swift
//  Yan_InPurchase
//
//  Created by suoge on 2023/3/8.
//

import Foundation
import Alamofire

class NetworkAPI: NSObject {

    static let shared = NetworkAPI()

    var noNetworkView: NoNetworkView? = NoNetworkView()

    private override init() {
        super.init()
    }

    func fetchNetworkStatus(completion: @escaping (Bool)->Void) {
        let manager = NetworkReachabilityManager()
        manager?.startListening { status in
            switch status {
            case .reachable(.ethernetOrWiFi):
                completion(true)
            case .reachable(.cellular):
                completion(true)
            case .notReachable:
                completion(false)
            default:
                print("未知")
            }
        }
    }


    func NoNetworkViewShow() {
        noNetworkView?.show()
    }

    func NoNetworkViewHide() {
        noNetworkView?.hide()
    }

}
