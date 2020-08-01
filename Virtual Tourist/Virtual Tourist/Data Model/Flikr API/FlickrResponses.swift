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

protocol ParserDelegate : XMLParserDelegate {
    var delegateStack: ParserDelegateStack? { get set }
    func didBecomeActive()
}

extension ParserDelegate {
    func didBecomeActive() {
    }
}

protocol NodeParser : ParserDelegate {
    associatedtype Item
    var result: Item? { get }
}

class ParserDelegateStack {
    private var parsers: [ParserDelegate] = []
    private let xmlParser: XMLParser

    init(xmlParser: XMLParser) {
        self.xmlParser = xmlParser
    }

    func push(_ parser: ParserDelegate) {
        parser.delegateStack = self
        xmlParser.delegate = parser
        parsers.append(parser)
    }

    func pop() {
        parsers.removeLast()
        if let next = parsers.last {
            xmlParser.delegate = next
            next.didBecomeActive()
        } else {
            xmlParser.delegate = nil
        }
    }
}

class ArrayParser<Parser : NodeParser> : NSObject, NodeParser {
    var result: [Parser.Item]? = []
    var delegateStack: ParserDelegateStack?

    private let tagName: String
    private let parserBuilder: (String) -> Parser?
    private var currentParser: Parser?

    init(tagName: String, parserBuilder: @escaping (String) -> Parser?) {
        self.tagName = tagName
        self.parserBuilder = parserBuilder
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == tagName {
            return
        }

        if let itemParser = parserBuilder(elementName) {
            currentParser = itemParser
            delegateStack?.push(itemParser)
            itemParser.parser?(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == tagName {
            delegateStack?.pop()
        }
    }

    func didBecomeActive() {
        guard let item = currentParser?.result else { return }
        result?.append(item)
    }
}

class PhotoInfoParser : NSObject, NodeParser {
    private let tagName: String
    private var id: String!
    private var owner: String!
    private var secret: String!
    private var server: Int!
    private var farm: Int!
    private var title: String!
    

    var delegateStack: ParserDelegateStack?
    var result: PhotoInfo?

    init(tagName: String) {
        self.tagName = tagName
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == tagName {
            id = attributeDict["id"]
            owner = attributeDict["owner"]
            secret = attributeDict["secret"]
            server = attributeDict["server"].flatMap(Int.init)
            farm = attributeDict["farm"].flatMap(Int.init)
            title = attributeDict["title"]
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == tagName {
            result = PhotoInfo(id: id, owner: owner, secret: secret, server: server, farm: farm, title: title, ispublic: true, isfriend: false, isfamily: false)
            delegateStack?.pop()
        }
    }
}

class PhotoListParser : NSObject, NodeParser {
    private let tagName: String

    private var page: Int!
    private var pages: Int!
    private var perpage: Int!
    private var total: Int!
    private let photosParser: ArrayParser<PhotoInfoParser>

    var delegateStack: ParserDelegateStack?
    var result: PhotoSearchResponse?

    init(tagName: String) {
        self.tagName = tagName
        photosParser = ArrayParser<PhotoInfoParser>(tagName: "photos") { tag in
            guard tag == "photo" else { return nil }
            return PhotoInfoParser(tagName: tag)
        }
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        print("parsing \(elementName)")

        if elementName == tagName {
            page = attributeDict["page"].flatMap(Int.init)
            pages = attributeDict["pages"].flatMap(Int.init)
            perpage = attributeDict["perpage"].flatMap(Int.init)
            total = attributeDict["total"].flatMap(Int.init)
            return
        }

        switch elementName {
        case "photo":
            delegateStack?.push(photosParser)
            photosParser.parser(parser, didStartElement: elementName, namespaceURI: namespaceURI, qualifiedName: qName, attributes: attributeDict)

        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == tagName {
            result = PhotoSearchResponse(page: page, pages: pages, perpage: perpage, total: total, photos: photosParser.result!)
            delegateStack?.pop()
        }
    }
}
