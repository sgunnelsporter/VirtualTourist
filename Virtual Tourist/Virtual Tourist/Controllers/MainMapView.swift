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

class MainMapView: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    //MARK: Outlets & View Variables
    @IBOutlet weak var mapView: MKMapView!
    
    //MARK: Data
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    //MARK: Variable definitions
    let showCollectionSegueID = "ShowCollection"
    var annotations = [MKPointAnnotation]()
    let annotationReuseId = "pin"
    
    //MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.setupFetchedResultsController()
        self.convertPinsToAnnotations()
        self.mapView.addAnnotations(self.annotations)
    }

    //MARK: Data Handling
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        //TO DO: Set-up Data Controller then load data
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func convertPinsToAnnotations(){
        //TO DO: Set-up Data Controller then convert loaded data to Annotations
        /*for pin in pins {
            let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)

            // Create the annotation; setting coordiates, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = pin.locationName ?? ""
            
            annotations.append(annotation)
        }*/
    }
    //MARK: Long Press Gesture Handling
    @IBAction func addNewPin(_ gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            
            //TO DO: Add alert to confirm pin addition
            // get the location name from geo search
            // create alert including location name
            // display alert
            // create new pin
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
}

