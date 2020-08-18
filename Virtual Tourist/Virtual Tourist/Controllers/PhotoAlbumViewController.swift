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
    var loadedPhotoInfo:[PhotoInfo] = []
    var savedImages:[Photo?] = []
    
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
        savedImages = preloadSavedPhotos()
                
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
    func preloadSavedPhotos() -> [Photo] {
        var photoArray:[Photo] = []
        do {
            let fetchedPhotoResultsController = getFetchRequestController()
            try fetchedPhotoResultsController.performFetch()
            let photoCount = try fetchedPhotoResultsController.managedObjectContext.count(for: fetchedPhotoResultsController.fetchRequest)
            for index in 0..<photoCount {
                photoArray.append(fetchedPhotoResultsController.object(at: IndexPath(row: index, section: 0)))
            }
        } catch {
            fatalError("There was an error loading photo data from core!")
        }
        return photoArray

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
        FlickrAPI.getPhotosForLocation(pin: pin, completion: loadPhotoInfoFromFlickr(pin:_:error:))
    }
    
    func loadPhotoInfoFromFlickr(pin: Pin,_ photoInfo: [PhotoInfo], error: Error?){
        if error == nil {
            self.loadedPhotoInfo = photoInfo
        } else {
            // TO DO: Error Handling
            print("The photo info failed to download: \(error!.localizedDescription)")
        }
    }
    
    //MARK: Download the Photo from Flickr using PhotoInfo
    func downloadPhotoFromFlickr(_ photo: Photo) -> Void {
        let downloadQueue = DispatchQueue(label: "dl:\(photo.id!)", attributes: [])

         // call dispatch async to send a closure to the downloads queue
        downloadQueue.async { () -> Void in
             // download Data
            do {
                let imgData = try Data(contentsOf: photo.imageURL!)
                photo.imageData = imgData
            } catch {
                print("The image at \(photo.imageURL!.absoluteString): \(error.localizedDescription)")
            }
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
        // Create Cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoAlbumCellReuseId, for: indexPath) as! PhotoAlbumCell
        // Check for photo and set if there
        if let photo = self.savedImages[indexPath.row]?.imageData {
            cell.activityIndicator.stopAnimating()
            cell.imageView?.image = UIImage(data: photo)
            
        } else {
            // Set the activity indicator to enabled
            cell.activityIndicator.startAnimating()
            // Download Photo
            if self.savedImages[indexPath.row]?.imageURL != nil {
                
                self.downloadPhotoFromFlickr(self.savedImages[indexPath.row]!)
                
                if self.savedImages[indexPath.row]?.imageData != nil {
                    // Reload Data assigned to main queue
                    DispatchQueue.main.async(execute: { () -> Void in
                        print("Load Image View")
                        cell.imageView?.image = UIImage(data: (self.savedImages[indexPath.row]?.imageData)!)
                        cell.activityIndicator.stopAnimating()
                    })
                    // Update Core Data to match new savedImage
                    self.dataContext.refresh(self.savedImages[indexPath.row]!, mergeChanges: true)
                    // Save Core Data
                    do {
                        try self.dataContext.save()
                    } catch {
                        fatalError("The data could not be saved: \(error.localizedDescription)")
                    }
                }
            }
        }
        
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
        // find associated Photo from Core Data
        
        // delete from view
        self.savedImages.remove(at: indexPath.row)
        self.photoCollectionView.reloadData()
        
        // delete from core data and save
        self.dataContext.delete(savedImages[indexPath.row]!)
        
        do {
            try self.dataContext.save()
        } catch {
            fatalError("The data save could not be performed: \(error.localizedDescription)")
        }
        // delete from view
    }
}

    
