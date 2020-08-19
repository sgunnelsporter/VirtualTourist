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
    var dataContext:NSManagedObjectContext = DataContext.persistentContainer.viewContext
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
        do {
            try dataContext.save()
        } catch {
            fatalError("The data save could not be performed: \(error.localizedDescription)")
        }
        
        // Add new annotation to map
        self.mapView.addAnnotation(self.convertPinsToAnnotations(pin))
        
        //Enhancement - To Do:
        FlickrAPI.getPhotosForLocation(pin: pin, completion: loadPhotoInfoFromFlickr(pin:_:error:))
    }
    
    //MARK: Completion Function for getting Photo Info from Flickr
    func loadPhotoInfoFromFlickr(pin: Pin,_ photoInfo: [PhotoInfo], error: Error?){
        if error == nil {
            for info in photoInfo {
                let newPhoto = Photo(context: dataContext)
                newPhoto.associatedPin = pin
                newPhoto.id = UUID()
                newPhoto.imageURL = FlickrAPI.imageURL(farm: info.farm, server: info.server, id: info.id, secret: info.secret)
                //  Save Core Data
                do {
                    try self.dataContext.save()
                } catch {
                    fatalError("The data could not be saved: \(error.localizedDescription)")
                }
            }
        } else {
            // TO DO: Error Handling
            print("The photo info failed to download: \(error!.localizedDescription)")
        }
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
        if let location = location {
            self.tempLocationName = "\(location.locality ?? ""), \(location.country ?? "")"
        } else {
            //TO DO: Error Handling
            self.tempLocationName = "Error Occured specifying location. Please try again!"
        }
    }
    
}

