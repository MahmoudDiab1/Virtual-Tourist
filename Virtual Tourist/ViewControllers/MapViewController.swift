//
// MapViewController.swift
//  Virtual Tourist
//
//  Created by mahmoud diab on 6/19/20.
//  Copyright © 2020 Diab. All rights reserved.
//

import UIKit
import CoreData
import MapKit
class MapViewController: UIViewController {
    //    MARK:- Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIButton!
    
    
    
    
    //    MARK:- Variables
    var dataController:DataController!
    var fetchedResultController : NSFetchedResultsController<Pin>! = nil
     
    
    //    MARK:-LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        fetchedResultController.delegate = self
        // Do any additional setup after loading the view.
    }
    
    
    //    MARK:- Functions and Helpers
    func setupInitialView () {
        guard let mapRegion = UserDefaults.standard.object(forKey:"mapViewRegionData") as? [Double] else { return }
        let locationCoordinate = CLLocationCoordinate2D(latitude: mapRegion[0], longitude: mapRegion[1])
        let coordinateSpan = MKCoordinateSpan(latitudeDelta: mapRegion[3], longitudeDelta: mapRegion[4])
        let coordinateRegion = MKCoordinateRegion(center:locationCoordinate, span: coordinateSpan)
        
        mapView.region = coordinateRegion
        
        fetchPins { loaded in
            if loaded {
                guard let pins = self.fetchedResultController.fetchedObjects else { return }
                for i in 0..<pins.count
                {
                    let lat = pins[i].latitude
                    let long = pins[i].longitude
                    let coordinate = CLLocationCoordinate2D(latitude: lat,longitude: long)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    
                    self.mapView.addAnnotation(annotation)
                    
                }
            }
            
        }
    }
    
//    setup fetchedResultsController.
    func fetchPins(completion:@escaping(Bool)->()) {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        // dataController.viewContext.fetch(fetchRequest)
        fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do{
            try fetchedResultController.performFetch()
            completion(true)
        } catch {
            completion (false)
            fatalError(error.localizedDescription)
        }
        
    }
    
    
    
    
    //    MARK:- Actions
    @IBAction func editButtonPressed(_ sender: Any) {
    }
    
    
    
    
    //    MARK:- Delegate functions
     
    
}
//    MARK:- Extensions

extension MapViewController : MKMapViewDelegate ,NSFetchedResultsControllerDelegate{
//    Automatic save the map region once change occures.
    
     func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let centerLat =  CLLocationDegrees( mapView.region.center.latitude)
        let centerLong =  CLLocationDegrees( mapView.region.center.longitude)
        let spanLong = CLLocationDegrees(  mapView.region.span.longitudeDelta)
        let spanLat = CLLocationDegrees( mapView.region.span.latitudeDelta)
        let mapViewRegionData = [centerLat,centerLong,spanLat,spanLong]
        UserDefaults.standard.set(mapViewRegionData, forKey: "mapViewRegionData")
    }
    
    //        setup NSFetchedResultsControllerDelegate function (controller)did change an object
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let point = anObject as? Pin else { return }
        let lat = CLLocationDegrees( point.latitude )
        let long = ( point.longitude )
        let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: long )
        switch type {
        case .insert:
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            mapView.addAnnotation(annotation)
        case .delete:
            let annotations = mapView.annotations.filter{$0.coordinate == coordinates}
            mapView.removeAnnotation(annotations.first!)
        default:
            break
        }
    }
    
    
    
    
}

extension CLLocationCoordinate2D:Equatable {

    // Mstatic public AKES COORDINATE EQUATABLE
    static public func ==(lhs:CLLocationCoordinate2D,rhs:CLLocationCoordinate2D ) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == lhs.longitude
    }
}

