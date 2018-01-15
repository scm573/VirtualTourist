//
//  FlickrApi.swift
//  VirtualTourist
//
//  Created by Wu, Qifan | Keihan | ECID on 2018/01/15.
//

import Foundation
import SVProgressHUD
import CoreLocation

internal func requestPhotosNear(_ coordinate: CLLocationCoordinate2D, completionHandler: @escaping((Data?, URLResponse?, Error?) -> Void)) {
    if !ReachabilityHelper.isNetworkConnected() {
        presentAlert(title: "Network error", message: "No network connection.", preferredStyle: .alert, actionTitle: "Try again")
        return
    }
    
    let request = URLRequest(url: URL(string: "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=15b9dff955bafd96df4e7d92632494fb&lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&extras=url_m&format=json&nojsoncallback=1")!)
    let session = URLSession.shared
    let task = session.dataTask(with: request) { data, response, error in
//        SVProgressHUD.dismiss()
        if let httpResponse = response as? HTTPURLResponse {
            if 400...599 ~= httpResponse.statusCode {
                presentAlert(title: "Server error", message: "Something exploded.", preferredStyle: .alert, actionTitle: "Try again")
                return
            }
        }
        if error != nil {
            presentAlert(title: "Network error", message: error?.localizedDescription ?? "", preferredStyle: .alert, actionTitle: "Try again")
            return
        }
        completionHandler(data, response, error)
    }
//    SVProgressHUD.show()
    task.resume()
}
