//
//  ViewController.swift
//  Yan_InPurchase
//
//  Created by suoge on 2023/3/8.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    var selectedType: PurchaseProductType = .none {
        didSet {
            switch selectedType {
            case .none:
                weekButton.layer.borderWidth = 0
                yearButton.layer.borderWidth = 0
            case .WeekProduct:
                yearButton.layer.borderWidth = 0
                weekButton.layer.borderWidth = 2
                weekButton.layer.borderColor = UIColor.yellow.cgColor
            case .YearProduct:
                weekButton.layer.borderWidth = 0
                yearButton.layer.borderWidth = 2
                yearButton.layer.borderColor = UIColor.yellow.cgColor
            }
        }
    }

    lazy var weekButton: UIButton = {
        let button = UIButton()
        button.setTitle("Week: ", for: .normal)
        button.backgroundColor = .blue
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        button.addTarget(self, action: #selector(weekButtonTap), for: .touchUpInside)
        return button
    }()

    lazy var yearButton: UIButton = {
        let button = UIButton()
        button.setTitle("Year: ", for: .normal)
        button.backgroundColor = .red
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        button.addTarget(self, action: #selector(yearButtonTap), for: .touchUpInside)
        return button
    }()

    lazy var buyButton: UIBarButtonItem = {
        return .init(title: "Buy", style: .plain, target: self, action: #selector(buy))
    }()

    lazy var restoreButton: UIBarButtonItem = {
        return .init(title: "Restore", style: .plain, target: self, action: #selector(restore))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }


}

extension ViewController {
    func setupUI() {
        view.backgroundColor = .white
        navigationItem.rightBarButtonItems = [buyButton, restoreButton]
        view.addSubview(weekButton)
        view.addSubview(yearButton)
        NetworkAPI.shared.fetchNetworkStatus { [weak self] isReachable in
            guard let self = self else { return }
            if isReachable {
                self.weekButton.isHidden = false
                self.yearButton.isHidden = false
                PurchaseAPI.shared.getProductsInfo {[weak self]  in
                    guard let self = self else { return }
                    self.weekButton.setTitle("week: \(PurchaseAPI.weekPrice)", for: .normal)
                    self.yearButton.setTitle("year: \(PurchaseAPI.yearPrice)", for: .normal)
                    self.updateMemberStatus()
                }

            } else {
                NetworkAPI.shared.NoNetworkViewShow()
                self.weekButton.isHidden = true
                self.yearButton.isHidden = true
            }
        }
    }

    func setupConstraints() {
        weekButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(50)
        }

        yearButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(weekButton.snp.bottom).offset(20)
            make.height.equalTo(50)
        }
    }

    func updateMemberStatus() {
        guard let item = PurchaseAPI.readFromKeychain(key: ProductUserdefaultKeys.hasPurchasedItem),
              !PurchaseAPI.shared.isOverdue, item.isPurchased else {
            return
        }
        if item.purchaseProductID == ProductID.weekID {
            selectedType = .WeekProduct
            self.configuratePriceButton()
        } else if item.purchaseProductID == ProductID.yearID {
            selectedType = .YearProduct
            self.configuratePriceButton()
        }
    }
}

extension ViewController {
    @objc func weekButtonTap() {
        selectedType = .WeekProduct
    }

    @objc func yearButtonTap() {
        selectedType = .YearProduct
    }

    @objc func buy() {
        guard let productID = selectedType.productID else {
            return
        }
        let loadView = LoadingView(frame: .zero)
        loadView.center = Util.topViewController().view.center
        Util.topViewController().view.addSubview(loadView)
        PurchaseAPI.shared.purchaseProduct(prductID: productID) { isSuccess in
            loadView.removeFromSuperview()
            if isSuccess {
                print("购买成功")//toast提示购买成功
                guard var item = PurchaseAPI.readFromKeychain(key: ProductUserdefaultKeys.hasPurchasedItem) else {
                    return
                }
                item.purchaseProductID = productID
                item.isPurchased = true
                _ = PurchaseAPI.saveToKeychain(key: ProductUserdefaultKeys.hasPurchasedItem, value: item)
                print(item)
            } else {
                print("购买失败")//toast提示购买失败
            }
        } updateUICloure: {[weak self]  in
            guard let self = self else { return }
            //UI更新
            self.configuratePriceButton()
        }
    }

    func configuratePriceButton() {
        switch self.selectedType {
        case .WeekProduct:
            self.weekButton.setTitle(__("已购买"), for: .normal)
        case .YearProduct:
            self.yearButton.setTitle(__("已购买"), for: .normal)
            self.weekButton.isHidden = true
        default:
            fatalError()
        }
    }

    @objc func restore() {
        PurchaseAPI.shared.restorePurchase(completion: { isSuccess in
            if isSuccess {
                //恢复成功
            } else {
                print("`    `")
            }
        }) {
            //恢复成功更新UI
        }
    }

}
