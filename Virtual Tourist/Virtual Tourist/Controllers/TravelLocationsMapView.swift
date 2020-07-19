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

class TravelLocationsMapView: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate {

    //MARK: Outlets & View Variables
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longPressRecognizer: UILongPressGestureRecognizer!
    
    //MARK: Data
    var dataContext:NSManagedObjectContext!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    //MARK: Variable definitions
    let showCollectionSegueID = "ShowCollection"
    var annotations = [MKPointAnnotation]()
    let annotationReuseId = "pin"
    
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
        annotation.title = pin.locationName ?? ""
        
        return annotation
    }
    
    //MARK: Long Press Gesture Handling
    @IBAction func addNewPin(_ gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            //Get map coordinates of long press
            let location = self.longPressRecognizer.location(in: self.mapView)
            let coordinate = self.mapView.convert(location, toCoordinateFrom: self.mapView)
            // Get the location name from geo search
            let locationName = self.getPinLocationName(coordinate)
            // Create alert including location name
            let alertVC = UIAlertController(title: "Add new pin for", message: locationName, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in self.createNewPin(coordinate: coordinate, name: locationName)}))
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            // display alert
            show(alertVC, sender: nil)
        }
    }
    
    func createNewPin(coordinate: CLLocationCoordinate2D, name: String?){
        //Create and save new pin to Core Data
        let pin = Pin(context: dataContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        pin.locationName = name ?? ""
        
        // Save new pin
        try? dataContext.save()
        
        // Add new annotation to map
        self.mapView.addAnnotation(self.convertPinsToAnnotations(pin))
    }
    
    //MARK: MapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //get a pin view from use reuse queue
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: self.annotationReuseId) as? MKPinAnnotationView

        //set pin view attributes
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: self.annotationReuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .blue
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
            performSegue(withIdentifier: self.showCollectionSegueID, sender: self)
        }
    }
    
    //MARK: Prepare for segue to collection view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.showCollectionSegueID {
            //TO DO: Send Pin id to Collection View
           /* let controller = segue.destination as! PhotoAlbumView
            let controller.pinId = pinId*/
        }
    }
    
    //MARK: Get Pin Location Name
    func getPinLocationName(_ coordinate: CLLocationCoordinate2D) -> String? {
        var locationName: String!
        let geoCoder = CLGeocoder()
        // Convert location coordinate to location name.
        geoCoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { (places, error) in
            if error == nil{
                if let place = places{
                    // Get city & Country
                    let city = place.first?.locality ?? ""
                    let country = place.first?.country ?? ""
                    locationName = "\(city), \(country)"
                } else {
                    //TO DO: Handle Error
                    locationName = "Something weird is happending"
                }
            }
        }
        return locationName
    }
}

