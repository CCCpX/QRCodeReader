//
//  ScanInfo.swift
//  QRCodeReader
//
//  Created by chenpeixiang on 06/12/2017.
//  Copyright © 2017 chenpeixiang. All rights reserved.
//

import Foundation

struct ScanInfo {
    let sourceCode: Int
    let number: Int
    lazy var state: String = {
        return getState()
    }()
}

extension ScanInfo {
    fileprivate func getState() -> String {
        return "待定"
    }
}
