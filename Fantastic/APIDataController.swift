//
//  APIDataController.swift
//  Fantastic
//
//  Created by Jason Yang on 2/20/17.
//  Copyright © 2017 Jason Yang. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class APIDataController {
    
    class func jsonToUSDAFormat (json: [String : Any]) -> [(name: String, idValue: String)] {
        var searchResults: [(name: String, idValue: String)] = []
        var result: (name: String, idValue: String)
        
        if let searchHits = json["hits"] as? [AnyObject] {
            for itemData in searchHits {
                if itemData["_id"] != nil && itemData["fields"] != nil {
                    let fieldsData = itemData["fields"] as? [String : Any]
                    let idValue = itemData["_id"] as! String
                    let name = fieldsData?["item_name"] as! String
                    result = (name: name, idValue: idValue)
                    searchResults += [result]
                }
            }
        }
        return searchResults
    }
    
    class func createAPIRequest (searchString: String, completionHandler: @escaping (_ json: [String : Any]) -> Void) {
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
            if json != nil {
                completionHandler(json!)
            }
        }
        task.resume()
    }
    
    class func saveItemForID(idValue: String, json: [String : Any], completionHandler: (_ saved: Bool) -> Void) {
        if let searchHits = json["hits"] as? [AnyObject] {
            for itemData in searchHits {
                if itemData["_id"] as? String == idValue && itemData["fields"] != nil {
                    let fieldsData = itemData["fields"] as? [String : Any]
                    let name = fieldsData?["item_name"] as! String
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let context = appDelegate.persistentContainer.viewContext
                    
                    let requestForItem:NSFetchRequest = FoodItem.fetchRequest()
                    let predicate = NSPredicate(format: "idValue == %@", idValue)
                    requestForItem.predicate = predicate
                    
                    do {
                        let count = try context.count(for: requestForItem)
                        if count != 0 {
                            let saved = false
                            completionHandler(saved)
                            return
                        } else {
                            let usdaData = fieldsData?["usda_fields"] as? [String : Any]
                            let carbsData = usdaData?["CHOCDF"] as? [String : Any]
                            let carbs = carbsData?["value"] as! Float
                            let fatData = usdaData?["FAT"] as? [String : Any]
                            let fat = fatData?["value"] as! Float
                            let proteinData = usdaData?["PROCNT"] as? [String : Any]
                            let protein = proteinData?["value"] as! Float
                            let caloriesData = usdaData?["ENERC_KCAL"] as? [String : Any]
                            let calories = caloriesData?["value"] as! Float
                        
                            let newItem = FoodItem(context: context)
                            newItem.idValue = idValue
                            newItem.name = name
                            newItem.calories = calories
                            newItem.carbs = carbs
                            newItem.fat = fat
                            newItem.protein = protein
                            newItem.dateAdded = Date() as NSDate?
                            appDelegate.saveContext()
                            
                            NotificationCenter.default.post(name: NSNotification.Name("coreDataSaveComplete"), object: newItem)
                            
                            let saved = true
                            completionHandler(saved)
                        }
                    } catch {
                        print("error")
                    }
                    
                }
            }
        }
    }
    
}
