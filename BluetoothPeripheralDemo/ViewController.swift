//
//  ViewController.swift
//  BluetoothPeripheralDemo
//
//  Created by Marshal on 2022/10/25.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var receiveText: UILabel!
        
    var manager: LSBluetoothPerpheral?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func startAdvertise() {
        manager = LSBluetoothPerpheral()
        manager!.onReceiveWriteData = { [weak self] (receiveInfo) in
            print("receiveInfo", receiveInfo)
            self?.receiveText.text = receiveInfo
        }
    }
    
    @IBAction func onClickToAdvertise(_ sender: UIButton) {
        startAdvertise()
    }


}

