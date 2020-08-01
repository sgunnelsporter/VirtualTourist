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
    //example: <photo id="16112774426" owner="26932764@N03" secret="73cf8749e2" server="8616" farm="9" title="Le Châtelet-en-Brie (77)" ispublic="1" isfriend="0" isfamily="0" />
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

class PhotoInformation : NSObject, XMLParserDelegate {
   var level:Int = 0
   func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
    print("startElement: \(elementName),  Level:  \(level)");
      level = level+1
   }
   func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    level = level-1
    print("startElement: \(elementName),  Level:  \(level)");
      }
   func parser(_ parser: XMLParser, foundCharacters string: String) {
      let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmedString.count > 0
      {
        print(" Value: \(string)");
      }
   }

   func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    print("failure error: \(parseError)")
   }
}
