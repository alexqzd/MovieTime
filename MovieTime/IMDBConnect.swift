//
//  File.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 15/02/22.
//

import Foundation
import UIKit

class IMDBConnect {
    private let IMDBAPIKey = "k_92a0o0kv"
    private let IMDBBaseURL = "https://imdb-api.com/en/API/"
    
    static let sharedInstance = IMDBConnect()
    
    // Time before the rent expires and the item is removed from library
    let rentDuration = TimeInterval(60*60*24*3) // 3 days
//  let rentDuration = TimeInterval(60*3) // 3 minutes
    
    let itemUnitPrice = 2.99
    
    private(set) var favorites = Set<IMDBItem>()
    private var itemLibrary = Set<LibraryItem>()
        
    var cart = Set<IMDBItem>()
    
    init() {
        if let favs: [IMDBItem] = loadItems(pathName: "favorites") {
            for fav in favs {
                favorites.insert(fav)
            }
        }
        
        if let lib: [LibraryItem] = loadItems(pathName: "library") {
            for item in lib {
                itemLibrary.insert(item)
            }
        }
    }
    
    // Returns a complete URL to query for the passed query string
    private func constructAPIURL(withQuery query: String, arguments: String = "") -> URL? {
        let urlString = IMDBBaseURL + query + "/" + IMDBAPIKey + "/" + (arguments.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")
        return URL(string: urlString)
    }
    
    // Returns an array of popular items from the API
    func getPopular(contentType: ContentType) async throws -> [IMDBItem] {
       
        var items = [IMDBItem]()
        var url: URL
        switch contentType {
        case .Movie:
            url = constructAPIURL(withQuery: "MostPopularMovies")!
        case .TVShow:
            url = constructAPIURL(withQuery: "MostPopularTVs")!
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Error connecting to IMDB API")
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let errorMessage = json["errorMessage"] as? String
        guard errorMessage == "" || errorMessage == nil else {  // The API can return an empty error message or nil on success
            print("Unexpected error")
            throw IMDBError.apiError(message: json["errorMessage"] as? String ?? "Unknown error")
        }
        
        let jsonItems = json["items"] as! [Any]
        for jsonItem in jsonItems {
            let item = jsonItem as! [String: Any]
            
            var imageURL = item["image"] as! String
            let fullResPoster = FetchableImage(imageURL: imageURL)
            var thumnailPoster: FetchableImage?
            
            if let index = (imageURL.range(of: "._")?.lowerBound) // find image format separator
            {
                imageURL = String(imageURL.prefix(upTo: index)) // remove default image format
                imageURL += "._V1_UX256_CR0,3,256,352_AL_.jpg" // get smaller thumbnail URL
                thumnailPoster = FetchableImage(imageURL: imageURL)
            }
            
            let itemObj = IMDBItem(title: item["title"] as! String,
                                   year: item["year"] as! String,
                                   fullResPoster: fullResPoster,
                                   thumbnailPoster: thumnailPoster ?? fullResPoster,
                                   imdbID: item["id"] as! String,
                                   crew: item["crew"] as! String)
            items.append(itemObj)
        }
        return items
    }
    
    // Returns the details of the passed IMDB item
    func getTitleDetail(for imdbID: String) async throws -> IMDBItemDetail {
        let url = constructAPIURL(withQuery: "Title", arguments: imdbID)!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Error connecting to IMDB API")
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let errorMessage = json["errorMessage"] as? String
        guard errorMessage == "" || errorMessage == nil else { // The API can return an empty error message or nil on success
            print("Unexpected error on id \(imdbID)")
            throw IMDBError.apiError(message: json["errorMessage"] as? String ?? "Unknown error")
        }
        
        var imageURL = json["image"] as! String
        let fullResPoster = FetchableImage(imageURL: imageURL)
        var thumnailPoster: FetchableImage?
        
        if let index = (imageURL.range(of: "._")?.lowerBound) // find image format separator
        {
            imageURL = String(imageURL.prefix(upTo: index)) // remove default image format
            imageURL += "._V1_UX256_CR0,3,256,352_AL_.jpg" // get smaller thumbnail URL
            thumnailPoster = FetchableImage(imageURL: imageURL)
        }
        
        let itemObj = IMDBItemDetail(title: json["title"] as! String,
                                     year: json["year"] as! String,
                                     fullResPoster: fullResPoster,
                                     thumbnailPoster: thumnailPoster ?? fullResPoster,
                                     imdbID: json["id"] as! String,
                                     plot: json["plot"] as! String,
                                     awards: json["awards"] as! String,
                                     directors: json["directors"] as! String,
                                     writers: json["writers"] as! String,
                                     stars: json["stars"] as! String,
                                     genres: json["genres"] as! String,
                                     companies: json["companies"] as! String,
                                     contentRating: json["contentRating"] as? String,
                                     imDbRating: json["imDbRating"] as? Double,
                                     metacriticRating: json["metacriticRating"] as? Int,
                                     tagline: json["tagline"] as? String)
        return itemObj
    }
    
    func search(query: String) async throws -> [IMDBSearchResult] {
        
        var items = [IMDBSearchResult]()
        let url = constructAPIURL(withQuery: "Search", arguments: query)!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Error connecting to IMDB API")
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let errorMessage = json["errorMessage"] as? String
        guard errorMessage == "" || errorMessage == nil else {  // The API can return an empty error message or nil on success
            print("Unexpected error")
            throw IMDBError.apiError(message: json["errorMessage"] as? String ?? "Unknown error")
        }
        
        let jsonItems = json["results"] as! [Any]
        for jsonItem in jsonItems {
            let item = jsonItem as! [String: Any]
            
            var imageURL = item["image"] as! String
            let fullResPoster = FetchableImage(imageURL: imageURL)
            var thumnailPoster: FetchableImage?
            
            if let index = (imageURL.range(of: "._")?.lowerBound) // find image format separator
            {
                imageURL = String(imageURL.prefix(upTo: index)) // remove default image format
                imageURL += "._V1_UX256_CR0,3,256,352_AL_.jpg" // get smaller thumbnail URL
                thumnailPoster = FetchableImage(imageURL: imageURL)
            }
            
            let result = IMDBSearchResult(title: item["title"] as! String,
                                          description: item["description"] as! String,
                                          fullResPoster: fullResPoster,
                                          thumbnailPoster: thumnailPoster ?? fullResPoster,
                                          imdbID: item["id"] as! String)

            items.append(result)
        }
        return items
    }
    
    // Returns arrays of poster images and backdrop banners for the passed IMDB item
    func getImages(for imdbID: String) async throws -> PosterImages {
        let url = constructAPIURL(withQuery: "Posters", arguments: imdbID)!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Error connecting to IMDB API")
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let errorMessage = json["errorMessage"] as? String
        guard errorMessage == "" || errorMessage == nil else {
            print("Unexpected error on id \(imdbID)")
            throw IMDBError.apiError(message: json["errorMessage"] as? String ?? "Unknown error")
        }
        
        
        let postersJSON = json["posters"] as! [[String: Any]]
        let backdropsJSON = json["backdrops"] as! [[String: Any]]
        
        var fetchablePosters = [FetchableImage]()
        var fetchableBackdrops = [FetchableImage]()
        
        
        for jsonPoster in postersJSON {
            if let imageURL = jsonPoster["link"] as? String {
                fetchablePosters.append(FetchableImage(imageURL: imageURL))
            }
        }
        for jsonBackdrop in backdropsJSON {
            if let imageURL = jsonBackdrop["link"] as? String {
                fetchableBackdrops.append(FetchableImage(imageURL: imageURL))
            }
        }
        
        return PosterImages(posters: fetchablePosters, backdrops: fetchableBackdrops)
        
    }
    
    func addFavorite(item: IMDBItem) {
        favorites.insert(item)
        print("ading \(item.title) to favs")
        saveItems(items: favorites.sorted(by: {$0.imdbID < $1.imdbID}), pathName: "favorites")
    }
    
    func removeFavorite(item: IMDBItem) {
        favorites.remove(item)
        print("removing \(item.title) from favs")
        saveItems(items: favorites.sorted(by: {$0.imdbID < $1.imdbID}), pathName: "favorites")
    }
    
    func getItemLibrary() -> Set<LibraryItem> {
        itemLibrary = itemLibrary.filter({$0.dateAdded + rentDuration > Date()})
        return itemLibrary
    }
    
    private func saveItems<T: Codable>(items: [T], pathName: String) {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(pathName)
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            try data.write(to: path)
        } catch {
            print("ERROR: \(error)")
        }
    }
    
    private func loadItems<T: Codable>(pathName: String) -> T? {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(pathName)
        guard let data = try? Data(contentsOf: path) else {
            print("No items in \(pathName)")
            return nil
        }
        let decoder = JSONDecoder()
        if let savedFavorites = try? decoder.decode(T.self, from: data) {
            return savedFavorites
        } else {
            print("No items in \(pathName)")
            return nil
        }
    }
    
    func addToLibrary(item: IMDBItem) {
        itemLibrary.insert(LibraryItem(item: item, dateAdded: Date()))
        print("ading \(item.title) to library")
        saveItems(items: itemLibrary.sorted(by: {$0.item.imdbID < $1.item.imdbID}), pathName: "library")
    }
    
    func removeFromLibrary(item: IMDBItem) {
        if let itemInLibrary = itemLibrary.first(where: {$0.item.imdbID == item.imdbID}) {
            itemLibrary.remove(itemInLibrary)
            print("removing \(item.title) from library")
            saveItems(items: itemLibrary.sorted(by: {$0.item.imdbID < $1.item.imdbID}), pathName: "library")
        } else {
            print("item \(item.title) not in library")
        }

    }
    
}

struct IMDBItem: Codable, Hashable {
    static func == (lhs: IMDBItem, rhs: IMDBItem) -> Bool {
        lhs.imdbID == rhs.imdbID
    }
    
    var title: String
    var year: String
    var fullResPoster: FetchableImage
    var thumbnailPoster: FetchableImage
    var imdbID: String
    var crew: String
}

struct LibraryItem: Codable, Hashable {
    var item: IMDBItem
    var dateAdded: Date
}

struct IMDBSearchResult {
    var title: String
    var description: String
    var fullResPoster: FetchableImage
    var thumbnailPoster: FetchableImage
    var imdbID: String
    
    // We dont want to fetch de full details for every result because
    // we have limited API calls (100 per day)
    func toPartialIMDBItem() -> IMDBItem {
        return IMDBItem(title: title,
                        year: "",
                        fullResPoster: fullResPoster,
                        thumbnailPoster: thumbnailPoster,
                        imdbID: imdbID,
                        crew: "")
    }
    
    func fetchIMDBItem() async throws -> IMDBItem {
        let details = try await IMDBConnect.sharedInstance.getTitleDetail(for: imdbID)
        return IMDBItem(title: title,
                        year: details.year,
                        fullResPoster: fullResPoster,
                        thumbnailPoster: thumbnailPoster,
                        imdbID: imdbID,
                        crew: details.stars)
    }
}

struct IMDBItemDetail {
    var title: String
    var year: String
    var fullResPoster: FetchableImage
    var thumbnailPoster: FetchableImage
    var imdbID: String
    var plot: String
    var awards: String
    var directors: String
    var writers: String
    var stars: String
    var genres: String
    var companies: String
    var contentRating: String?
    var imDbRating: Double?
    var metacriticRating: Int?
    var tagline: String?
}

// Struct to hold an url to an image and a method to fetch it
struct FetchableImage: Codable, Hashable {
    let imageURL: String
    
    init(imageURL: String) {
        self.imageURL = imageURL
    }
    
    func fetch() async throws -> UIImage {
        let url = URL(string: imageURL)!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        guard let image = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
        return image
    }
    
}

struct PosterImages {
    var posters: [FetchableImage]
    var backdrops: [FetchableImage]
}

enum IMDBError: Error {
    case apiError(message: String)
}

enum ContentType {
    case Movie
    case TVShow
}
