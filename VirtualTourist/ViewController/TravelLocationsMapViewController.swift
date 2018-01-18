//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Wu, Qifan | Keihan | ECID on 2018/01/11.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        mapView.delegate = self
        
        let predicate = NSPredicate(value: true)
        queryDataOf(entityName: "Pin", predicate: predicate) { fetchedObjects in
            for pin in fetchedObjects as! [Pin] {
                self.addPinAt(CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.lng))
            }
        }
        
        if let encodedCameraData = UserDefaults.standard.object(forKey: "camera") {
            let camera = NSKeyedUnarchiver.unarchiveObject(with: encodedCameraData as! Data) as! MKMapCamera
            mapView.camera = camera
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAlbum" {
            let photoVC = segue.destination as! PhotoAlbumViewController
            let pinLocation = sender as! CLLocationCoordinate2D
            photoVC.pinLocation = pinLocation
        }
    }
}

extension TravelLocationsMapViewController: MKMapViewDelegate {
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "showAlbum", sender: view.annotation?.coordinate)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let encodedCameraData = NSKeyedArchiver.archivedData(withRootObject: mapView.camera)
        UserDefaults.standard.set(encodedCameraData, forKey: "camera")
    }
    
    func addPinAt(_ coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
}

extension TravelLocationsMapViewController: UIGestureRecognizerDelegate {
    @objc func onLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        let location = gestureReconizer.location(in: mapView)
        let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
        
        addPinAt(coordinate)
        
        let pin = NSEntityDescription.insertNewObject(forEntityName: "Pin", into: AppDelegate.shared.stack.context) as! Pin
        pin.lat = coordinate.latitude
        pin.lng = coordinate.longitude
        
        do {
            try AppDelegate.shared.stack.context.save()
        }
        catch {
            fatalError("Cannot save pin.")
        }
    }
}
