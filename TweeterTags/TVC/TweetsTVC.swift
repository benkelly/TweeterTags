//
//  TweetsTVC.swift
//  TweeterTags
//
//  Created by benjamin kelly on 06/03/2018.
//  Copyright © 2018 COMP47390-41550. All rights reserved.
//

import UIKit

class TweetsTVC: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var twitterQueryTextField: UITextField! {
        didSet {
            twitterQueryTextField.delegate = self
            twitterQueryTextField.text = twitterQueryText
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        twitterQueryText = textField.text!
        twitterQueryTextField.resignFirstResponder()
        return true
    }
    
    var tweets = [[TwitterTweet]]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var twitterQueryText : String = "#ucd"{
        didSet{
            let defaults = UserDefaults.standard
            var recentArr = [String]()
            if let tempArr = defaults.object(forKey: "recentSearches") as? [String] {
                recentArr = tempArr
                if recentArr.count >= 100 {
                    recentArr.removeLast()
                }
            }
            if(recentArr.last != twitterQueryText && twitterQueryText != "#ucd"){
                if (recentArr.contains(twitterQueryText)) {
                    if let index = recentArr.index(of: twitterQueryText) {
                        recentArr.remove(at: index)
                    }
                }
                recentArr.append(twitterQueryText)
            }
            defaults.set(recentArr, forKey: "recentSearches")
            twitterQueryTextField?.text = twitterQueryText
            tweets.removeAll()
            self.tableView.reloadData()
            refresh()
        }
    }
    
    private var twitterRequest: TwitterRequest?
    
    // update data model
    @objc private func refresh() {
        let request = TwitterRequest(search: twitterQueryText, count: 40)
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            request.fetchTweets { (newTweets) -> Void in
                if newTweets.count > 0 {
                    self.twitterRequest = request
                    DispatchQueue.main.async { () -> Void in
                        self.tweets.insert(newTweets, at: 0)
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.refresh()
        NotificationCenter.default.addObserver(self, selector: #selector(self.refresh), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tweets.count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets[section].count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TweeterCell", for: indexPath) as! TweetTVCell
        cell.showTweet = tweets[indexPath.section][indexPath.row]
        return cell
    }
    
    // segue to tweet options
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tweetsToMentionsTVC"{
            if let destination =  segue.destination as? MentionsTVC{
                if let index = self.tableView.indexPathForSelectedRow{
                    destination.showTweet = tweets[index.section][index.row]
                }
            }
        }
    }
}
