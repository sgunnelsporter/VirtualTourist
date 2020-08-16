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
    var fetchedPhotoResultsController:NSFetchedResultsController<Photo>!
    
    var annotation = [MKPointAnnotation]()
    
    //MARK: Other Variables
    let photoAlbumCellReuseId = "PhotoAlbumCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Assign self as delegate to mapView and collectionView
        self.mapView.delegate = self
        //Add pin to the Map
        annotation.append(self.setPinToAnnotation(pin))
        self.mapView.addAnnotations(self.annotation)
        
        
        // Set-up Flow Layout of collection view
        let space : CGFloat = 8.0
        let wDimension = (view.frame.size.width - (2 * space)) / 3.0
        let hDimension = (view.frame.size.height - (2 * space)) / 4.0

        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: wDimension, height: hDimension)
        
        // Load the Pin
        self.photoCollectionView.dataSource = self;
        self.loadPhotoData()
        //self.photoCollectionView.dataSource = fetchedPhotoResultsController;
        
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
        annotation.subtitle = pin.id?.uuidString
        
        return annotation
    }
    
    //MARK: Load the Photo Data
    func loadPhotoData(){
        // make fetch request for the photos for this Pin
        let photoFetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        photoFetchRequest.sortDescriptors = [sortDescriptor]
        let photoPredicate = NSPredicate(format: "associatedPin == %@", pin)
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
            self.downloadPhotoInformationFromFlickr()
        }
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
            newPhoto.imageData = try! Data(contentsOf: imageURL)
            // save new photos to Core Data as they download in background queue
            newPhoto.awakeFromInsert()
            
            //TO Do: Handle Throw
            try? dataContext.save()
            
            photoCollectionView.reloadData()
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
            // TO DO: Error Handling
        }
        
        // Download New Set of Photos
        self.downloadPhotoInformationFromFlickr()
        photoCollectionView.reloadData()
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
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchedPhotoResultsController.fetchedObjects?.count ?? 0
   }
       
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = self.fetchedPhotoResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoAlbumCellReuseId, for: indexPath) as! PhotoAlbumCell
           // Set the image
        cell.imageView?.image = UIImage(data: photo.imageData!)
           
        return cell
   }
       
   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
       //To Do: Segue on tap, unless in edit mode
       //perform segue to detail view
           
   }
}

    
