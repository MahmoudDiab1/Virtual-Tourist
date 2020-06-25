//
//  PhotoCollectionViewController.swift
//  Virtual Tourist
//
//  Created by mahmoud diab on 6/20/20.
//  Copyright © 2020 Diab. All rights reserved.
// 
import UIKit
import MapKit
import CoreData

class PhotoCollectionViewController: UIViewController {
    
    //MARK:- Outlets
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var barButton: UIButton!
    @IBOutlet var emptyImageLable: UILabel!
    
    //MARK:- Variables
    
    var coordinate : CLLocationCoordinate2D!
    var dataController : DataController!
    var fetchedResultsController : NSFetchedResultsController<Photo>! 
    var pin : Pin!
    
    // Datasource of collectionView
    var photos : [UIImage] = Array(repeating: UIImage(named: "placeholder.png")! , count: 25){
        didSet{
            if !(photos.contains( UIImage(named: "placeholder.png")!) ) {
                barButton.isEnabled = true
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            }
            if photos.isEmpty {
              emptyImageLable.alpha = 1
            }
        }
    }
    
    //MARK:- Constants
    let spaceBetweenItem:CGFloat = 5
    let totalCellCount:Int = 20
    let cellIdentifier = "cell"
    
    
    //MARK:- Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
    }
    
    //MARK: setupScene
    func  setupScene(){
        //collectionView FlowLayout setup
        let space: CGFloat = 5.0
        let dimension = (self.view.frame.size.width - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = spaceBetweenItem
        flowLayout.minimumLineSpacing = spaceBetweenItem
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        // setupMap
        setupMap()
        setupFetchedResultsController()
        fetchSuccess()
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    //MARK:- NEW COLLECTION
    @IBAction func newCollectionPressed(_ sender: Any) {
        barButton.isEnabled = false
        deleteAllPhotos()
        photos = Array(repeating: UIImage(named: "placeholder.png")!  , count: 25)
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
        let page = nextPage()
        pin.page = Int32(page)
        try? dataController.viewContext.save()
        
        FlickrClient.getFlickrImages(lat: coordinate.latitude, lng: coordinate.longitude, page: page, completion: handleSuccessFlickerImages(pages:result:error:))
    }
    
    func nextPage() -> Int {
        return ((pin.page+1) <= pin.pages) ? Int(pin.page+1) : 1
    }
    
    func deleteAllPhotos(){
        for photo in fetchedResultsController.fetchedObjects! {
            dataController.viewContext.delete(photo)
            do{
                try dataController.viewContext.save()
                print("success delete")
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    // Populate array of images from flicker
    func fetchSuccess(){
        if pin.photo?.count == 0 {
            FlickrClient.getFlickrImages(lat: coordinate.latitude, lng: coordinate.longitude, page: 1, completion: handleSuccessFlickerImages(pages:result:error:))
        }
    }
    
    //MARK: Populate array of imageUrls
    func handleSuccessFlickerImages(pages:Int,result:[FlickrImage]?,error:Error?){
        if pages == 0{
            handleEmptyImages()
            return
        }
        saveNumberOfPagesToPin(pages)
        if let result = result{
            photos = Array(repeating: UIImage(named: "placeholder.png")!, count: result.count-1)
            for image in result {
                let imageUrl = URL(string: image.imageURLString())
                FlickrClient.requestImageFile(imageUrl!, completion: self.handleImageDownload(data:error:))
            }
        }
    }
    
    func saveNumberOfPagesToPin(_ pages: Int){
        // Saves pages attribute of pin the first time data is fetched
        if pin.pages == 0{
            pin.pages = Int32(pages)
            try? dataController.viewContext.save()
        }
    }
    
    func handleEmptyImages(){
        photos = []
        collectionView.reloadData()
        collectionView.alpha = 0
        
        
    }
    
    //  Download Images
    func handleImageDownload(data:Data?,error:Error?){
        if let data = data {
            DispatchQueue.main.async {
                if let aPhoto = UIImage(data: data){
                    self.addImageToPhotos(aPhoto)
                    self.collectionView.reloadData()
                }
                self.addImageToCoreData(data)
            }
        } else {
            print(error!.localizedDescription,"Error saving data")
        }
    }
    
    //  Save  to coreData
    func addImageToCoreData(_ data : Data) {
        let photo = Photo(context: dataController.viewContext)
        photo.pin = pin
        photo.imageData = data
        try? dataController.viewContext.save()
    }
    
    //MARK: Delete Image
    func deleteImage(at index: Int) {
        reFetch()
        if let photos = fetchedResultsController.fetchedObjects{
            if photos.count == 0 {
                return
            }
            let imageToDelete = photos[index]
            do{
                dataController.viewContext.delete(imageToDelete)
                try dataController.viewContext.save()
                self.photos.remove(at: index)
                reFetch()
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }catch{
                print(error.localizedDescription)
            }
        }
    }
    
    // Add Image to Photos array
    func addImageToPhotos(_ image: UIImage){
        if photos.contains(UIImage(named: "placeholder.png")!){
            let index = photos.firstIndex(of: UIImage(named: "placeholder.png")!)
            photos[index!] = image
        }else{
            photos.append(image)
        }
    }
    
}

//MARK:-  UICollectionView
extension  PhotoCollectionViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PhotoCollectionViewCell
        cell.collectionImage.image = photos[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width / 3 - spaceBetweenItem
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return spaceBetweenItem
    }
    
    // Delete photo on selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.deleteImage(at: indexPath.item)
    }
}

//MARK:- FetchedResultsController Methods
extension PhotoCollectionViewController : NSFetchedResultsControllerDelegate{
    
    func setupFetchedResultsController(){
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
            let numberOfPhotos = fetchedResultsController.fetchedObjects?.count ?? 0
            photos  =   Array(repeating: UIImage(named: "placeholder.png")! , count: numberOfPhotos)
            for photo in fetchedResultsController.fetchedObjects!{
                if let aPhoto = UIImage(data: photo.imageData!){
                    addImageToPhotos(aPhoto)
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        } catch{
            fatalError(error.localizedDescription)
        }
    }
    
    func reFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("reFetch - \(error)")
        }
    }
}

//MARK:- MapView setup
extension PhotoCollectionViewController: MKMapViewDelegate{
    
    func setupMap(){
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        mapView.region = MKCoordinateRegion(center: coordinate, span: span)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
}
