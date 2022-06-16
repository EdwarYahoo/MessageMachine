//
//  MessageConfigurationController.swift
//  MessageMachine
//
//  Created by EDWAR FERNANDO MARTINEZ CASTRO on 10/06/22.
//

import UIKit
import Firebase

class MessageConfigurationController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    //unwind segue for logouts across the app
    @IBAction func unwindSegue(_ sender: UIStoryboardSegue){}
    
    let db = Firestore.firestore()
    var messageConfiguration : [MessageConfiguration] = []
    let formatter = DateFormatter()
    
    override func viewDidLoad(){
        
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        title = K.appMessageConfigurationTitle
        //formatter.dateFormat = K.dateFormat
        
        
        navigationItem.hidesBackButton = true
        tableView.register(UINib(nibName: K.cellNibNameMessageConfiguration, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
    }
    
    func loadMessages(){
        
        // Query to Firebase collection
        db.collection(K.FStore.MessageConfiguration.collectionName).order(by: K.FStore.Messages.dateField).addSnapshotListener() { (querySnapshot, err) in
            self.messageConfiguration = [] // Save all messages in this variable
            if let err = err {
                print("\(K.errorMsgGetDocument)\(err)")
            } else {
                if let snapshotDocuments = querySnapshot?.documents{
                    for doc in snapshotDocuments{
                        let data = doc.data()
                        if (data[K.FStore.MessageConfiguration.ownerField] as! String) == Auth.auth().currentUser?.email { // Show owner's messages only
                            
                            if let messageConfCategory = data[K.FStore.MessageConfiguration.categoryField] as? Int,
                               //let messageConfDocId = data[K.FStore.MessageConfiguration.docIdField] as? String?,
                               let messageConfFrequency = data[K.FStore.MessageConfiguration.frequencyField] as? Int,
                               let messageConfMessage = data[K.FStore.MessageConfiguration.messageField] as? String,
                               let messageConfSendTo = data[K.FStore.MessageConfiguration.sendToField] as? [String],
                               let messageConfDate = data[K.FStore.MessageConfiguration.dateField] as? Double
                            {
                                let newMessageConfiguration = MessageConfiguration(docId: doc.documentID, category: messageConfCategory, frequency: messageConfFrequency, message: messageConfMessage, sendTo: messageConfSendTo, date: messageConfDate)
                                self.messageConfiguration.append(newMessageConfiguration)
                                
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    //Fix the scroll for messages
                                    let indexPath =  IndexPath(row: self.messageConfiguration.count-1, section: 0)
                                    self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}




extension MessageConfigurationController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageConfiguration.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messageConfiguration[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageConfigurationCell
        
        cell.lblCategory.text = K.FStore.MessageConfiguration.categories[message.category]
        cell.lblMessage.text = message.message
        cell.lblFrequency.text = String(message.frequency)
        cell.lblSendTo.text = message.sendTo.joined(separator: K.sendToSeparator)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            performSegue(withIdentifier: K.Segues.messageConfigurationDetail, sender: self)
            tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let destinationVC = segue.destination as! CreateUpdateMessage
        if let indexPath = tableView.indexPathForSelectedRow{
            destinationVC.messageConfiguration = messageConfiguration[indexPath.row]
        }
    }
}
