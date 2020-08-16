//
//  MainMapView.swift
//  Virtual Tourist
//
//  Created by Sarah Gunnels Porter on 7/13/20.
//  Copyright © 2020 Gunnels Porter. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import CoreLocation

class TravelLocationsMapView: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate {

    //MARK: Outlets & View Variables
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longPressRecognizer: UILongPressGestureRecognizer!
    
    //MARK: Data
    var dataContext:NSManagedObjectContext!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    //MARK: Variable definitions
    let showPhotoAlbumSegueID = "ShowCollection"
    var annotations = [MKPointAnnotation]()
    let annotationReuseId = "pin"
    var tempNewPin: Pin!
    var tempLocationName: String!
    
    //MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        // Set Data Context
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.dataContext = appDelegate?.persistentContainer.viewContext
        self.longPressRecognizer.delegate = self
        self.mapView.addGestureRecognizer(longPressRecognizer)
        self.setupFetchedResultsController()
        // Check if pins were loaded (or exist)
        if let pins = fetchedResultsController.fetchedObjects {
            for pin in pins {
                annotations.append(self.convertPinsToAnnotations(pin))
            }
        }
        self.mapView.addAnnotations(self.annotations)
    }

    //MARK: Data Handling
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        //Load data
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.dataContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func convertPinsToAnnotations(_ pin: Pin) -> MKPointAnnotation{
        // Convert Pins to Annotations for addition to map
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)

        // Create the annotation; setting coordiates, title, and subtitle properties
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = pin.locationName ?? "Still Empty"
        annotation.subtitle = pin.id?.uuidString
        
        return annotation
    }
    
    func convertAnnotationToPin(_ annotation: MKAnnotationView) -> Pin {
        // TO DO:
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let predicate = NSPredicate(format: "id == %@", (annotation.annotation?.subtitle)!!)
        fetchRequest.predicate = predicate
        let tempFetchedResultsController:NSFetchedResultsController<Pin>!
        tempFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.dataContext, sectionNameKeyPath: nil, cacheName: "passPin")
        do {
            try tempFetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        return (tempFetchedResultsController.fetchedObjects?.first)!
    }
    
    //MARK: Long Press Gesture Handling
    @IBAction func addNewPin(_ gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            //Get map coordinates of long press
            let location = self.longPressRecognizer.location(in: self.mapView)
            let coordinate = self.mapView.convert(location, toCoordinateFrom: self.mapView)
            self.getPinLocationName(coordinate)
            // Create alert including location name
            let alertVC = UIAlertController(title: "Add new pin here?", message: self.tempLocationName, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in self.createNewPin(coordinate: coordinate, name: self.tempLocationName)}))
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            // display alert
            present(alertVC, animated: true, completion: nil)
        }
    }
    
    func createNewPin(coordinate: CLLocationCoordinate2D, name: String?){
        //Create and save new pin to Core Data
        let pin = Pin(context: dataContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        pin.locationName = name ?? "Empty"
        
        self.tempNewPin = pin
        
        // Save new pin
        try? dataContext.save()
        
        // Add new annotation to map
        self.mapView.addAnnotation(self.convertPinsToAnnotations(pin))
        
        FlickrAPI.getPhotosForLocation(lat: pin.latitude, lon: pin.longitude, completion: loadInitialPhotosFromFlickr(_:error:))
    }
    
    //MARK: MapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //get a pin view from use reuse queue
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: self.annotationReuseId) as? MKPinAnnotationView

        //set pin view attributes
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: self.annotationReuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            // Perform Segue to Photo Collection View
            // translate annotation to pin
            let pinToPass = self.convertAnnotationToPin(view)
            performSegue(withIdentifier: self.showPhotoAlbumSegueID, sender: pinToPass as Any?)
        }
    }
    
    //MARK: Prepare for segue to collection view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.showPhotoAlbumSegueID {
            //Send Pin and View Context to Album View
           let vc = segue.destination as! PhotoAlbumViewController
            vc.pin = sender as! Pin?
            vc.dataContext = self.dataContext
        }
    }
    
    //MARK: Get Pin Location Name
    func getPinLocationName(_ coordinate: CLLocationCoordinate2D) -> Void {
        let geoCoder = CLGeocoder()
        // Convert location coordinate to location name.
        geoCoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { (places, error) in
            if error == nil{
                let firstLocation = places?[0]
                self.setTempLocationName(firstLocation)
            } else {
                self.setTempLocationName(nil)
            }
        }
    }
    func setTempLocationName(_ location: CLPlacemark?) -> Void {
        if location == location {
            self.tempLocationName = "\(location!.locality ?? ""), \(location!.country ?? "")"
        } else {
            //TO DO: Error Handling
            self.tempLocationName = "Error Occured specifying location. Please try again!"
        }
    }
    
    //MARK: Load Initial Set of Photos from Flickr
    func loadInitialPhotosFromFlickr(_ photoInfo: [PhotoInfo], error: Error?){
        for photo in photoInfo {
            // save new image
            let imageURL = FlickrAPI.imageURL(farm: photo.farm, server: photo.server, id: photo.id, secret: photo.secret)
            let newPhoto = Photo(context: dataContext)
            newPhoto.associatedPin = tempNewPin
            newPhoto.id = UUID()
            // TO DO: Handle throw
            // TO DO: Move to background queue
            newPhoto.imageData = try! Data(contentsOf: imageURL)
            // save new photos to Core Data as they download in background queue
            newPhoto.awakeFromInsert()
            
            //TO Do: Handle Throw
            try? dataContext.save()
        
        }
    }
}

