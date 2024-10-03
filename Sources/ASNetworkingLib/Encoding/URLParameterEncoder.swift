//
//  URLEncoding.swift
//  NetworkLayer
//
//  Created by Malcolm Kumwenda on 2018/03/05.
//  Copyright © 2018 Malcolm Kumwenda. All rights reserved.
//

import Foundation

public struct URLParameterEncoder: ParameterEncoder {
  public func encode(urlRequest: inout URLRequest, with parameters: ServiceParameters) throws {
    
    guard let url = urlRequest.url else { throw NetworkError.errorWithDefault(.missingURL) }
    
    if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
      !parameters.isEmpty {
      
      if let queryItems = urlComponents.queryItems {
        urlComponents.queryItems = queryItems
      } else {
        urlComponents.queryItems = [URLQueryItem]()
      }
      // Get key params array
      let itemKeys = urlComponents.queryItems?.map({return $0.name}) ?? []
      for (key,value) in parameters {
        // Add parameters only if url dont contains same key
        if !itemKeys.contains(key) {
          let queryItem = URLQueryItem(name: key , value: "\(value)")
          urlComponents.queryItems?.append(queryItem)
        }
      }
      urlRequest.url = urlComponents.url
    }
    
    if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
      urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
    }
    
  }
}
