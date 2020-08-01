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

class PhotoAlbumViewController: UICollectionViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    //MARK: View Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    //MARK: Data Handling
    var dataContext:NSManagedObjectContext!
    var pinId:String!
    var fetchedPinResultsController:NSFetchedResultsController<Pin>!
    var fetchedPhotoResultsController:NSFetchedResultsController<Photo>!
    
    //MARK: Other Variables
    let photoAlbumCellReuseId = "PhotoAlbumCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Assign self as delegate to mapView and collectionView
        self.mapView.delegate = self
        
        // Load the Pin
        self.loadPhotoData()
        
        // Set-up Flow Layout of collection view
        let space : CGFloat = 8.0
        let wDimension = (view.frame.size.width - (2 * space)) / 3.0
        let hDimension = (view.frame.size.height - (2 * space)) / 4.0

        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: wDimension, height: hDimension)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.photoCollectionView.reloadData()
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
        if fetchedPhotoResultsController.fetchedObjects!.isEmpty {
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

    
    //MARK: Collection View Set-up
   override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchedPhotoResultsController.fetchedObjects?.count ?? 0
   }
       
   override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = self.fetchedPhotoResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoAlbumCellReuseId, for: indexPath) as! PhotoAlbumCell
           // Set the image
        cell.imageView?.image = UIImage(data: photo.imageData!)
           
        return cell
   }
       
   override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
       //To Do: Segue on tap, unless in edit mode
       //perform segue to detail view
           
   }
}

    
