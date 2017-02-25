//
//  MainViewController.swift
//  Fantastic
//
//  Created by Jason Yang on 2/19/17.
//  Copyright © 2017 Jason Yang. All rights reserved.
//

import UIKit
import CoreData
import HealthKit

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {

    @IBOutlet weak var mainTable: UITableView!
    
    var searchController: UISearchController!
    var suggestedSearchFoods: [String] = []
    var filteredSuggestedSearchFoods: [String] = []
    var savedFoodItems: [FoodItem] = []
    var filteredSavedFoodItems: [FoodItem] = []
    var scopeButtonTitles = ["Recommended", "Search Results", "Saved"]
    var apiSearchResults: [(name: String, idValue: String)] = []
    var jsonResults: [String : Any] = [:]
    var foodToPass: FoodItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mainTable.delegate = self
        mainTable.dataSource = self
        
        self.definesPresentationContext = true
        
        self.navigationController?.navigationBar.isTranslucent = false
        //self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        //self.navigationController?.navigationBar.shadowImage = UIImage()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.frame = CGRect(x: searchController.searchBar.frame.origin.x, y: searchController.searchBar.frame.origin.y, width: searchController.searchBar.frame.width, height: CGFloat(Constants.kSearchBarHeight))
        searchController.searchBar.barTintColor = self.navigationController?.navigationBar.barTintColor
        searchController.searchBar.tintColor = UIColor.white
        searchController.searchBar.scopeButtonTitles = scopeButtonTitles
        
        mainTable.tableHeaderView = self.searchController.searchBar
        
        suggestedSearchFoods = ["apple", "bagel", "banana", "beer", "bread", "carrots", "cheddar cheese", "chicken breast", "chili with beans", "chocolate chip cookie", "coffee", "cola", "corn", "egg", "graham cracker", "granola bar", "green beans", "ground beef patty", "hot dog", "ice cream", "jelly doughnut", "ketchup", "milk", "mixed nuts", "mustard", "oatmeal", "orange juice", "peanut butter", "pizza", "pork chop", "potato", "potato chips", "pretzels", "raisins", "ranch salad dressing", "red wine", "rice", "salsa", "shrimp", "spaghetti", "spaghetti sauce", "tuna", "white wine", "yellow cake"]
        
        NotificationCenter.default.addObserver(self, selector: #selector(saveDidComplete), name: NSNotification.Name("coreDataSaveComplete"), object: nil)
        
        setUpHealthKit()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = mainTable.dequeueReusableCell(withIdentifier: Constants.kMainCellID)
        var foodName: String
        
        switch (searchController.searchBar.selectedScopeButtonIndex) {
        case 0:
            if searchController.isActive && searchController.searchBar.text != "" {
                foodName = filteredSuggestedSearchFoods[indexPath.row]
            }
            else {
                foodName = suggestedSearchFoods[indexPath.row]
            }
        case 1:
            foodName = apiSearchResults[indexPath.row].name
        case 2:
            if searchController.isActive && searchController.searchBar.text != "" {
                foodName = filteredSavedFoodItems[indexPath.row].name!
            }
            else {
                foodName = savedFoodItems[indexPath.row].name!
            }
        default:
            foodName = ""
        }
        
        cell?.textLabel?.text = foodName
        cell?.accessoryType = .disclosureIndicator
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch (searchController.searchBar.selectedScopeButtonIndex) {
        case 0:
            if searchController.isActive && searchController.searchBar.text != "" {
                return filteredSuggestedSearchFoods.count
            }
            else {
                return suggestedSearchFoods.count
            }
        case 1:
            return apiSearchResults.count
        case 2:
            if searchController.isActive && searchController.searchBar.text != "" {
                return filteredSavedFoodItems.count
            }
            else {
                return savedFoodItems.count
            }
        default:
            return 0
        }
    }
    
    //MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (searchController.searchBar.selectedScopeButtonIndex) {
        case 0:
            var searchFoodName: String
            if searchController.isActive && searchController.searchBar.text != "" {
                searchFoodName = filteredSuggestedSearchFoods[indexPath.row]
            }
            else {
                searchFoodName = suggestedSearchFoods[indexPath.row]
            }
            searchController.searchBar.selectedScopeButtonIndex = 1
            APIDataController.createAPIRequest(searchString: searchFoodName, completionHandler: { (json) in
                self.apiSearchResults = APIDataController.jsonToUSDAFormat(json: json)
                self.jsonResults = json
                DispatchQueue.main.async {
                    self.mainTable.reloadData()
                }
            })
        case 1:
            if searchController.isActive {
                let idValue = apiSearchResults[indexPath.row].idValue
                APIDataController.saveItemForID(idValue: idValue, json: jsonResults, completionHandler: { (saved) in
                    if saved {
                        self.present(createBasicAlert(title: "Success", message: "Item saved!"), animated: true, completion: nil)
                    } else {
                        self.present(createBasicAlert(title: "Note", message: "Already saved"), animated: true, completion: nil)
                    }
                })
            }
            
        case 2:
            if searchController.isActive && searchController.searchBar.text != "" {
                foodToPass = filteredSavedFoodItems[indexPath.row]
            }
            else {
                foodToPass = savedFoodItems[indexPath.row]
            }
            self.performSegue(withIdentifier: Constants.kSegueToDetail, sender: self)
        default:
            print("D")
        }
    }
    
    //MARK: UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text!
        let selectedScopeButtonIndex = searchController.searchBar.selectedScopeButtonIndex
        if selectedScopeButtonIndex == 0 {
           filteredSuggestedSearchFoods = filterContentString(searchText: searchText, in: suggestedSearchFoods)
        } else if selectedScopeButtonIndex == 2 {
            filteredSavedFoodItems = filterContentFoodItem(searchText: searchText, in: savedFoodItems)
        }
        
        mainTable.reloadData()
    }
    
    //MARK: UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            APIDataController.createAPIRequest(searchString: searchText, completionHandler: { (json) in
                self.apiSearchResults = APIDataController.jsonToUSDAFormat(json: json)
                self.jsonResults = json
                DispatchQueue.main.async {
                    self.mainTable.reloadData()
                }
            })
        }
        searchController.searchBar.selectedScopeButtonIndex = 1
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if selectedScope == 2 {
            getSavedFoodItems()
        }
        mainTable.reloadData()
    }
    
    //MARK: Helpers
    
    func filterContentString (searchText: String, in searchArray: [String]) -> [String] {
        var filteredArray: [String]
        filteredArray = searchArray.filter({ (food: String) -> Bool in
            let isMatch = food.lowercased().contains(searchText.lowercased())
            return isMatch
        })
        return filteredArray
    }
    
    func filterContentFoodItem(searchText: String, in searchArray: [FoodItem]) -> [FoodItem] {
        var filteredArray: [FoodItem]
        filteredArray = searchArray.filter({ (food: FoodItem) -> Bool in
            let isMatch = food.name!.lowercased().contains(searchText.lowercased())
            return isMatch
        })
        return filteredArray
    }
    
    func getSavedFoodItems() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let savedItemRequest:NSFetchRequest = FoodItem.fetchRequest()
        do {
            savedFoodItems = try context.fetch(savedItemRequest) as [FoodItem]
        } catch {
            print("error")
        }
    }
    
    func createBasicAlert(title: String, message: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (alertAction) in
            self.performSegue(withIdentifier: Constants.kSegueToDetail, sender: self)
        }))
        return alert
    }
    
    func saveDidComplete() {
        print("thats one...")
    }
    
    func setUpHealthKit() {
        let healthStore = HKHealthStore()
        
        let dataTypes: Set = [
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCarbohydrates)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryFatTotal)!,
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)!
        ]
    
        healthStore.requestAuthorization(toShare: dataTypes, read: dataTypes) { (success, error) in
            if success {
                print("complete health auth")
            } else {
                print("error health auth")
            }
        }
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailVC = segue.destination as! DetailViewController
        if foodToPass != nil {
            detailVC.foodItem = self.foodToPass
        }
    }

}
