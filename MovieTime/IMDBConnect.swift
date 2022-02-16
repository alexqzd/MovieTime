//
//  File.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 15/02/22.
//

import Foundation
import UIKit

class IMDBConnect {
    private let IMDBAPIKey = "API KEY"
    private let IMDBBaseURL = "https://imdb-api.com/en/API/"
    
    // Returns a complete URL to query for the passed query string
    private func constructAPIURL(withQuery query: String) -> URL? {
        let urlString = IMDBBaseURL + query + "/" + IMDBAPIKey
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
        guard errorMessage == "" else {
            print("Unexpected error")
            throw IMDBError.apiError(message: json["errorMessage"] as! String)
        }
        
        let jsonItems = json["items"] as! [Any]
        for jsonItem in jsonItems {
            let item = jsonItem as! [String: Any]
            
            var imageURL = item["image"] as! String
            
            if let index = (imageURL.range(of: "._")?.lowerBound) // find image format separator
            {
                imageURL = String(imageURL.prefix(upTo: index)) // remove default image format
                imageURL += "._V1_UX256_CR0,3,256,352_AL_.jpg" // get smaller thumbnail URL
            }
            
            let itemObj = IMBDItem(title: item["title"] as! String,
                                   year: item["year"] as! String,
                                   imageURL: imageURL,
                                   imdbID: item["id"] as! String)
            items.append(itemObj)
        }
        return items
    }
    
}

struct IMBDItem {
    var title: String
    var year: String
    var imageURL: String
    var imdbID: String
    
    func fetchPoster() async throws -> UIImage {
        let url = URL(string: imageURL)!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        guard let image = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
        return image
    }
}

enum IMDBError: Error {
    case apiError(message: String)
}
