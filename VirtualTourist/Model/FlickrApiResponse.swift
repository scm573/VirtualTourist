//
//  FlickrApiResponse.swift
//  VirtualTourist
//
//  Created by Wu, Qifan | Keihan | ECID on 2018/01/15.
//

import Foundation

struct FlickrApiResponse: Codable {
    let photos: Photos?
    
    struct Photos: Codable {
        let page: Int?
        let pages: Int?
        let perpage: Int?
        let count: String?
        let photo: [Photo]?
        
        struct Photo: Codable {
            let url_m: String?
        }
    }
}
