//
//  TweetTVCell.swift
//  TweeterTags
//
//  Created by benjamin kelly on 06/03/2018.
//  Copyright © 2018 COMP47390-41550. All rights reserved.
//

import UIKit

class TweetTVCell: UITableViewCell {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var screenName: UILabel!
    @IBOutlet weak var tweetText: UILabel!
    @IBOutlet weak var date: UILabel!
    
    var showTweet: TwitterTweet? {
        didSet {
            getTweet()
        }
    }
    
    func getTweet() {
        if let showTweet = self.showTweet {
            screenName?.text = String(describing: showTweet.user)
            if let imageURL = showTweet.user.profileImageURL {
                if let imageData = try? Data(contentsOf: imageURL) {
                    profilePicture.image = UIImage(data: imageData)
                }
            }
            let formatter = DateFormatter()
            if Date().timeIntervalSince(showTweet.created as Date) > (86400-1) {
                formatter.dateStyle = DateFormatter.Style.medium
            } else {  // within 24hr display short time
                formatter.timeStyle = DateFormatter.Style.short
            }
            date?.text = formatter.string(from: showTweet.created as Date)
            
            // change tweet feauture string colours
            if tweetText?.text != nil  {
                let attributedString = NSMutableAttributedString(string: showTweet.text)
                for url in showTweet.urls {
                    let range = url.nsrange
                    attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.red, range: range)
                }
                for hashtag in showTweet.hashtags {
                    let range = hashtag.nsrange
                    attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.blue, range: range)
                }
                for mention in showTweet.userMentions {
                    let range = mention.nsrange
                    attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.green, range: range)
                }
                tweetText?.attributedText = attributedString
            }
        }
    }
}
