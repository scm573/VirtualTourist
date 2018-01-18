//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Wu, Qifan | Keihan | ECID on 2018/01/11.
//

import UIKit
import MapKit
import Kingfisher

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var pinLocation: CLLocationCoordinate2D?
    var photos: [FlickrApiResponse.Photos.Photo]? {
        didSet {
            guard let photos = photos else { return }
            randomPhotos = Array(photos.sorted { _,_ in arc4random_uniform(1) == 0 }.prefix(21)).map { $0 }
        }
    }
    var randomPhotos: [FlickrApiResponse.Photos.Photo]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        guard let coordinate = pinLocation else { return }
        request()
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        mapView.setCenter(coordinate, animated: false)
    }
    
    @IBAction func requestNewCollection(_ sender: Any) {
        newCollectionButton.isEnabled = false
        request()
    }
    
    func request() {
        guard let coordinate = pinLocation else { return }
        requestPhotosNear(coordinate) { data, response, error in
            let decoder: JSONDecoder = JSONDecoder()
            do {
                defer {
                    self.newCollectionButton.isEnabled = true // Too slow here, why?
                }
                let flickrApiResponse: FlickrApiResponse = try decoder.decode(FlickrApiResponse.self, from: data!)
                self.photos = flickrApiResponse.photos?.photo
                performUIUpdatesOnMain { self.collectionView.reloadData() }
            } catch {
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
        return randomPhotos?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoAlbumUICollectionViewCell
        let imageUrl = URL(string: (randomPhotos?[indexPath.row].url_m)!)
        cell.imageView.kf.indicatorType = .activity
        cell.imageView.kf.setImage(with: imageUrl)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}
