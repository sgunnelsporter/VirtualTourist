//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Sarah Gunnels Porter on 7/19/20.
//  Copyright © 2020 Gunnels Porter. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

    //MARK: View Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    //MARK: Data Handling
    var dataContext:NSManagedObjectContext!
    var pinId:String!
    var fetchedPinResultsController:NSFetchedResultsController<Pin>!
    var fetchedPhotoResultsController:NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Assign self as delegate to mapView and collectionView
        self.mapView.delegate = self
        self.photoCollectionView.delegate = self
        
        // Load the Pin
        self.loadPhotoData()
    }
    
    //MARK: Load the Pin & Photo Data
    func loadPhotoData(){
        // get get Pin with pinId given by MapView
        let pinFetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let pinPredicate = NSPredicate(format: "id == %@", UUID(uuidString: pinId)! as CVarArg)
        pinFetchRequest.predicate = pinPredicate
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        pinFetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedPinResultsController = NSFetchedResultsController(fetchRequest: pinFetchRequest, managedObjectContext: dataContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedPinResultsController.delegate = self

        do {
            try fetchedPinResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        // make fetch request for the photos for this Pin
        let photoFetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let photoPredicate = NSPredicate(format: "pin == %@", fetchedPinResultsController.fetchedObjects!.first!)
        photoFetchRequest.predicate = photoPredicate
        fetchedPhotoResultsController = NSFetchedResultsController(fetchRequest: photoFetchRequest, managedObjectContext: dataContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedPhotoResultsController.delegate = self
        do{
            try fetchedPhotoResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        // check if photos exist for this pin
        if let photos = fetchedPhotoResultsController.fetchedObjects {
            for photo in photos {
                // set photos in the collection view
            }
        } else {
            self.downloadPhotosFromFlickr()
        }
    }
    
    func downloadPhotosFromFlickr(){
        //To Do: Download photos from Flickr
        // download new set of photos for this pin from Flickr in background queue
        // display in view in main queue as they download
        // save new photos to Core Data as they download in background queue
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
