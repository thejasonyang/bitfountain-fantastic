//
//  MainViewController.swift
//  Fantastic
//
//  Created by Jason Yang on 2/19/17.
//  Copyright © 2017 Jason Yang. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {

    @IBOutlet weak var mainTable: UITableView!
    
    var searchController: UISearchController!
    var suggestedSearchFoods: [String] = []
    var filteredSuggestedSearchFoods: [String] = []
    var scopeButtonTitles = ["Recommended", "Search Results", "Saved"]
    var apiSearchResults: [(name: String, idValue: String)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mainTable.delegate = self
        mainTable.dataSource = self
        
        self.definesPresentationContext = true
        
        //self.navigationController?.navigationBar.isTranslucent = false
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
            foodName = ""
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
            return 0
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
                DispatchQueue.main.async {
                    self.mainTable.reloadData()
                }
            })
        case 1:
            print("1")
        case 2:
            print("2")
        default:
            print("D")
        }
    }
    
    //MARK: UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text!
        let selectedScopeButtonIndex = searchController.searchBar.selectedScopeButtonIndex
        filteredSuggestedSearchFoods = filterContent(searchText: searchText, in: suggestedSearchFoods, scope: selectedScopeButtonIndex)
        mainTable.reloadData()
    }
    
    //MARK: UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            APIDataController.createAPIRequest(searchString: searchText, completionHandler: { (json) in
                self.apiSearchResults = APIDataController.jsonToUSDAFormat(json: json)
                DispatchQueue.main.async {
                    self.mainTable.reloadData()
                }
            })
        }
        searchController.searchBar.selectedScopeButtonIndex = 1
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        mainTable.reloadData()
    }
    
    //MARK: Helpers
    
    func filterContent (searchText: String, in searchArray: [String], scope: Int) -> [String] {
        var filteredArray: [String]
        filteredArray = searchArray.filter({ (food: String) -> Bool in
            let isMatch = food.lowercased().contains(searchText.lowercased())
            return isMatch
        })
        return filteredArray
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
