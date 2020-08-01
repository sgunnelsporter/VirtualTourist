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
    
    func locationSearchURL(lat: Double, lon: Double, page: Int) -> URL? {
        // example URL for each with lat/lon : https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=cf5e26ab866d8f7e61b97552cf489baa&lat=48.856&lon=2.353&radius=2&radius_units=miles&per_page=50&page=1
        let fullURL = Endpoint.baseURL.rawValue + "&lat=\(lat)&lon=\(lon)&page=\(page)"
        return URL(string: fullURL)
    }
}
