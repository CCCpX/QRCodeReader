//
//  QRScannerController.swift
//  QRCodeReader
//
//  Created by chenpeixiang on 06/12/2017.
//  Copyright © 2017 chenpeixiang. All rights reserved.
//

import UIKit
import AVFoundation

//FIX: 该页面从后台切到前台后，扫描的动画会停止!!!
class QRScannerController: UIViewController {
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var bottomView: UIView!
    
    fileprivate var captureSession: AVCaptureSession?
    fileprivate var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    fileprivate var qrCodeFrameView: UIView?
    
    fileprivate lazy var toolCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 80)
        let toolView = UICollectionView(frame: bottomView.bounds, collectionViewLayout: layout)
        toolView.register(UINib.init(nibName: "ScanToolItemCell", bundle: nil), forCellWithReuseIdentifier: "ScanToolItemCell")
        toolView.showsHorizontalScrollIndicator = false
        toolView.alwaysBounceHorizontal = true
        toolView.delegate = self
        toolView.dataSource = self
        return toolView
    }()
    
    fileprivate var scanResult = [ScanInfo]() {
        didSet {
        }
    }
    
    fileprivate var functionItems: [ScanFunction] {
        return [
            ScanFunction.flash,
            ScanFunction.quickScan,
            ScanFunction.manual,
            ScanFunction.voice,
            ScanFunction.barGunInput,
            ScanFunction.takePhoto,
            ScanFunction.inputUnsign
        ]
    }
    
    // 仅支持条码
    let supportedCodeType = [
        AVMetadataObject.ObjectType.code39,
        AVMetadataObject.ObjectType.code39Mod43,
        AVMetadataObject.ObjectType.code93,
        AVMetadataObject.ObjectType.code128,
        AVMetadataObject.ObjectType.ean8,
        AVMetadataObject.ObjectType.ean13,
        AVMetadataObject.ObjectType.aztec,
        AVMetadataObject.ObjectType.pdf417
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 获取AVCaptureDevice对象, 初始化硬件设备并配置参数
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            // 通过初始化的硬件设备获得AVCaptureDeviceInput对象
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            // 初始化 session 对象
            captureSession = AVCaptureSession()
            
            // 为session添加输入设备
            captureSession?.addInput(input)
            
            // 初始化输出对象
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // 配置代理, 用于处理捕获到的元数据
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // 配置可被扫描的码类型
            captureMetadataOutput.metadataObjectTypes = supportedCodeType
            
            // 初始化视频预览的layer， 并将其作为viewPreview的sublayer
            configPreviewLayer()
            // 自定义预览层: 添加mask，动态扫描线，聚焦区域
            configFocusLayer()
            captureSession?.startRunning()
        } catch {
            print(error)
            return
        }
        // 将显示信息的 label 与 top bar 提到最前面
        view.bringSubview(toFront: previewView)
        view.bringSubview(toFront: bottomView)
        bottomView.addSubview(toolCollectionView)
    }
    
    private func configPreviewLayer() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = previewView.bounds
        guard let resultLayer = videoPreviewLayer else { return }
        previewView.layer.addSublayer(resultLayer)
    }
    
    private func configFocusLayer() {
        let fixedRect = UIEdgeInsetsInsetRect(previewView.bounds, UIEdgeInsets(top: -1, left: -1, bottom: 1, right: 1))
        let path = UIBezierPath(roundedRect: fixedRect, cornerRadius: 0)
        let scanPath = UIBezierPath()
        scanPath.usesEvenOddFillRule = true
        // 绘制扫描区域
        let interval: CGFloat = 20
        let height: CGFloat = 120
        let width = UIScreen.main.bounds.width - (interval * 2)
        
        scanPath.move(to: CGPoint(x: interval, y: interval))
        scanPath.addLine(to: CGPoint(x: interval + width, y: interval))
        scanPath.addLine(to: CGPoint(x: interval + width, y: interval + height))
        scanPath.addLine(to: CGPoint(x: interval, y: interval + height))
        scanPath.close()
        
        path.append(scanPath)
        
        let scanLayer = CAShapeLayer()
        scanLayer.path = path.cgPath
        scanLayer.fillRule = kCAFillRuleEvenOdd
        scanLayer.fillColor = UIColor.black.cgColor
        scanLayer.lineWidth = 1.0
        scanLayer.opacity = 0.65
        scanLayer.strokeColor = UIColor.white.cgColor
        // 绘制四个角落
        let cornerPath = UIBezierPath()
        let cornerLayer = CAShapeLayer()
        let cL: CGFloat = 10;
        // 左上角
        cornerPath.move(to: CGPoint(x: interval, y: interval))
        cornerPath.addLine(to: CGPoint(x: interval, y: interval + cL))
        cornerPath.move(to: CGPoint(x: interval, y: interval))
        cornerPath.addLine(to: CGPoint(x: interval + cL, y: interval))
        // 右上角
        cornerPath.move(to: CGPoint(x: interval + width, y: interval))
        cornerPath.addLine(to: CGPoint(x: interval + width - cL, y: interval))
        cornerPath.move(to: CGPoint(x: interval + width, y: interval))
        cornerPath.addLine(to: CGPoint(x: interval + width, y: interval + cL))
        // 左下角
        cornerPath.move(to: CGPoint(x: interval, y: interval + height))
        cornerPath.addLine(to: CGPoint(x: interval, y: interval + height - cL))
        cornerPath.move(to: CGPoint(x: interval, y: interval + height))
        cornerPath.addLine(to: CGPoint(x: interval + cL, y: interval + height))
        // 右下角
        cornerPath.move(to: CGPoint(x: interval + width, y: interval + height))
        cornerPath.addLine(to: CGPoint(x: interval + width, y: interval + height - cL))
        cornerPath.move(to: CGPoint(x: interval + width, y: interval + height))
        cornerPath.addLine(to: CGPoint(x: interval + width - cL, y: interval + height))
        
        cornerLayer.path = cornerPath.cgPath
        cornerLayer.fillColor = UIColor.clear.cgColor
        cornerLayer.lineWidth = 2
        cornerLayer.strokeColor = UIColor.green.cgColor
        
        // 绘制动态指示线
        let lineLayer = CAGradientLayer()
        lineLayer.frame = CGRect(x: interval + 3, y: 0, width: width - 8, height: 2)
        lineLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.green.cgColor,
            UIColor.green.cgColor,
            UIColor.clear.cgColor
        ]
        lineLayer.startPoint = CGPoint(x: 0, y: 0)
        lineLayer.endPoint = CGPoint(x: 1, y: 0)
        
        let scanAnimation = CABasicAnimation(keyPath: "position.y")
        scanAnimation.fromValue = interval
        scanAnimation.toValue = height + interval
        scanAnimation.duration = 1
        scanAnimation.repeatCount = Float.greatestFiniteMagnitude
        scanAnimation.speed = 0.5
        
        lineLayer.add(scanAnimation, forKey: "YPosition")
        
        // 绘制提示文字layer
        let textLayer = CATextLayer()
        textLayer.frame = CGRect(x: interval, y: interval + height + 8, width: width, height: 45)
        textLayer.fontSize = 14
        textLayer.alignmentMode = kCAAlignmentCenter
        textLayer.string = "将条码放入框内，即可自动扫描"
        textLayer.contentsScale = UIScreen.main.scale
        previewView.layer.addSublayer(scanLayer)
        previewView.layer.addSublayer(cornerLayer)
        previewView.layer.addSublayer(lineLayer)
        previewView.layer.addSublayer(textLayer)
    }
}

extension QRScannerController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // 检查: metadataObjects对象不为空，并且至少包含一个元素
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = .zero
//            messageLabel.text = "No QR/bar Code is detected"
            return
        }
        // 获得元数据对象
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        // 如果元数据是二维码，则更新二维码选择框大小与label的文本
        if supportedCodeType.contains(metadataObj.type) {
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            guard let codeObject = barCodeObject else { return }
            qrCodeFrameView?.frame = codeObject.bounds
            if metadataObj.stringValue != nil {
                print(metadataObj.stringValue ?? "")
//                messageLabel.text = metadataObj.stringValue
            }
        }
    }
}

extension QRScannerController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return functionItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScanToolItemCell", for: indexPath) as! ScanToolItemCell
        cell.type = functionItems[indexPath.row]
        return cell
    }
}

extension QRScannerController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let type = functionItems[indexPath.row]
        print("\(type)")
    }
}

