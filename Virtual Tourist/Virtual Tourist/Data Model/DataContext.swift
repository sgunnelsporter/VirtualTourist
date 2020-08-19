//
//  DataContext.swift
//  Virtual Tourist
//
//  Created by Sarah Gunnels Porter on 8/18/20.
//  Copyright © 2020 Gunnels Porter. All rights reserved.
//

import Foundation
import CoreData

class DataContext {
// MARK: - Core Data stack

    static var persistentContainer: NSPersistentContainer = {
        /*The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it.*/
        let container = NSPersistentContainer(name: "Virtual_Tourist")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    static func saveContext () {
        let context = DataContext.persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
