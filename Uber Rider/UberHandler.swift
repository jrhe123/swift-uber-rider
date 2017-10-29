//
//  UberHandler.swift
//  Uber Rider
//
//  Created by Jiarong He on 2017-10-24.
//  Copyright © 2017 Jiarong He. All rights reserved.
//

import Foundation
import FirebaseDatabase

protocol UberController: class {
    
    func canCallUber(delegateCalled: Bool);
    func driverAcceptedRequest(requestAccepted: Bool, driverName: String);
    func updateDriversLocatiion(lat: Double, long: Double);
}

class UberHandler{
    
    private static let _instance = UberHandler();
    
    weak var delegate: UberController?;
    
    var rider = "";
    var driver = "";
    var rider_id = "";
    
    static var Instance: UberHandler{
        return _instance;
    }
    
    func requestUber(latitude: Double, longitude: Double){
        
        let data : Dictionary<String, Any> = [Constants.NAME: rider, Constants.LATITUDE: latitude, Constants.LONGITUDE: longitude];
        
        DBProvider.Instance.requestRef.childByAutoId().setValue(data);
    }
    
    
    func observeMessagesForRider(){
        
        // 1. Rider request Uber
        DBProvider.Instance.requestRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot)
            in
            
            if let data = snapshot.value as? NSDictionary {
                
                if let name = data[Constants.NAME] as? String {
                    
                    if name == self.rider{
                        self.rider_id = snapshot.key;
                        self.delegate?.canCallUber(delegateCalled: true);
                    }
                }
            }
        }
        
        // 2. Rider cancel Uber
        DBProvider.Instance.requestRef.observe(DataEventType.childRemoved) { (snapshot: DataSnapshot)
            in
            
            if let data = snapshot.value as? NSDictionary {
                
                if let name = data[Constants.NAME] as? String {
                    
                    if name == self.rider{
                        self.delegate?.canCallUber(delegateCalled: false);
                    }
                }
            }
        }
        
        // 3. Driver accept request
        DBProvider.Instance.requestAcceptedRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot)
            in
            
            if let data = snapshot.value as? NSDictionary {
                
                if let name = data[Constants.NAME] as? String {
                    
                    if self.driver == "" {
                        self.driver = name;
                        self.delegate?.driverAcceptedRequest(requestAccepted: true, driverName: self.driver);
                    }
                }
            }
        }
        
        // 4. Driver cancel request
        DBProvider.Instance.requestAcceptedRef.observe(DataEventType.childRemoved) { (snapshot: DataSnapshot)
            in
            
            if let data = snapshot.value as? NSDictionary {
                
                if let name = data[Constants.NAME] as? String {
                    
                    if name == self.driver {
                        self.driver = "";
                        self.delegate?.driverAcceptedRequest(requestAccepted: false, driverName: name);
                    }
                }
            }
        }
        
        // 5. Check Driver Location
        DBProvider.Instance.requestAcceptedRef.observe(DataEventType.childChanged) { (snapshot: DataSnapshot)
            in
            
            if let data = snapshot.value as? NSDictionary {
                
                if let name = data[Constants.NAME] as? String {
                    
                    if name == self.driver {
                        
                        if let lat = data[Constants.LATITUDE] as? Double{
                            
                            if let long  = data[Constants.LONGITUDE] as? Double{
                                
                                self.delegate?.updateDriversLocatiion(lat: lat, long: long);
                            }
                        }
                    }
                }
            }
        }
        
        
    }
    
    func cancelUber() {
        
        DBProvider.Instance.requestRef.child(rider_id).removeValue();
    }
    
    
    func updateRiderLocation(lat: Double, long: Double){
        
        DBProvider.Instance.requestAcceptedRef.child(rider_id).updateChildValues([Constants.LATITUDE: lat, Constants.LONGITUDE: long]);
    }
    
    
    
    
} // class


