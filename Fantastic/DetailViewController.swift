//
//  DetailViewController.swift
//  Fantastic
//
//  Created by Jason Yang on 2/19/17.
//  Copyright © 2017 Jason Yang. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailTextView: UITextView!
    
    var foodItem: FoodItem?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self, selector: #selector(saveDidComplete(notification:)), name: NSNotification.Name("coreDataSaveComplete"), object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if foodItem != nil {
            detailTextView.attributedText = createStringFromFoodItem(foodItem: foodItem!)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func addBarButtonPressed(_ sender: UIBarButtonItem) {
    }
    
    func saveDidComplete(notification: Notification) {
        print("...and thats two!")
        foodItem = notification.object as? FoodItem
    }
    
    func createStringFromFoodItem(foodItem: FoodItem) -> NSMutableAttributedString {
        var attributedString = NSMutableAttributedString()
        var centeredParagraphStyle = NSMutableParagraphStyle()
        centeredParagraphStyle.alignment = NSTextAlignment.center
        centeredParagraphStyle.lineSpacing = 10
        
        let titleAttributesDictionary = [
            NSForegroundColorAttributeName : UIColor.black,
            NSFontAttributeName : UIFont.boldSystemFont(ofSize: 20),
            NSParagraphStyleAttributeName : centeredParagraphStyle
        ]
        
        let titleString = NSAttributedString(string: foodItem.name!, attributes: titleAttributesDictionary)
        
        attributedString.append(titleString)
        
        return attributedString
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
