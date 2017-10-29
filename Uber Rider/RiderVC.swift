//
//  RiderVC.swift
//  Uber Rider
//
//  Created by Jiarong He on 2017-10-23.
//  Copyright © 2017 Jiarong He. All rights reserved.
//

import UIKit
import MapKit

class RiderVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UberController {

    
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var callUberBtn: UIButton!
    
    
    // MAP
    private var locationManager = CLLocationManager();
    private var userLocation: CLLocationCoordinate2D?;
    private var driverLocation: CLLocationCoordinate2D?;
    
    
    // Timer
    private var timer = Timer();
    
    
    // default
    private var canCallUber = true;
    private var riderCanceledRequest = false;
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeLocationManager();
        
        
        // delegate connect !!
        UberHandler.Instance.delegate = self;
        UberHandler.Instance.observeMessagesForRider();
    }
    
    
    private func initializeLocationManager(){
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.requestWhenInUseAuthorization();
        locationManager.startUpdatingLocation();
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locationManager.location?.coordinate{
            
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude);
            
            let region = MKCoordinateRegion(center: userLocation!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01));
            
            myMap.setRegion(region, animated: true);
            self.myMap.removeAnnotations(self.myMap.annotations);
            
            
            if driverLocation != nil{
                if !canCallUber {
                    let driverAnnotation = MKPointAnnotation();
                    driverAnnotation.coordinate = driverLocation!;
                    driverAnnotation.title = "Driver Location";
                    myMap.addAnnotation(driverAnnotation);
                }
            }
            
            
            let annotation = MKPointAnnotation();
            annotation.coordinate = userLocation!;
            annotation.title = "Driver Location";
            myMap.addAnnotation(annotation);
        }
        
    }
    
    
    func updateRidersLocation(){
        
        UberHandler.Instance.updateRiderLocation(lat: userLocation!.latitude, long: userLocation!.longitude);
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logout(_ sender: Any) {
        
        if AuthProvider.init().logout(){
            
            if !canCallUber{
                UberHandler.Instance.cancelUber();
                timer.invalidate();
            }
            
            dismiss(animated: true, completion: nil);
        }else{
            self.alerTheUser(title: "Could Not Logout", message: "We could not logout at the moment, please try again later");
        }
    }
    
    
    // 1. delegate func
    func canCallUber(delegateCalled: Bool) {
        
        if delegateCalled {
            
            callUberBtn.setTitle("Cancel Uber", for: UIControlState.normal);
            canCallUber = false;
        }else{
            
            callUberBtn.setTitle("Call Uber", for: UIControlState.normal);
            canCallUber = true;
        }
    }
    
    // 2. delegate func
    func driverAcceptedRequest(requestAccepted: Bool, driverName: String){
        
        if !riderCanceledRequest{
            if requestAccepted{
                alerTheUser(title: "Uber Accepted", message: "\(driverName) Accepted Your Uber Request")
            }else{
                UberHandler.Instance.cancelUber();
                timer.invalidate();
                alerTheUser(title: "Uber Canceled", message: "\(driverName) Canceled Uber Request")
            }
        }
        riderCanceledRequest = false;
    }
    
    // 3. deletegate func
    func updateDriversLocatiion(lat: Double, long: Double){
        
        driverLocation = CLLocationCoordinate2D(latitude: lat, longitude: long);
    }
    
    
    
    @IBAction func callUber(_ sender: Any) {
        
        if userLocation != nil {
            
            if canCallUber {
                
                UberHandler.Instance.requestUber(latitude: Double(userLocation!.latitude), longitude: Double(userLocation!.longitude));
                
                
                // update location
                timer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(RiderVC.updateRidersLocation), userInfo: nil, repeats: true);
                
            } else {
                
                riderCanceledRequest = true;
                
                // cancel uber
                UberHandler.Instance.cancelUber();
                
                timer.invalidate();
            }
        }
    }
    
    
    private func alerTheUser(title: String, message: String){
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil);
        
        alert.addAction(ok);
        present(alert, animated: true, completion: nil);
    }

} // class









