//
// MapViewController.swift
//  Virtual Tourist
//
//  Created by mahmoud diab on 6/19/20.
//  Copyright © 2020 Diab. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    //MARK:- Variables -
    var dataController : DataController!
    var fetchedResultsController : NSFetchedResultsController<Pin>!
    
    //MARK:- Outlets -
    @IBOutlet var mapView: MKMapView!
   
    //MARK:- LifeCycle-
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
        print(Array(UserDefaults.standard.dictionaryRepresentation()))
        mapView.delegate = self
        fetchedResultsController.delegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateEditButtonState()
    }
    
    func initialSetup(){
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        if let region = MKCoordinateRegion.load(withKey: "mapregion"){
            mapView.region = region
        }
        setupFetchedResultsController(completion: loadMap(fetchSuccessful:))
    }
    
    
    //MARK:- Long Tap Gesture On MapView
    @IBAction func mapLongTap(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began{
            let tapLocation = sender.location(in: mapView)
            let coordinate = self.mapView.convert(tapLocation, toCoordinateFrom: self.mapView)
            addPin(coordinate)
        }
    }
    
    //MARK: Remove annotation from mapView
    func deleteAnnotation(_ fromCoordinate : CLLocationCoordinate2D){
        let annotations =  mapView.annotations.filter { $0.coordinate == fromCoordinate}
        let annotationtoDelete = annotations.first
        mapView.removeAnnotation(annotationtoDelete!)
    }
    
    //MARK: Delete Pin from coreData
    func deletePin(_ pin:MKAnnotation){
        let coord = pin.coordinate
        let pinToDelete = fetchPin(coord)!
        dataController.viewContext.delete(pinToDelete)
        do {
            try dataController.viewContext.save()
        } catch { print(error.localizedDescription)  }
        updateEditButtonState()
    }
    
    func updateEditButtonState() {
        if let sections = fetchedResultsController.sections{
            navigationItem.rightBarButtonItem?.isEnabled = sections[0].numberOfObjects > 0
            if !(navigationItem.rightBarButtonItem?.isEnabled ?? false) { isEditing = false }
        }
    }
    
    //MARK: get pin from annotation
    func fetchPin(_ coordinate: CLLocationCoordinate2D) -> Pin?{
        if let pins = fetchedResultsController.fetchedObjects{
            let pin = pins.filter{ $0.coordinate == coordinate}
            return pin.first
        }
        return nil
    }
 
    
    //MARK: Add annotation to mapView
    func AddAnnotationToMap(_ fromCoordinate: CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = fromCoordinate
        mapView.addAnnotation(annotation)
    }
    
    //MARK: Save Pin to coreData
    func addPin(_ coordinate: CLLocationCoordinate2D){
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        pin.page = 1
        do{
            try dataController.viewContext.save()
        } catch {
            print(error.localizedDescription)
        }
        updateEditButtonState()
    }
    
    
    
    
}

//MARK:- Extensions-

// MARK:- MKMapView Delegate Methods EXT.
extension MapViewController : NSFetchedResultsControllerDelegate , MKMapViewDelegate {

    //MARK:-  FetchedResultsController Delegate Methods
        //     Setup FetchedResultsViewController
        func setupFetchedResultsController(completion: @escaping (Bool)->()) {
            let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
            fetchRequest.sortDescriptors = []
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "Pin")
            do{
                try fetchedResultsController.performFetch()
                completion(true)
            } catch{
                completion(false)
                fatalError(error.localizedDescription)
            }
        }
        
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            
            guard let point = anObject as? Pin else {
                print(" Bad location data "); return
            }
            
            switch type {
            case .insert:
                AddAnnotationToMap(point.coordinate)
            case .delete:
                print("Pin Deleted successfuly")
                deleteAnnotation(point.coordinate)
            default:
                break
            }
        }
     // MARK:- MapView Delegate Methods

    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        mapView.region.save(withKey: "mapregion")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if isEditing {
            
            deleteAlert("Pin") { (result) in
                switch result{
                case .success:
                    mapView.deselectAnnotation(view.annotation, animated: true)
                    self.deletePin(view.annotation!)
                case .failure:
                    mapView.deselectAnnotation(view.annotation, animated: true)
                }
            }
            
        } else {
            
            if let vc =  storyboard?.instantiateViewController(identifier: "PhotoCollectionViewController") as? PhotoCollectionViewController {
                let coordinate = view.annotation?.coordinate
                vc.coordinate = coordinate
                vc.dataController = self.dataController
                vc.pin = fetchPin(coordinate!)
//                present(vc,animated: true,completion: nil)
                                    navigationController?.pushViewController(vc, animated: true)
            }
            
            mapView.deselectAnnotation(view.annotation, animated: true)
        }
    }
    // Add Annotations from coredata.
    func loadMap(fetchSuccessful success: Bool){
        if success {
            if let points = fetchedResultsController.fetchedObjects{
                for i in points {
                    let coordinate = i.coordinate
                    AddAnnotationToMap(coordinate)
                }
            }
        }
    }
}



//MARK:- Returns coordinate of Pin .
extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        let latDegrees = CLLocationDegrees(latitude)
        let longDegrees = CLLocationDegrees(longitude)
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
    }
}


//MARK: save region using user defaults.
extension MKCoordinateRegion {
    public  func save(withKey key:String) {
        let locationData = [center.latitude, center.longitude,
                            span.latitudeDelta, span.longitudeDelta]
        UserDefaults.standard.set(locationData, forKey: key)
    }
    
    public static func load(withKey key:String) -> MKCoordinateRegion? {
        guard let region = UserDefaults.standard.object(forKey: key) as? [Double] else { return nil }
        let center = CLLocationCoordinate2D(latitude: region[0], longitude: region[1])
        let span = MKCoordinateSpan(latitudeDelta: region[2], longitudeDelta: region[3])
        return MKCoordinateRegion(center: center, span: span)
    }
}

//Alert
extension UIViewController {
    func deleteAlert(_ item : String,completion: @escaping (Result)->()){
        let deleteAlert = UIAlertController(title: "Delete " + item, message: "This action cannot be undone", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel){ (UIAlertAction) in
            completion(.failure)
        }
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (UIAlertAction) in
            completion(.success)
        }
        deleteAlert.addAction(cancelAction)
        deleteAlert.addAction(deleteAction)
        self.present(deleteAlert,animated: true)
    }
    
}

 
extension CLLocationCoordinate2D: Equatable {}
public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}


enum Result {
    case success
    case failure
}
