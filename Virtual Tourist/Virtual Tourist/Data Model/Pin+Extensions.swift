//
//  Pin+Extensions.swift
//  Virtual Tourist
//
//  Created by Sarah Gunnels Porter on 7/18/20.
//  Copyright © 2020 Gunnels Porter. All rights reserved.
//

import Foundation
import CoreData
import MapKit

extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
}
