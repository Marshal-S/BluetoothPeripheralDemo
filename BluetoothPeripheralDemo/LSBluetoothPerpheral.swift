//
//  LSBluetoothPerpheral.swift
//  BluetoothPeripheralDemo
//
//  Created by Marshal on 2022/10/25.
//

import Foundation
import CoreBluetooth

let serviceUUID = "11000000-0000-0000-0000-818282828282";
let characterUUID = "12000000-0000-0000-0000-000000000000";
let writeCharacterUUID = "13000000-0000-0000-0000-000000000000";

let instance = LSBluetoothPerpheral();

class LSBluetoothPerpheral: NSObject, CBPeripheralManagerDelegate {
    var receiveData: NSMutableData =  NSMutableData();
    var receiveString: NSMutableString =  NSMutableString();
    
    var manager: CBPeripheralManager?;
    var readWrite: CBMutableCharacteristic?;
    var write: CBMutableCharacteristic?;
    
    var onReceiveWriteData: ((String) -> Void)? //接收信息回调
    
    static func sharedInstance() -> LSBluetoothPerpheral {
        return instance;
    };
    
    override init() {
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            fallthrough
        case .resetting:
            fallthrough
        case .unsupported:
            print("蓝牙异常")
        case .unauthorized:
            print("没授权")
        case .poweredOff:
            print("没打开蓝牙")
        case .poweredOn:
            setup()
        @unknown default:
            print("出现了为知错误")
        }
    }
    
    //符合条件后在初始化
    func setup() {
        print("初始化了")
        let properties = (CBCharacteristicProperties.indicate.rawValue | CBCharacteristicProperties.write.rawValue | CBCharacteristicProperties.writeWithoutResponse.rawValue |  CBCharacteristicProperties.indicate.rawValue | CBCharacteristicProperties.read.rawValue | CBCharacteristicProperties.notify.rawValue)
        let permissions = (CBAttributePermissions.readable.rawValue | CBAttributePermissions.writeable.rawValue)
        
        //暴露特征
        let readwriteCharacteristicDescription = CBMutableDescriptor(type: CBUUID(string: CBUUIDCharacteristicUserDescriptionString), value: "name")
        
        
        readWrite = CBMutableCharacteristic(type: CBUUID(string: characterUUID), properties: CBCharacteristicProperties(rawValue: properties), value: nil, permissions: CBAttributePermissions(rawValue: permissions));
        readWrite?.descriptors = [readwriteCharacteristicDescription];
    
        //搞一个差不多一样的特征，可以用来做其他的交互
        write = CBMutableCharacteristic(type: CBUUID(string: writeCharacterUUID), properties: CBCharacteristicProperties(rawValue: properties), value: nil, permissions: CBAttributePermissions(rawValue: permissions))
                                            
        let service = CBMutableService(type: CBUUID(string: serviceUUID), primary: true)
        service.characteristics = [readWrite!, write!]
        manager?.add(service)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("添加了server 开始广播")
        //添加了server 开始广播
        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: CBUUID(string: serviceUUID),
            CBAdvertisementDataLocalNameKey:"marshal_123456"
        ])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("开始广播")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        //接收到读取信息的通知
        print("didReceiveReadRequest", request);
        
        let data = request.characteristic.value
        print("data", data!.description as String)
        
        let myString = "你猜猜我是谁"
        let newData = myString.data(using: String.Encoding.utf8)
        
        request.value = newData
       //对请求作出成功响应
        peripheral.respond(to: request, withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        requests.forEach { obj in
            if obj.characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue == 1 {
                //需要反馈就告诉成功了
                peripheral .respond(to: obj, withResult: .success)
            }
            //什么信息都没传递结束
            if obj.value == nil {
                return
            }
            if (obj.characteristic.uuid.uuidString == writeCharacterUUID) {
                //假设我们用到了这个服务做其中一件事情
                let receiveString = NSString(data: obj.value!, encoding: String.Encoding.utf8.rawValue);
                let str = String(data: obj.value!, encoding: String.Encoding.utf8)
                print("receiveString", receiveString?.description)
                print("str", str?.description)
                
                if let receive = receiveString {
                    self.receiveString.append(receive as String)
                    self.receiveData.append(obj.value!)
                    if let block = self.onReceiveWriteData {
                        block(receive as String)
                        //收到后并且反馈给对方
                        obj.value = "我收到的消息为:\(receive)".data(using: String.Encoding.utf8)
                        peripheral.respond(to: obj, withResult: .success)
                    }
                }
            }
        }
    }
}
