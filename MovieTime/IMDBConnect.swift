//
//  File.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 15/02/22.
//

import Foundation
import UIKit

class IMDBConnect {
    private let IMDBAPIKey = "k_2tcj88j3"
    private let IMDBBaseURL = "https://imdb-api.com/en/API/"
    
    // Returns a complete URL to query for the passed query string
    private func constructAPIURL(withQuery query: String, arguments: String = "") -> URL? {
        let urlString = IMDBBaseURL + query + "/" + IMDBAPIKey + "/" + arguments
        return URL(string: urlString)
    }
    
    // Returns an array of popular items from the API
    func getPopular(contentType: ContentType) async throws -> [IMBDItem] {
        var items = [IMBDItem]()
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
        guard errorMessage == "" || errorMessage == nil else {
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
            
            let itemObj = IMBDItem(title: item["title"] as! String,
                                   year: item["year"] as! String,
                                   fullResPoster: fullResPoster,
                                   thumbnailPoster: thumnailPoster ?? fullResPoster,
                                   imdbID: item["id"] as! String,
                                   crew: item["crew"] as! String)
            items.append(itemObj)
        }
        return items
    }
    
    func getTitleDetail(for imdbID: String) async throws -> IMBDItemDetail {
        let url = constructAPIURL(withQuery: "Title", arguments: imdbID)!
        
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
        
        
        var imageURL = json["image"] as! String
        let fullResPoster = FetchableImage(imageURL: imageURL)
        var thumnailPoster: FetchableImage?
        
        if let index = (imageURL.range(of: "._")?.lowerBound) // find image format separator
        {
            imageURL = String(imageURL.prefix(upTo: index)) // remove default image format
            imageURL += "._V1_UX256_CR0,3,256,352_AL_.jpg" // get smaller thumbnail URL
            thumnailPoster = FetchableImage(imageURL: imageURL)
        }
        
        let itemObj = IMBDItemDetail(title: json["title"] as! String,
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
    
}

struct IMBDItem {
    var title: String
    var year: String
    var fullResPoster: FetchableImage
    var thumbnailPoster: FetchableImage
    var imdbID: String
    var crew: String
}

struct IMBDItemDetail {
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

struct FetchableImage {
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
