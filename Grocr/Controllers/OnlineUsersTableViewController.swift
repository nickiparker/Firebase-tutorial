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

class OnlineUsersTableViewController: UITableViewController {
  
  // MARK: Constants
  let userCell = "UserCell"
  
  // MARK: Properties
    // - Displays a list of online users
  let usersRef = Database.database().reference(withPath: "online")

  var currentUsers: [String] = []
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent

  }
  
  // MARK: UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // 1 - Create an observer that listens for children added to the location managed by usersRef
    usersRef.observe(.childAdded, with: { snap in
        // 2 - Take the value from the snapshot, and then append it to the local array
        guard let email = snap.value as? String else { return }
        self.currentUsers.append(email)
        // 3 - The current row is always the count of the local array minus one
        let row = self.currentUsers.count - 1
        // 4 - Create an instance NSIndexPath using the calculated row index
        let indexPath = IndexPath(row: row, section: 0)
        // 5 - Insert the row using an animation that causes the cell to be inserted from the top
        self.tableView.insertRows(at: [indexPath], with: .top)
        
        // - It searches the local array for the email value to find the corresponding child item, and once located, it deletes the associated row from the table
        self.usersRef.observe(.childRemoved, with: { snap in
        guard let emailToFind = snap.value as? String else { return }
        for (index, email) in self.currentUsers.enumerated() {
            if email == emailToFind {
                let indexPath = IndexPath(row: index, section: 0)
                self.currentUsers.remove(at: index)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
              }
            }
        })
    })
  }
  
  // MARK: UITableView Delegate methods
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return currentUsers.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: userCell, for: indexPath)
    let onlineUserEmail = currentUsers[indexPath.row]
    cell.textLabel?.text = onlineUserEmail
    return cell
  }
  
  // MARK: Actions - To logout of app
  
  @IBAction func signoutButtonPressed(_ sender: AnyObject) {
    // 1 - You first get the currentUser and create onlineRef using its uid, which is a unique identifier representing the user
    let user = Auth.auth().currentUser!
    let onlineRef = Database.database().reference(withPath: "online/\(user.uid)")
    
    // 2 - You call removeValue to delete the value for onlineRef. While Firebase automatically adds the user to online upon sign in, it does not remove the user on sign out. Instead, it only removes users when they become disconnected
    onlineRef.removeValue { (error, _) in
        
        // 3 - Within the completion closure, you first check if there’s an error and simply print it if so
        if let error = error {
            print("Removing online failed: \(error)")
            return
        }
        
        // 4 - You here call Auth.auth().signOut() to remove the user’s credentials from the keychain. If there isn’t an error, you dismiss the view controller. 
        do {
            try Auth.auth().signOut()
            self.dismiss(animated: true, completion: nil)
        } catch (let error) {
            print("Auth sign out failed: \(error)")
        }
    }
  }
}
