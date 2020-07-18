//
//  Photo+Extensions.swift
//  Virtual Tourist
//
//  Created by Sarah Gunnels Porter on 7/18/20.
//  Copyright © 2020 Gunnels Porter. All rights reserved.
//

import Foundation
import CoreData

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
}

