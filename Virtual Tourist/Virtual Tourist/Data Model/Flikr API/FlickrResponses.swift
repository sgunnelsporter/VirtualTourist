//
//  FlickrResponses.swift
//  Virtual Tourist
//
//  Created by Sarah Gunnels Porter on 8/1/20.
//  Copyright © 2020 Gunnels Porter. All rights reserved.
//

import Foundation

// Structure for the Search Response for the Flicker API
struct PhotoSearchResponse: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photos: [PhotoInfo]
}

struct PhotoInfo: Codable {
    //<photo id="16112774426" owner="26932764@N03" secret="73cf8749e2" server="8616" farm="9" title="Le Châtelet-en-Brie (77)" ispublic="1" isfriend="0" isfamily="0" />
    let id: String
    let owner: String
    let secret: String
    let server: Int
    let farm: Int
    let title: String
    let ispublic: Bool
    let isfriend: Bool
    let isfamily: Bool
}
