/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Firebase

class GroceryListTableViewController: UITableViewController {

  // MARK: Constants
  let listToUsers = "ListToUsers"
  
  // MARK: Properties
  let ref = Database.database().reference(withPath: "grocery-items")
  var items: [GroceryItem] = []
  var user: User!
  var userCountBarButtonItem: UIBarButtonItem!
  
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  // MARK: UIViewController Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.allowsMultipleSelectionDuringEditing = false
    
    userCountBarButtonItem = UIBarButtonItem(title: "1",
                                             style: .plain,
                                             target: self,
                                             action: #selector(userCountButtonDidTouch))
    userCountBarButtonItem.tintColor = UIColor.white
    navigationItem.leftBarButtonItem = userCountBarButtonItem
    
    user = User(uid: "FakeId", email: "hungry@person.food")
    // 1 - Attach a listener to receive updates whenever the grocery-items endpoint is modified. queryOrdered(byChild:) returns a reference that informs the server to return data in an ordered fashion
    ref.queryOrdered(byChild: "completed").observe(.value, with: { snapshot in

      // 2 - Store the latest version of the data in a local variable inside the listener’s closure
      var newItems: [GroceryItem] = []
        
      // 3 - The listener’s closure returns a snapshot of the latest set of data. Using children, you loop through the grocery items
      for child in snapshot.children {
 
        // 4 - After creating an instance of GroceryItem, it’s added it to the array that contains the latest version of the data
        if let snapshot = child as? DataSnapshot,
           let groceryItem = GroceryItem(snapshot: snapshot) {
                newItems.append(groceryItem)
          }
        }
        
      // 5 - Replace items with the latest version of the data, then reload the table view so it displays the latest version
      self.items = newItems
      self.tableView.reloadData()
    })

  }
  
  // MARK: UITableView Delegate methods
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
    let groceryItem = items[indexPath.row]
    
    cell.textLabel?.text = groceryItem.name
    cell.detailTextLabel?.text = groceryItem.addedByUser
    
    toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
// Removes items from the list AND database
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
        let groceryItem = items[indexPath.row]
        groceryItem.ref?.removeValue()
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    // 1 - Find the cell the user tapped using cellForRow(at:)
    guard let cell = tableView.cellForRow(at: indexPath) else { return }

    // 2 - Get the corresponding GroceryItem by using the index path’s row
    let groceryItem = items[indexPath.row]
 
    // 3 - Negate completed on the grocery item to toggle the status
    let toggledCompletion = !groceryItem.completed
 
    // 4 - Call toggleCellCheckbox(_:isCompleted:) to update the visual properties of the cell
    toggleCellCheckbox(cell, isCompleted: toggledCompletion)

    // 5 - Use updateChildValues(_:), passing a dictionary, to update Firebase
    groceryItem.ref?.updateChildValues([
        "completed": toggledCompletion
        ])
  }
  
  func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
    if !isCompleted {
      cell.accessoryType = .none
      cell.textLabel?.textColor = .black
      cell.detailTextLabel?.textColor = .black
    } else {
      cell.accessoryType = .checkmark
      cell.textLabel?.textColor = .gray
      cell.detailTextLabel?.textColor = .gray
    }
  }
  
  // MARK: Add Item
  
    @IBAction func addButtonDidTouch(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Grocery Item",
                                      message: "Add an Item",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
 
            // 1 - Get the text field, and its text, from the alert controller
            guard let textField = alert.textFields?.first,
                let text = textField.text else { return }
            
            // 2 - Using the current user’s data, create a new, uuncompleted GroceryItem
            let groceryItem = GroceryItem(name: text,
                                          addedByUser: self.user.email,
                                          completed: false)
 
            // 3 - Create a child reference using child(_:). The key value of this reference is the item’s name in lowercase
            let groceryItemRef = self.ref.child(text.lowercased())
   
            // 4 - Use setValue(_:) to save data to the database. This method expects a Dictionary
            groceryItemRef.setValue(groceryItem.toAnyObject())
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel)
        
        alert.addTextField()
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
  
  @objc func userCountButtonDidTouch() {
    performSegue(withIdentifier: listToUsers, sender: nil)
  }
}
