//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by mahmoud diab on 6/23/20.
//  Copyright © 2020 Diab. All rights reserved.
//
 
import Foundation
import UIKit
 

class FlickrClient {
    //MARK: CONSTANTS
    private static let flickrEndpoint  = "https://api.flickr.com/services/rest/"
    private static let flickrAPIKey    = "6631798c498928174b419c82dcbeccb8"
    private static let flickrSearch    = "flickr.photos.search"
    private static let format          = "json"
    private static let searchRangeKM   = 10
    private static let perpage = 25
    
    
    //MARK:- GET REQUEST
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let range = Range(uncheckedBounds: (14, data.count - 1))
                let newData = data.subdata(in: range)
                let responseObject = try decoder.decode(ResponseType.self, from: newData)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
               
                    DispatchQueue.main.async {
                        completion(nil, error)
                }
            }
        }
        task.resume()
        
        return task
    }
    
    //MARK: Get resposne of request
    static func getFlickrImages(lat: Double, lng: Double,page:Int, completion: @escaping (Int,[FlickrImage]?,Error?) -> Void) {
            let request = URL(string: "\(flickrEndpoint)?method=\(flickrSearch)&format=\(format)&api_key=\(flickrAPIKey)&lat=\(lat)&lon=\(lng)&radius=\(searchRangeKM)&page=\(page)&per_page=\(perpage)")!
                
        print(request)
        taskForGETRequest(url: request, responseType: PhotosResponse.self) { (result, error) in
            if let error = error {
                completion(0,nil,error)
                return
            }
            let photos = result?.photos.photo
            let numberOfPages = (result?.photos.pages) ?? 0
            completion(numberOfPages,photos,nil)
        }
    }
    
    
    class func requestImageFile(_ url : URL, completion: @escaping (Data?,Error?) -> Void){
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {completion(nil,error) ; return }
            completion(data,nil)
        }
        task.resume()
    }
}
