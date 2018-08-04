//
//  TwitterAPI.swift
//

import Foundation
import TwitterKit
import CoreLocation

// MARK: - TwitterAPI 1.1

struct TwitterAPI {
    struct User {
        static let name = "name"
        static let screenName = "screen_name"
        static let id = "id_str"
        static let verified = "verified"
        static let profileImageURL = "profile_image_url"
    }
    
    struct Tweet {
        static let user = "user"
        static let text = "text"
        static let created = "created_at"
        static let id = "id_str"
        static let media = "entities.media"
    }
    
    struct Entities {
        static let hashtags = "entities.hashtags"
        static let urls = "entities.urls"
        static let userMentions = "entities.user_mentions"
        static let indices = "indices"
        static let text = "text"
    }
    
    struct Media {
        static let url = "media_url_https"
        static let width = "sizes.small.w"
        static let height = "sizes.small.h"
    }
    
    struct Constants {
        static let jsonExtension = ".json"
        static let urlPrefix = "https://api.twitter.com/1.1/"
    }
    
    struct Request {
        static let count = "count"
        static let query = "q"
        static let tweets = "statuses"
        static let resultType = "result_type"
        static let resultTypeRecent = "recent"
        static let resultTypePopular = "popular"
        static let geocode = "geocode"
        static let searchForTweets = "search/tweets"
        static let maxID = "max_id"
        static let sinceID = "since_id"
        struct SearchMetadata {
            static let maxID = "search_metadata.max_id_str"
            static let nextResults = "search_metadata.next_results"
            static let separator = "&"
        }
    }
    
    static let twitterDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

// MARK: - Twitter User

open class TwitterUser: CustomStringConvertible
{
    open let screenName: String
    open let name: String
    open let id: String
    open let verified: Bool
    open let profileImageURL: URL?
    
    open var description: String { return "@\(screenName) (\(name))\(verified ? " ✅" : "")" }
    
    init?(data: NSDictionary?) {
        guard
            let screenName = data?.value(forKeyPath: TwitterAPI.User.screenName) as? String,
            let name = data?.value(forKeyPath: TwitterAPI.User.name) as? String,
            let id = data?.value(forKeyPath: TwitterAPI.User.id) as? String
            else {
                return nil
        }
        
        self.screenName = screenName
        self.name = name
        self.id = id
        
        self.verified = (data?.value(forKeyPath: TwitterAPI.User.verified) as AnyObject).boolValue ?? false
        let urlString = data?.value(forKeyPath: TwitterAPI.User.profileImageURL) as? String ?? ""
        self.profileImageURL = (urlString.count > 0) ? URL(string: urlString) : nil
    }
    
    open var asPropertyList: AnyObject {
        get {
            return [TwitterAPI.User.name: name,
                    TwitterAPI.User.screenName: screenName,
                    TwitterAPI.User.id: id,
                    TwitterAPI.User.verified: verified ? "YES" : "NO",
                    TwitterAPI.User.profileImageURL: profileImageURL?.absoluteString ?? ""] as AnyObject
        }
    }
}

// MARK: - Twitter Media

open class TwitterMedia: CustomStringConvertible
{
    open let url: URL
    open let aspectRatio: Double
    
    open var description: String { return "\(url.absoluteString) (aspect ratio = \(aspectRatio))" }
    
    init?(data: NSDictionary?) {
        guard
            let height = data?.value(forKeyPath: TwitterAPI.Media.height) as? Double, height > 0,
            let width = data?.value(forKeyPath: TwitterAPI.Media.width) as? Double, width > 0,
            let urlString = data?.value(forKeyPath: TwitterAPI.Media.url) as? String,
            let url = URL(string: urlString)
            else {
                return nil
        }
        self.url = url
        self.aspectRatio = width/height
    }
    
}


// MARK: - Twitter Tweet

open class TwitterTweet: CustomStringConvertible {
    open let text: String
    open let user: TwitterUser
    open let created: Date
    open let id: String
    open let media: [TwitterMedia]
    open let hashtags: [TwitterMention]
    open let urls: [TwitterMention]
    open let userMentions: [TwitterMention]
    
    open var description: String { return "\(user) - \(created)\n\(text)\nhashtags: \(hashtags)\nurls: \(urls)\nuser_mentions: \(userMentions)" + "\nid: \(id)" }
    
    init?(data: NSDictionary?)
    {
        guard
            let user = TwitterUser(data: data?.value(forKeyPath: TwitterAPI.Tweet.user) as? NSDictionary),
            let text = data?.value(forKeyPath: TwitterAPI.Tweet.text) as? String,
            let created = (data?.value(forKeyPath: TwitterAPI.Tweet.created) as? String)?.asTwitterDate,
            let id = data?.value(forKeyPath: TwitterAPI.Tweet.id) as? String
            else {
                return nil
        }
        
        self.user = user
        self.text = text
        self.created = created
        self.id = id
        
        self.media = TwitterTweet.mediaItemsFromTwitterData(data?.value(forKeyPath: TwitterAPI.Tweet.media) as? NSArray)
        self.hashtags = TwitterTweet.mentionsFromTwitterData(data?.arrayForKeyPath(TwitterAPI.Entities.hashtags), inText: text, withPrefix: "#")
        self.urls = TwitterTweet.mentionsFromTwitterData(data?.arrayForKeyPath(TwitterAPI.Entities.urls), inText: text, withPrefix: "http")
        self.userMentions = TwitterTweet.mentionsFromTwitterData(data?.arrayForKeyPath(TwitterAPI.Entities.userMentions), inText: text, withPrefix: "@")
    }
    
    // MARK: - Private API
    
    private static func mediaItemsFromTwitterData(_ twitterData: NSArray?) -> [TwitterMedia] {
        var mediaItems = [TwitterMedia]()
        for mediaItemData in twitterData ?? [] {
            if let mediaItem = TwitterMedia(data: mediaItemData as? NSDictionary) {
                mediaItems.append(mediaItem)
            }
        }
        return mediaItems
    }
    
    private static func mentionsFromTwitterData(_ twitterData: NSArray?, inText text: String, withPrefix prefix: String) -> [TwitterMention] {
        var mentions = [TwitterMention]()
        for mentionData in twitterData ?? [] {
            if let mention = TwitterMention(fromTwitterData: mentionData as? NSDictionary, inText: text as NSString, withPrefix: prefix) {
                mentions.append(mention)
            }
        }
        return mentions
    }
}

// MARK: - Twitter Mention

open class TwitterMention: CustomStringConvertible
{
    open let keyword: String              // # or @ or http prefix
    open let nsrange: NSRange             // index into tweet's (Attributed)String
    
    open var description: String { return "\(keyword) (\(nsrange.location), \(nsrange.location+nsrange.length-1))" }
    
    init?(fromTwitterData data: NSDictionary?, inText text: NSString, withPrefix prefix: String)
    {
        guard
            let indices = data?.value(forKeyPath: TwitterAPI.Entities.indices) as? NSArray,
            let start = (indices.firstObject as? NSNumber)?.intValue, start >= 0,
            let end = (indices.lastObject as? NSNumber)?.intValue, end > start
            else {
                return nil
        }
        
        var prefixAloneOrPrefixedMention = prefix
        if let mention = data?.value(forKeyPath: TwitterAPI.Entities.text) as? String {
            prefixAloneOrPrefixedMention = mention.prependPrefixIfAbsent(prefix)
        }
        let expectedRange = NSRange(location: start, length: end - start)
        guard
            let nsrange = text.rangeOfSubstringWithPrefix(prefixAloneOrPrefixedMention, expectedRange: expectedRange)
            else {
                return nil
        }
        
        self.keyword = text.substring(with: nsrange)
        self.nsrange = nsrange
    }
}

// MARK: - Twitter request

open class TwitterRequest: NSObject
{
    open let requestType: String
    open let parameters: [String:String]
    
    public init(_ requestType: String, _ parameters: Dictionary<String, String> = [:]) {
        self.requestType = requestType
        self.parameters = parameters
    }
    
    public convenience init(search: String, count: Int = 0) {
        var parameters = [TwitterAPI.Request.query : search]
        if count > 0 {
            parameters[TwitterAPI.Request.count] = "\(count)"
        }
        self.init(TwitterAPI.Request.searchForTweets, parameters)
    }
    
    open func fetchTweets(_ handler: @escaping ([TwitterTweet]) -> Void) {
        fetch { results in
            var tweets = [TwitterTweet]()
            var tweetArray: NSArray?
            if let dictionary = results as? NSDictionary {
                if let tweets = dictionary[TwitterAPI.Request.tweets] as? NSArray {
                    tweetArray = tweets
                } else if let tweet = TwitterTweet(data: dictionary) {
                    tweets = [tweet]
                }
            } else if let array = results as? NSArray {
                tweetArray = array
            }
            if tweetArray != nil {
                for tweetData in tweetArray! {
                    if let tweet = TwitterTweet(data: tweetData as? NSDictionary) {
                        tweets.append(tweet)
                    }
                }
            }
            handler(tweets)
        }
    }
    
    public typealias PropertyList = AnyObject
    
    open func fetch(_ handler: @escaping (_ results: PropertyList?) -> Void) {
        performTwitterRequest(handler)
    }
    
    // Create request for older tweets
    open var requestForOlder: TwitterRequest? {
        if min_id == nil {
            if parameters[TwitterAPI.Request.maxID] != nil {
                return self
            }
        } else {
            return modifiedRequest(parametersToChange: [TwitterAPI.Request.maxID : min_id!])
        }
        return nil
    }
    
    // Create request for newer tweets
    open var requestForNewer: TwitterRequest? {
        if max_id == nil {
            if parameters[TwitterAPI.Request.sinceID] != nil {
                return self
            }
        } else {
            return modifiedRequest(parametersToChange: [TwitterAPI.Request.sinceID : max_id!], clearCount: true)
        }
        return nil
    }
    
    // MARK: - Private API
    private func performTwitterRequest(_ handler: @escaping (PropertyList?) -> Void) {
        let client = TWTRAPIClient()
        var clientError : NSError?
        let jsonExtension = (self.requestType.range(of: TwitterAPI.Constants.jsonExtension) == nil) ? TwitterAPI.Constants.jsonExtension : ""
        let request = client.urlRequest(withMethod: "GET", url: "\(TwitterAPI.Constants.urlPrefix)\(self.requestType)\(jsonExtension)", parameters: self.parameters, error: &clientError)
        
        client.sendTwitterRequest(request) { (response, responseData, error) -> Void in
            if let err = error {
                print("Error: \(err.localizedDescription)")
            } else {
                var propertyListResponse: PropertyList?
                if responseData != nil {
                    propertyListResponse = try! JSONSerialization.jsonObject(
                        with: responseData!,
                        options: JSONSerialization.ReadingOptions.mutableLeaves) as TwitterRequest.PropertyList?
                    if propertyListResponse == nil {
                        let error = "Couldn't parse JSON"
                        self.log(error as AnyObject)
                        propertyListResponse = error as TwitterRequest.PropertyList?
                    }
                } else {
                    let error = "Silence from Twitter."
                    self.log(error as AnyObject)
                    propertyListResponse = error as TwitterRequest.PropertyList?
                }
                self.synchronize {
                    self.captureFollowonRequestInfo(propertyListResponse)
                }
                handler(propertyListResponse)
            }
        }
    }
        
    private var min_id: String? = nil
    private var max_id: String? = nil
    
    private func modifiedRequest(parametersToChange: Dictionary<String,String>, clearCount: Bool = false) -> TwitterRequest {
        var newParameters = parameters
        for (key, value) in parametersToChange {
            newParameters[key] = value
        }
        if clearCount { newParameters[TwitterAPI.Request.count] = nil }
        return TwitterRequest(requestType, newParameters)
    }
    
    private func captureFollowonRequestInfo(_ propertyListResponse: PropertyList?) {
        if let responseDictionary = propertyListResponse as? NSDictionary {
            self.max_id = responseDictionary.value(forKeyPath: TwitterAPI.Request.SearchMetadata.maxID) as? String
            if let next_results = responseDictionary.value(forKeyPath: TwitterAPI.Request.SearchMetadata.nextResults) as? String {
                for queryTerm in next_results.components(separatedBy: TwitterAPI.Request.SearchMetadata.separator) {
                    if queryTerm.hasPrefix("?\(TwitterAPI.Request.maxID)=") {
                        let next_id = queryTerm.components(separatedBy: "=")
                        if next_id.count == 2 {
                            self.min_id = next_id[1]
                        }
                    }
                }
            }
        }
    }
    
    private func log(_ whatToLog: AnyObject) {
        debugPrint("TwitterRequest: \(whatToLog)")
    }
    
    private func synchronize(_ closure: () -> Void) {
        objc_sync_enter(self)
        closure()
        objc_sync_exit(self)
    }
}

// MARK: - Class Extensions

fileprivate extension String {
    var asTwitterDate: Date? {
        return TwitterAPI.twitterDateFormatter.date(from: self)
    }
}

fileprivate extension NSDictionary {
    func arrayForKeyPath(_ keypath: String) -> NSArray? {
        return self.value(forKeyPath: keypath) as? NSArray
    }
}

fileprivate extension String {
    func prependPrefixIfAbsent(_ prefix: String) -> String {
        if hasPrefix(prefix) {
            return self
        } else {
            return prefix + self
        }
    }
}

fileprivate extension NSString
{
    func rangeOfSubstringWithPrefix(_ prefix: String, expectedRange: NSRange) -> NSRange?
    {
        var offset = 0
        var substringRange = expectedRange
        while range.contains(substringRange) && substringRange.intersects(expectedRange) {
            if substring(with: substringRange).hasPrefix(prefix) {
                return substringRange
            }
            offset = offset > 0 ? -(offset+1) : -(offset-1)
            substringRange.location += offset
        }
        
        var searchRange = range
        var bestMatchRange = NSRange.NotFound
        var bestMatchDistance = Int.max
        repeat {
            substringRange = self.range(of: prefix, options: [], range: searchRange)
            let distance = substringRange.distanceFrom(expectedRange)
            if distance < bestMatchDistance {
                bestMatchRange = substringRange
                bestMatchDistance = distance
            }
            searchRange.length -= substringRange.end - searchRange.start
            searchRange.start = substringRange.end
        } while searchRange.length > 0
        
        if bestMatchRange.location != NSNotFound {
            bestMatchRange.length = expectedRange.length
            if range.contains(bestMatchRange) {
                return bestMatchRange
            }
        }
        
        print("No keyword with prefix \(prefix) in range \(expectedRange) of \(self)")
        
        return nil
    }
    
    var range: NSRange { return NSRange(location:0, length: length) }
}

fileprivate extension NSRange
{
    func contains(_ range: NSRange) -> Bool {
        return range.location >= location && range.location+range.length <= location+length
    }
    
    func intersects(_ range: NSRange) -> Bool {
        if range.location == NSNotFound || location == NSNotFound {
            return false
        } else {
            return (range.start >= start && range.start < end) || (range.end >= start && range.end < end)
        }
    }
    
    func distanceFrom(_ range: NSRange) -> Int {
        if range.location == NSNotFound || location == NSNotFound {
            return Int.max
        } else if intersects(range) {
            return 0
        } else {
            return (end < range.start) ? range.start - end : start - range.end
        }
    }
    
    static let NotFound = NSRange(location: NSNotFound, length: 0)
    
    var start: Int {
        get { return location }
        set { location = newValue }
    }
    
    var end: Int { return location+length }
}


