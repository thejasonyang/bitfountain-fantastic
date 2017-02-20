//
//  APIDataController.swift
//  Fantastic
//
//  Created by Jason Yang on 2/20/17.
//  Copyright © 2017 Jason Yang. All rights reserved.
//

import Foundation

class APIDataController {
    
    class func
    
    class func createAPIRequest (searchString: String) {
        var request = URLRequest(url: URL(string: Constants.kAPIURL)!)
        let session = URLSession.shared
        request.httpMethod = "POST"
        
        let fields = ["item_name", "brand_name", "keywords", "usda_fields"]
        
        let params = [
            "appId" : Constants.kAppID,
            "appKey" : Constants.kAppKey,
            "fields" : fields,
            "limit" : 50,
            "query" : searchString,
            "filters" : ["exists":["usda_fields":true]]
            ] as [String : Any]
        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any] else {
                print("error")
                return
            }
            print (json)
        }
        task.resume()
    }
}
