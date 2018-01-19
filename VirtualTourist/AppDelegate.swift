//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Wu, Qifan | Keihan | ECID on 2018/01/11.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var stack = CoreDataStack(modelName: "Model")!
    static let shared = UIApplication.shared.delegate as! AppDelegate
    
}

