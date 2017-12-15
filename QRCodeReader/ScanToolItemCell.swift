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
                    icon = "icon_scan_flash"
                case .quickScan:
                    title = "极速扫描"
                    icon = "icon_scan_scan"
                case .manual:
                    title = "手动输入"
                    icon = "icon_scan_flash"
                case .voice:
                    title = "语音输入"
                    icon = "icon_scan_scan"
                case .takePhoto:
                    title = "扫完即拍"
                    icon = "icon_scan_voice"
                case .inputUnsign:
                    title = "导入未签单号"
                    icon = "icon_scan_flash"
                case .barGunInput:
                    title = "扫描枪输入"
                    icon = "icon_scan_voice"
                }
            }
            imageView.image = UIImage(named: icon)
            titleLabel.text = title
        }
    }
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var titleLabel: UILabel!
}
