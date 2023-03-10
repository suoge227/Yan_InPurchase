//
//  LoadingView.swift
//  Yan_InPurchase
//
//  Created by suoge on 2023/3/10.
//

import UIKit

/*
 let loadView = LoadingView(frame: .zero)
 loadView.center = Util.topViewController().view.center
 Util.topViewController().view.addSubview(loadView)
 */

class LoadingView: UIView {

  lazy var loadImage: UIImageView = {
    let imageView = UIImageView(image: UIImage(named: "Loading"))
    imageView.contentMode = .scaleAspectFill
    return imageView
  }()

  override init(frame: CGRect) {
      super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
      setupUI()
      load()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  func setupUI() {
    addSubview(loadImage)
    backgroundColor = UIColor(hex: 0x161A20)
    layer.cornerRadius = 14
    layer.masksToBounds = true
    loadImage.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.size.equalTo(44)
    }

  }

  func load() {
    UIView.animate(withDuration: 1, delay: 0.0, options: .curveEaseOut, animations: {
      self.loadImage.transform = self.loadImage.transform.rotated(by: CGFloat(Double.pi))
    }) { finished in
      self.rotateAnimation(imageView: self.loadImage)
    }
  }


  func rotateAnimation(imageView:UIImageView) {
    let rotateAnimation = CABasicAnimation(keyPath:"transform.rotation")
    rotateAnimation.fromValue = 0.0
    rotateAnimation.toValue = CGFloat(.pi * 2.0)
    rotateAnimation.duration = 0.5
    rotateAnimation.repeatCount = .greatestFiniteMagnitude
    imageView.layer.add(rotateAnimation, forKey: nil)
  }

}



