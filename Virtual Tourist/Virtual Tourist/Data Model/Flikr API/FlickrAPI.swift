//
//  FlickrAPI.swift
//  Virtual Tourist
//
//  Created by Sarah Gunnels Porter on 8/1/20.
//  Copyright © 2020 Gunnels Porter. All rights reserved.
//

import Foundation

class FlickrAPI {
    enum Endpoint : String {
        case baseURL = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=cf5e26ab866d8f7e61b97552cf489baa&radius=5&radius_units=km&per_page=100"
        
        var url : URL? {
            return URL(string: self.rawValue)
        }
    }
    
    class func locationSearchURL(lat: Double, lon: Double, page: Int) -> URL? {
        // example URL for each with lat/lon : https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=cf5e26ab866d8f7e61b97552cf489baa&lat=48.856&lon=2.353&radius=2&radius_units=miles&per_page=50&page=1
        let fullURL = Endpoint.baseURL.rawValue + "&lat=\(lat)&lon=\(lon)&page=\(page)"
        return URL(string: fullURL)
    }
    
    class func getPhotosForLocation(lat:Double, lon: Double, completion: @escaping ([PhotoInfo], Error?) -> Void) {
        //TO DO: Add random number generator to page.
        let page = 4;
        let url = self.locationSearchURL(lat: lat, lon: lon, page: page)
        let urlRequest = URLRequest(url: url!)
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion([], error)
                }
                return
            }
            print(String(data: data, encoding: .utf8)!)
            let decoder = JSONDecoder()
            do {
                let fullResponseObject = try decoder.decode(PhotoSearchResponse.self, from: data)
                let responseArray = fullResponseObject.photos
                DispatchQueue.main.async {
                    completion(responseArray, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion([], error)
                }
            }
        }
        task.resume()
    }
    
    class func imageURL(farm: Int, server: Int, id: String, secret: String) -> URL {
        // https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}.jpg
        let urlString = "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
        let url = URL(string: urlString)!
        
        return url
    }
}
