//
//  FirebaseNetworkService.swift
//  GifConverter
//
//  Created by Brian Rosales on 9/26/25.
//

import Foundation
/// Article: https://firebase.google.com/docs/database/rest/auth#python

/// Firebase web API Key: AIzaSyBCGnxPK_F2Td3_BKm3519KoQuTlRUNkJU

class FirebaseNetworkService {
    // https://firestore.googleapis.com/v1/projects/animebuddies-f6e62/databases/(default)/documents/
    
    serviceAccount.
    
    func fetch() async {
        let url : String = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyBCGnxPK_F2Td3_BKm3519KoQuTlRUNkJU"
        
        let document = "demo"
        
        guard let newURL = URL(string: url + document) else {
            print("URL Failed to create")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: newURL)
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                print("Not valid status code")
                return
            }
            
            print("code: \(statusCode)")
            //            guard (200...299).contains(statusCode) else {
            //                print("Response not ok")
            //                if statusCode == 404 {
            //                    print("404 Not Found!")
            //                } else if statusCode == 403 {
            //                    print("Permission denied")
            //                }
            //                return
            //            }
        } catch {
            print(error)
        }
    }
}
