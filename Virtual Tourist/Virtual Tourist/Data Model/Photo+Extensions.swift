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
    static func createNew(pin: Pin, info: PhotoInfo){
        let dataContext = DataContext.persistentContainer.viewContext
        
        let newPhoto = Photo(context: dataContext)
        newPhoto.associatedPin = pin
        newPhoto.id = UUID()
        newPhoto.imageURL = FlickrAPI.imageURL(farm: info.farm, server: info.server, id: info.id, secret: info.secret)
        //  Save Core Data
        do {
            try dataContext.save()
        } catch {
            fatalError("The Photo could not be created: \(error.localizedDescription)")
        }
    }
}

extension Collection where Element == Photo, Index == Int {
    func delete(at indices: IndexSet, from managedObjectContext: NSManagedObjectContext) {
        indices.forEach { managedObjectContext.delete(self[$0]) }
 
        do {
            try managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}

