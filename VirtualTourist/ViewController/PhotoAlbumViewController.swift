//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Wu, Qifan | Keihan | ECID on 2018/01/11.
//

import UIKit
import MapKit
import Kingfisher
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var pinLocation: CLLocationCoordinate2D?
    var pin: Pin?
    var pages: Int?
    var downloadedPhotos: [FlickrApiResponse.Photos.Photo]? {
        didSet {
            performUIUpdatesOnMain {
                self.downloadedPhotos?.forEach { self.insert($0) }
                let predicate = NSPredicate(format: "pin = %@", argumentArray: [self.pin!])
                queryDataOf(entityName: "Photo", predicate: predicate) { fetchedObjects in
                    self.photoEntities = fetchedObjects as? [Photo]
                }
            }
        }
    }
    var photoEntities: [Photo]? {
        didSet {
            performUIUpdatesOnMain { self.collectionView.reloadData() }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        guard let coordinate = pinLocation else { return }
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        mapView.setCenter(coordinate, animated: false)
        
        guard let pin = pin else { return }
        let predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
        queryDataOf(entityName: "Photo", predicate: predicate) { fetchedObjects in
            if fetchedObjects.count == 0 {
                self.request()
            } else {
                self.photoEntities = fetchedObjects as? [Photo]
                self.newCollectionButton.isEnabled = true
            }
        }
    }
    
    @IBAction func requestNewCollection(_ sender: Any) {
        newCollectionButton.isEnabled = false
        deleteAllPhotos()
        request()
    }
    
    func request() {
        guard let coordinate = pinLocation else { return }
        requestPhotosNear(coordinate, pages: pages) { data, response, error in
            let decoder: JSONDecoder = JSONDecoder()
            do {
                performUIUpdatesOnMain {
                    self.newCollectionButton.isEnabled = true
                }
                let flickrApiResponse: FlickrApiResponse = try decoder.decode(FlickrApiResponse.self, from: data!)
                self.downloadedPhotos = flickrApiResponse.photos?.photo
                self.pages = flickrApiResponse.photos?.pages
            } catch {
                performUIUpdatesOnMain {
                    self.newCollectionButton.isEnabled = true
                }
                print("json convert failed in JSONDecoder", error.localizedDescription)
            }
        }
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoEntities?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoAlbumUICollectionViewCell
        
        let photoEntity = photoEntities?[indexPath.row]
        if let imageData = photoEntity?.imageData {
            cell.imageView.image = UIImage(data: imageData)
        } else {
            let imageUrl = URL(string: (photoEntities?[indexPath.row].url)!)
            cell.imageView.kf.indicatorType = .activity
            cell.imageView.kf.setImage(with: imageUrl, placeholder: UIImage(named: "AppIcon"))
            
            KingfisherManager.shared.retrieveImage(with: imageUrl!, options: nil, progressBlock: nil) { image, error, cacheType, imageURL in
                if let image = image {
                    photoEntity?.imageData = UIImageJPEGRepresentation(image, 1)
                    do {
                        try AppDelegate.shared.stack.context.save()
                    }
                    catch {
                        fatalError("Failed when saving a photo.")
                    }
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToBeDeleted = self.photoEntities?[indexPath.row]
        delete(photoToBeDeleted!)
        self.photoEntities?.remove(at: indexPath.row)
        self.collectionView.reloadData()
    }
}

extension PhotoAlbumViewController {
    func insert(_ photo: FlickrApiResponse.Photos.Photo) {
        let photoEntity = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: AppDelegate.shared.stack.context) as! Photo
        photoEntity.pin = pin
        photoEntity.url = photo.url_m
        
        do {
            try AppDelegate.shared.stack.context.save()
        }
        catch {
            fatalError("Failed when saving a photo.")
        }
    }
    
    func delete(_ photo: Photo) {
        do {
            AppDelegate.shared.stack.context.delete(photo)
            try AppDelegate.shared.stack.context.save()
        }
        catch {
            fatalError("Failed when deleting a photo.")
        }
    }
    
    func deleteAllPhotos() {
        do {
            self.photoEntities?.forEach { AppDelegate.shared.stack.context.delete($0) }
            try AppDelegate.shared.stack.context.save()
        }
        catch {
            fatalError("Failed when deleting photos.")
        }
    }
}
