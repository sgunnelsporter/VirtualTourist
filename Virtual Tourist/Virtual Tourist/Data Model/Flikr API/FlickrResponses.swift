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
    //photo id="2636" owner="47058503995@N01" secret="a123456" server="2" title="test_04" ispublic="1" isfriend="0" isfamily="0"
    let id: String
    let owner: String
    let secret: String
    let server: Int
    let title: String
    let ispublic: Bool
    let isfriend: Bool
    let isfamily: Bool
}
