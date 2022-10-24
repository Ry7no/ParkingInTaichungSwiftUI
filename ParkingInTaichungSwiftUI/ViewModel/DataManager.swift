//
//  DataManager.swift
//  ParkingInTaichungSwiftUI
//
//  Created by @Ryan on 2022/10/24.
//

import SwiftUI



class DataManager: ObservableObject {
    
    @Published var fetchedParkingLots = [ParkingLot]()
    @Published var availableParkingLots = [ParkingLot]()
    @Published var unavailableParkingLots = [ParkingLot]()
    
    init() {
        getParkingData()
    }
    
    func getParkingData() {
        
        let address = "https://datacenter.taichung.gov.tw/swagger/OpenData/791a8a4b-ade6-48cf-b3ed-6c594e58a1f1"
            if let url = URL(string: address) {
                // GET
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    // 假如錯誤存在，則印出錯誤訊息（ 例如：網路斷線等等... ）
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                      // 取得 response 和 data
                    } else if let response = response as? HTTPURLResponse,let data = data {
                        // 將 response 轉乘 HTTPURLResponse 可以查看 statusCode 檢查錯誤（ ex: 404 可能是網址錯誤等等... ）
                        print("Status code: \(response.statusCode)")
                        // 創建 JSONDecoder 實例來解析我們的 json 檔
                        let decoder = JSONDecoder()
                        // decode 從 json 解碼，返回一個指定類型的值，這個類型必須符合 Decodable 協議
                        DispatchQueue.main.async {
                            self.fetchedParkingLots = try! decoder.decode([ParkingLot].self, from: data)
                            print(self.fetchedParkingLots.count)
                            
                            self.fetchedParkingLots.forEach { ParkingLot in
                                if ParkingLot.status == "0" {
                                    self.availableParkingLots.append(ParkingLot)
                                } else {
                                    self.unavailableParkingLots.append(ParkingLot)
                                }
                            }
                            
                            print("availableParkingLots: \(self.availableParkingLots.count)")
                            print("unavailableParkingLots: \(self.unavailableParkingLots.count)")
                            print("Sum: \(self.availableParkingLots.count + self.unavailableParkingLots.count)")
                        }
//                        if let ParkingLotData = try? decoder.decode([ParkingLot].self, from: data) {
//                            print("============== ParkingLotData ==============")
//                            print(ParkingLotData[0])
//                            print(ParkingLotData.count)
//                            print("============== ParkingLotData ==============")
//                        }
                    }
                    }.resume()
            } else {
                print("Invalid URL.")
            }
    }
    

}
