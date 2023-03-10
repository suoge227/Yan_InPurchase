//
//  Util.swift
//  Toolkit
//
//  Created by lsc on 27/02/2017.
//

import Foundation
import UIKit
import StoreKit
import SafariServices
import Photos

// MARK: - Localizations
public func __(_ text: String) -> String {
    return NSLocalizedString(text, tableName: "Localizations", bundle: Bundle.main, value: "", comment: "")
}


public class Util {
    
    /// 是否有刘海
    @available(iOSApplicationExtension, unavailable)
    public static var hasTopNotch: Bool {
        if #available(iOS 11.0, tvOS 11.0, *) {
            // with notch: 44.0 on iPhone X, XS, XS Max, XR.
            // without notch: 20.0 on iPhone 8 on iOS 12+.
            return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
        }
        
        return false
    }
    
    /// 是否有底部Home区域
    @available(iOSApplicationExtension, unavailable)
    public static var hasBottomSafeAreaInsets: Bool {
        if #available(iOS 11.0, tvOS 11.0, *) {
            // with home indicator: 34.0 on iPhone X, XS, XS Max, XR.
            return UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0 > 0
        }
        
        return false
    }
    
    /// 安全区
    @available(iOSApplicationExtension, unavailable)
    public static var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, tvOS 11.0, *) {
            if let safeAreaInsets = UIApplication.shared.delegate?.window??.safeAreaInsets {
                return safeAreaInsets
            } else if let safeAreaInsets = UIApplication.shared.keyWindow?.safeAreaInsets {
                return safeAreaInsets
            }
        }
    
        return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    }
    
    /// 返回最顶层的 view controller
    @available(iOSApplicationExtension, unavailable)
    public static func topViewControllerOptional() -> UIViewController? {
        var keyWinwow = UIApplication.shared.keyWindow
        if keyWinwow == nil {
            keyWinwow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        }
        if #available(iOS 13.0, *), keyWinwow == nil {
            keyWinwow = UIApplication.shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first
        }
        
        var top = keyWinwow?.rootViewController
        if top == nil {
            top = UIApplication.shared.delegate?.window??.rootViewController
        }
        
        while true {
            if let presented = top?.presentedViewController {
                top = presented
            } else if let nav = top as? UINavigationController {
                top = nav.visibleViewController
            } else if let tab = top as? UITabBarController {
                top = tab.selectedViewController
            } else {
                break
            }
        }
        
        return top
    }
    
    @available(iOSApplicationExtension, unavailable)
    public static func topViewController() -> UIViewController {
        return topViewControllerOptional()!
    }

    /// 返回本地化的app名称
    public static func appName() -> String {
        if let appName = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
            return appName
        } else if let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return appName
        } else {
            return Bundle.main.infoDictionary?["CFBundleName"] as! String
        }
    }
    
    /// 返回版本号
    public static func appVersion() -> String {
        return (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    }
    
    public static func buildNumber() -> String {
        return (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? ""
    }

    /// 自定义 UINavigationbar 返回按钮
    public static func customNavigationBarBackIndicator(navigationItem: UINavigationItem, navigationBar: UINavigationBar?, image: UIImage) {
        let backButtonItem = UIBarButtonItem(title: " ", style: .plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButtonItem
        if let navigationBar = navigationBar {
            navigationBar.backIndicatorTransitionMaskImage = image
            navigationBar.backIndicatorImage = image
        }
    }
    
    class func openURL(_ withString: String, failure: (@escaping () -> Void) = {}) {
        if let url = URL(string: withString) {
            if UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            } else {
                failure()
            }
        }
    }
    
}

// MARK: - Photos
extension Util {
    
    class func accessPhotos(withHandler: @escaping () -> Void) {
        var isAuthorized: Bool? {
            didSet {
                DispatchQueue.main.async {
                    if (isAuthorized != nil) && isAuthorized! {
                        withHandler()
                    } else {
                        showPhotosAuthorizationAlert()
                    }
                }
            }
        }
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == .authorized {
                    isAuthorized = true
                }
            }
        case .authorized:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }
    
    class func showPhotosAuthorizationAlert() {
        let alertController = UIAlertController(
            title: __("无法访问照片"),
            message: String(format: __("您需要设置允许%@访问“照片”权限才可以使用"), Util.appName()) ,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: __("取消"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: __("去设置"), style: .default) { (action) in
            openURL(UIApplication.openSettingsURLString)
        })
        Util.topViewController().present(alertController, animated: true, completion: nil)
    }
    
}

public extension Util {
    static let pixelOne: CGFloat = {
        return 1 / UIScreen.main.scale
    }()
    
    static let isSimulator: Bool = {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }()
    
    static let isIPad: Bool = {
        return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad
    }()
    
    @available(iOSApplicationExtension, unavailable)
    static let isZoomedMode: Bool = {
        if isIPad {
            return false
        }
        let nativeScale = UIScreen.main.nativeScale
        var scale = UIScreen.main.scale
        
        let shouldBeDownsampledDevice = UIScreen.main.nativeBounds.size.equalTo(CGSize(width: 1080, height: 1920))
        if shouldBeDownsampledDevice {
            scale /= 1.15;
        }
        return nativeScale > scale
    }()
    
    @available(iOSApplicationExtension, unavailable)
    static let isRegularScreen: Bool = {
        return isIPad || (!isZoomedMode && (is61InchScreen || is61InchScreen || is55InchScreen))
    }()
    
    /// 是否横竖屏，用户界面横屏了才会返回true
    @available(iOSApplicationExtension, unavailable)
    static var isLandscape: Bool {
        return UIApplication.shared.statusBarOrientation.isLandscape
    }
    
    /// 屏幕宽度，跟横竖屏无关
    @available(iOSApplicationExtension, unavailable)
    static let deviceWidth = isLandscape ? UIScreen.main.bounds.height : UIScreen.main.bounds.width

    /// 屏幕高度，跟横竖屏无关
    @available(iOSApplicationExtension, unavailable)
    static let deviceHeight = isLandscape ? UIScreen.main.bounds.width : UIScreen.main.bounds.height
    
    /// tabbar  高度
    @available(iOSApplicationExtension, unavailable)
    static var tabBarHeight: CGFloat {
        if isIPad {
            if hasBottomSafeAreaInsets {
                return 65
            } else {
                if #available(iOS 12.0, *) {
                    return 50
                } else {
                    return 49
                }
            }
        } else {
            let height: CGFloat
            if isLandscape, !isRegularScreen {
                height = 32
            } else {
                height = 49
            }
            return height + safeAreaInsets.bottom
        }
    }
}

@available(iOSApplicationExtension, unavailable)
public extension Util {
    static let is65InchScreen: Bool = {
        if CGSize(width: deviceWidth, height: deviceHeight) != screenSizeFor65Inch {
            return false
        }
        let deviceModel = Util.deviceModel()
        if deviceModel != "iPhone11,4" && deviceModel == "iPhone11,6" && deviceModel != "iPhone12,5" {
            return false
        }
        return true
    }()
    
    static let is61InchScreen: Bool = {
        if CGSize(width: deviceWidth, height: deviceHeight) != screenSizeFor61Inch {
            return false
        }
        let deviceModel = Util.deviceModel()
        if deviceModel != "iPhone11,8" && deviceModel == "iPhone12,1" {
            return false
        }
        return true
    }()

    /// 原始设备型号
    static func deviceModel() -> String {
        if Util.isSimulator {
            return ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"
        }
        var systemInfo = utsname()
        uname(&systemInfo)

        if let utf8String = NSString(bytes: &systemInfo.machine, length: Int(_SYS_NAMELEN), encoding: String.Encoding.ascii.rawValue)?.utf8String {
            if let versionCode = String(validatingUTF8: utf8String) {
                return versionCode
            }
        }

        return "unknown"
    }
    
    
    static let is58InchScreen: Bool = {
        return CGSize(width: deviceWidth, height: deviceHeight) == screenSizeFor58Inch
    }()
    
    static let is55InchScreen: Bool = {
        return CGSize(width: deviceWidth, height: deviceHeight) == screenSizeFor55Inch
    }()
    
    static let is47InchScreen: Bool = {
        return CGSize(width: deviceWidth, height: deviceHeight) == screenSizeFor47Inch
    }()
    
    static let is40InchScreen: Bool = {
        return CGSize(width: deviceWidth, height: deviceHeight) == screenSizeFor40Inch
    }()
    
    static var is35InchScreen: Bool {
        return CGSize(width: deviceWidth, height: deviceHeight) == screenSizeFor35Inch
    }
    
    static var screenSizeFor65Inch: CGSize {
        return CGSize(width: 414, height: 896)
    }
    
    static var screenSizeFor61Inch: CGSize {
        return CGSize(width: 414, height: 896)
    }

    static var screenSizeFor58Inch: CGSize {
        return CGSize(width: 375, height: 812)
    }

    static var screenSizeFor55Inch: CGSize {
        return CGSize(width: 414, height: 736)
    }

    static var screenSizeFor47Inch: CGSize {
        return CGSize(width: 375, height: 667)
    }
    
    static var screenSizeFor40Inch: CGSize {
        return CGSize(width: 320, height: 568)
    }

    static var screenSizeFor35Inch: CGSize {
        return CGSize(width: 320, height: 480)
    }
}

extension Util {
    
    @available(iOSApplicationExtension, unavailable, message: "This is unavailable: Use view controller based solutions where appropriate instead.")
    public static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    public static func requestReview() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        } else {
            // Fallback on earlier versions
        }
    }
}

extension Util {
    
    public static func countryCode() -> String {
        return NSLocale.current.regionCode ?? ""
    }
    
    public static func languageCode() -> String {
        let languageCode = NSLocale.preferredLanguages.first ?? ""
        
        if languageCode.starts(with: "zh-HK") {
            return "zh-Hant"
        }
        
        var components = languageCode.split(separator: "-")
        if components.count >= 2, let suffix = components.last, suffix == suffix.uppercased() { // 如 pt-PT、pt-BR 则输出 pt
            components.removeLast()
            return components.joined(separator: "-")
        }
        
        return languageCode
    }
}

extension Util {
    static func webURL(urlStr: String) -> URL? {
        if var urlComponents = URLComponents(string: urlStr) {
            var queryItems = [URLQueryItem]()
            queryItems.append(URLQueryItem(name: "lang", value: Util.languageCode()))
            queryItems.append(URLQueryItem(name: "version", value: Util.appVersion()))
            urlComponents.queryItems = queryItems
            if let url = urlComponents.url {
                return url
            }
        }
        return nil
    }
}

// MARK: - Path
extension Util {
    /// 连接路径
    public static func join(component: String...) -> String {
        let components = component
        var result: NSString = ""
        for c in components {
            if result.length == 0 {
                result = c as NSString
            }
            else {
                result = result.appendingPathComponent(c) as NSString
            }
        }
        
        return result as String
    }
    
    public static var documentsPath: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    public static var libraryPath: String {
        return NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
    }
    
    public static var cachesPath: String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    }
    
    public static var moduleName: String? {
        var str = NSStringFromClass(Util.self) as? String
        return str?.components(separatedBy: ".").first
    }
}

extension Util {
  public static func browseURL(urlStr: String) {
    if let url = URL(string: urlStr) {
      let safariVC = SFSafariViewController(url: url)
      safariVC.modalPresentationStyle = .fullScreen
      Util.topViewController().present(safariVC, animated: true, completion: nil)
    }
  }
}

extension Util {
    public static func resignFirstResponder() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
