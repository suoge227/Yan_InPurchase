//
//  NoNetworkView.swift
//  ChatAI
//
//  Created by HavinZhu on 2023/3/6.
//

import Alamofire


class NoNetworkView: UIView {
    
    lazy var imageView: UIImageView = {
        let object = UIImageView()
        object.image = UIImage(named: "Empty")
        return object
    }()
    
    lazy var titleLabel: UILabel = {
        let object = UILabel()
        object.font = .systemFont(ofSize: 17, weight: .medium)
        object.text = "网络连接"
        object.textColor = .white
        return object
    }()
    
    lazy var textLabel: UILabel = {
        let object = UILabel()
        object.font = .systemFont(ofSize: 15)
        object.text = "请检查网络连接后重试"
        object.textColor = .white
        return object
    }()
    

    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        
        backgroundColor = .brown
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(textLabel)
        
        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(38)
            make.bottom.equalTo(self.snp.centerY)
            make.centerX.equalToSuperview()
        }
        textLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }


    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    


    func show() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self, let window = UIApplication.shared.keyWindow else { return }
            self.alpha = 1.0
            window.addSubview(self)
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.alpha = 0.0
        } completion: { [weak self] success in
            self?.removeFromSuperview()
        }
    }

    
}
