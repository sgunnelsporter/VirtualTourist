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
    var dataContext:NSManagedObjectContext = DataContext.persistentContainer.viewContext
    var pin:Pin!
    
    var annotation = [MKPointAnnotation]()
    var loadedPhotoInfo:[PhotoInfo] = []
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
        self.preloadSavedPhotos()
                
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
    func preloadSavedPhotos() {
        do {
            let fetchedPhotoResultsController = getFetchRequestController()
            try fetchedPhotoResultsController.performFetch()
            let photoCount = try fetchedPhotoResultsController.managedObjectContext.count(for: fetchedPhotoResultsController.fetchRequest)
            for index in 0..<photoCount {
                self.savedImages.append(fetchedPhotoResultsController.object(at: IndexPath(row: index, section: 0)))
            }
        } catch {
            fatalError("There was an error loading photo data from core!")
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
        FlickrAPI.getPhotosForLocation(pin: pin, completion: loadPhotoInfoFromFlickr(pin:_:error:))
    }
    
    func loadPhotoInfoFromFlickr(pin: Pin,_ photoInfo: [PhotoInfo], error: Error?){
        if error == nil {
            for info in photoInfo {
                Photo.createNew(pin: pin, info: info)
            }
        } else {
            // TO DO: Error Handling
            print("The photo info failed to download: \(error!.localizedDescription)")
        }
    }

    
    //MARK: Download the Photo from Flickr using PhotoInfo
    func downloadPhotoFromFlickr(_ photo: Photo, index: IndexPath) -> Void {
        if let url = photo.imageURL {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data else {
                    print("no data, or there was an error")
                    return
                }
                photo.imageData = data
                do {
                    try self.dataContext.save()
                } catch {
                    fatalError("The old image deletes could not be performed: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
                    self.photoCollectionView.reloadItems(at: [index])
                }
            }
            task.resume()
        }
    }
    
    //MARK: New Collection Request
    @IBAction func newCollectionRequest(_ sender: Any) {
        // Clear out old photos
        for photo in savedImages {
            photo.imageURL = nil
            photo.imageData = nil
            do {
                try dataContext.save()
            } catch {
                fatalError("The old image deletes could not be performed: \(error.localizedDescription)")
            }
        }
        
        // Full delete of savedImages
        photoCollectionView.reloadData()

        // Reset Photo Info Array
        self.loadedPhotoInfo = []

        // Download New Set of Photos
        self.downloadPhotoInformationFromFlickr()
        self.preloadSavedPhotos()
        photoCollectionView.reloadData()
    }
    
    //MARK: Collection View Set-up
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create Cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoAlbumCellReuseId, for: indexPath) as! PhotoAlbumCell
        // Check for photo and set if there
        if let photo = self.savedImages[indexPath.row].imageData {
            cell.activityIndicator.stopAnimating()
            cell.imageView?.image = UIImage(data: photo)
            
        } else {
            // Set the activity indicator to enabled
            cell.activityIndicator.startAnimating()
            cell.imageView.image = nil
            // Download Photo
            if self.savedImages[indexPath.row].imageURL != nil {
                
                self.downloadPhotoFromFlickr(self.savedImages[indexPath.row], index: indexPath)
                
                if self.savedImages[indexPath.row].imageData != nil {
                    // Reload Data assigned to main queue
                    DispatchQueue.main.async(execute: { () -> Void in
                        print("Load Image View")
                        cell.imageView?.image = UIImage(data: (self.savedImages[indexPath.row].imageData)!)
                        cell.activityIndicator.stopAnimating()
                    })
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
        // Delete from Core Data
        self.dataContext.delete(savedImages[indexPath.row])
        
        // Delete from view
        self.savedImages.remove(at: indexPath.row)
        self.photoCollectionView.reloadData()
        
        // Save Core Data
        do {
            try self.dataContext.save()
        } catch {
            fatalError("The data save could not be performed: \(error.localizedDescription)")
        }
    }
}

    
