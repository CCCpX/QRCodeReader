//
//  ScanToolItemCell.swift
//  QRCodeReader
//
//  Created by chenpeixiang on 08/12/2017.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import UIKit

class ScanToolItemCell: UICollectionViewCell {
    open var type: ScanFunction! {
        didSet {
            var title = ""
            var icon = ""
            if let type = type {
                switch type {
                case .flash:
                    title = "闪光灯"
                    icon = "flash"
                case .quickScan:
                    title = "极速扫描"
                    icon = "flash"
                case .manual:
                    title = "手动输入"
                    icon = "manual"
                case .voice:
                    title = "语音输入"
                    icon = "flash"
                case .takePhoto:
                    title = "扫完即拍"
                    icon = "flash"
                case .inputUnsign:
                    title = "导入未签单号"
                    icon = "flash"
                case .barGunInput:
                    title = "扫描枪输入"
                    icon = "flash"
                }
            }
            imageView.image = UIImage(named: icon)
            titleLabel.text = title
        }
    }
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var titleLabel: UILabel!
}
