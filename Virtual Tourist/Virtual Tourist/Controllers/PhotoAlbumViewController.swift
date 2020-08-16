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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    //MARK: View Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    //MARK: Data Handling
    var dataContext:NSManagedObjectContext!
    var pin:Pin!
    
    var annotation = [MKPointAnnotation]()
    var savedImages:[Photo] = []
    
    //MARK: Other Variables
    let photoAlbumCellReuseId = "PhotoAlbumCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Assign self as delegate to mapView and collectionView
        self.mapView.delegate = self
        //Add pin to the Map
        annotation.append(self.setPinToAnnotation(pin))
        self.mapView.addAnnotations(self.annotation)
        self.mapView.setCenter(self.annotation.first!.coordinate, animated: true)
        
        
        // Set-up Flow Layout of collection view
        let space : CGFloat = 8.0
        let wDimension = (photoCollectionView.frame.size.width - (2 * space)) / 4.0
        let hDimension = (photoCollectionView.frame.size.height - (2 * space)) / 5.0

        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: wDimension, height: hDimension)
        
        // Set Photo Collection Attributes
        self.photoCollectionView.delegate = self
        self.photoCollectionView.dataSource = self
        // Load the Pin Photos
        let savedPhotos = preloadSavedPhoto()
        if savedPhotos == nil || savedPhotos?.count == 0 {
            //load new images
            self.downloadPhotoInformationFromFlickr()
        } else {
            savedImages = preloadSavedPhoto()!
        }
                
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.photoCollectionView.reloadData()
    }
    
    //MARK: Set Pin and Pin Data
    func setPinToAnnotation(_ pin: Pin) -> MKPointAnnotation{
        // Convert Pins to Annotations for addition to map
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)

        // Create the annotation; setting coordiates, title, and subtitle properties
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = pin.locationName ?? "Still Empty"
        
        return annotation
    }
    
    //MARK: Load the Photo Data
    func preloadSavedPhoto() -> [Photo]? {
        do {
            var photoArray:[Photo] = []
            let fetchedPhotoResultsController = getFetchRequestController()
            try fetchedPhotoResultsController.performFetch()
            let photoCount = try fetchedPhotoResultsController.managedObjectContext.count(for: fetchedPhotoResultsController.fetchRequest)
            for index in 0..<photoCount {
                photoArray.append(fetchedPhotoResultsController.object(at: IndexPath(row: index, section: 0)))
            }
            return photoArray
        } catch {
            return nil
        }
    }
    
    func getFetchRequestController() -> NSFetchedResultsController<Photo> {
       
        var fetchedPhotoResultsController:NSFetchedResultsController<Photo>!
        
        // make fetch request for the photos for this Pin
        let photoFetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        photoFetchRequest.sortDescriptors = [sortDescriptor]
        let photoPredicate = NSPredicate(format: "associatedPin == %@", pin)
        photoFetchRequest.predicate = photoPredicate
        fetchedPhotoResultsController = NSFetchedResultsController(fetchRequest: photoFetchRequest, managedObjectContext: dataContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedPhotoResultsController.delegate = self
        
        return fetchedPhotoResultsController
    }
    
    func downloadPhotoInformationFromFlickr(){
        //Download photos from Flickr
        // request photo information
        FlickrAPI.getPhotosForLocation(lat: pin.latitude, lon: pin.longitude, completion: loadPhotosFromFlickr(_:error:))
    }
    
    func loadPhotosFromFlickr(_ photoInfo: [PhotoInfo], error: Error?){
        // download each photo
        for photo in photoInfo {
            // save new image
            let imageURL = FlickrAPI.imageURL(farm: photo.farm, server: photo.server, id: photo.id, secret: photo.secret)
            let newPhoto = Photo(context: dataContext)
            newPhoto.associatedPin = pin
            newPhoto.id = UUID()
            // TO DO: Handle throw
            // TO DO: Move to background queue
            let downloadQueue = DispatchQueue(label: "dl\(photo.id)", attributes: [])

             // call dispatch async to send a closure to the downloads queue
             downloadQueue.async { () -> Void in

                 // download Data
                do {
                    let imgData = try Data(contentsOf: imageURL)
                    // display it
                    DispatchQueue.main.async(execute: { () -> Void in
                        newPhoto.imageData = imgData
                            do {
                                try self.dataContext.save()
                            } catch {
                                fatalError("The data could not be saved: \(error.localizedDescription)")
                            }
                        print("Appnding to savedImages Array")
                        self.savedImages.append(newPhoto)
                        print("Reloading Collection View")
                        self.photoCollectionView.reloadData()
                    })
                } catch {
                    print("The image at \(imageURL.absoluteString): \(error.localizedDescription)")
                }
                 
             }
            
            
             
             // save new photos to Core Data as they download in background queue
             newPhoto.awakeFromInsert()
          
        }
                
    }
    
    //MARK: New Collection Request
    @IBAction func newCollectionRequest(_ sender: Any) {
        // Clear out old photos
        // Create Fetch Request
        let photoFetchRequest:NSFetchRequest<NSFetchRequestResult> = Photo.fetchRequest()

        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: photoFetchRequest)

        do {
            try dataContext.execute(batchDeleteRequest)
        } catch {
            fatalError("The old image deletes could not be performed: \(error.localizedDescription)")
        }
        
        // Full delete of savedImages
        self.savedImages = []
        photoCollectionView.reloadData()

        // Download New Set of Photos
        self.downloadPhotoInformationFromFlickr()
    }
    
    //MARK: Collection View Set-up
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.savedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoAlbumCellReuseId, for: indexPath) as! PhotoAlbumCell
           // Set the image
        cell.imageView?.image = UIImage(data: self.savedImages[indexPath.row].imageData!)
           
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alertVC = UIAlertController(title: "Delete this image?", message: nil, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in self.deletePhoto(indexPath: indexPath)}))
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        // display alert
        present(alertVC, animated: true, completion: nil)
    }
    
    func deletePhoto(indexPath: IndexPath){
        // delete from core data and save
        self.dataContext.delete(savedImages[indexPath.row])
        self.savedImages.remove(at: indexPath.row)
        do {
            try self.dataContext.save()
        } catch {
            fatalError("The data save could not be performed: \(error.localizedDescription)")
        }
        // delete from view
        self.photoCollectionView.reloadData()
    }
}

    
