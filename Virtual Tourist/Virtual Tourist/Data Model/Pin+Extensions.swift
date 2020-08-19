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
    static func createNew(latitude: Double, longitude: Double, locationName: String?) -> Pin{
        let dataContext = DataContext.persistentContainer.viewContext
        
        let newPin = Pin(context: dataContext)
        newPin.id = UUID()
        newPin.latitude = latitude
        newPin.longitude = longitude
        newPin.locationName = locationName
        //  Save Core Data
        do {
            try dataContext.save()
        } catch {
            fatalError("The Photo could not be created: \(error.localizedDescription)")
        }
        
        return newPin
    }
    
    func removePhotos(_ photos: [Photo]) {
        let dataContext = DataContext.persistentContainer.viewContext
        
        for photo in photos {
            self.removeFromPhoto(photo)
            dataContext.delete(photo)
        }
        do {
            try dataContext.save()
        } catch {
            fatalError("The Photo could not be created: \(error.localizedDescription)")
        }
    }
}
