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
        return .init(title: "BUY", style: .plain, target: self, action: #selector(buy))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()

        updateMemberStatus()
    }


}

extension ViewController {
    func setupUI() {
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = buyButton
        view.addSubview(weekButton)
        view.addSubview(yearButton)
        NetworkAPI.shared.fetchNetworkStatus { [weak self] isReachable in
            guard let self = self else { return }
            if isReachable {
                self.weekButton.isHidden = false
                self.yearButton.isHidden = false
                let loadView = LoadingView(frame: .zero)
                loadView.center = Util.topViewController().view.center
                Util.topViewController().view.addSubview(loadView)
                PurchaseAPI.shared.getProductsInfo {[weak self]  in
                    guard let self = self else { return }
                    self.weekButton.setTitle("week: \(PurchaseAPI.weekPrice)", for: .normal)
                    self.yearButton.setTitle("year: \(PurchaseAPI.yearPrice)", for: .normal)
                    loadView.removeFromSuperview()
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
        if !PurchaseAPI.shared.isOverdue {
            guard let item = PurchaseAPI.readFromKeychain(key: ProductUserdefaultKeys.hasPurchasedItem) else {
                return
            }
            if item.productID == ProductID.weekID {
                selectedType = .WeekProduct
            } else if item.productID == ProductID.yearID {
                selectedType = .YearProduct
            }
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
            if isSuccess {
                print("购买成功")
            } else {
                print("购买失败")
            }
        }
    }
}
