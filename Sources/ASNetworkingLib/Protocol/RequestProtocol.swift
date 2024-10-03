//
//  RequestProtocol.swift
//  Pokedex
//
//  Created by Luis Alonso Salcido Martínez on 16/05/24.
//

import Foundation

public enum HTTPMethod : String {
  case get     = "GET"
  case post    = "POST"
  case put     = "PUT"
  case patch   = "PATCH"
  case delete  = "DELETE"
}

public typealias HTTPHeaders = [String:String]
public typealias ServiceParameters = [String:Any]

public protocol RequestProtocol {
  var path:String {get}
  var method: HTTPMethod {get}
  var headers: HTTPHeaders {get}
  var timeoutInterval:TimeInterval {get}
  var keyDecodingStrategy:JSONDecoder.KeyDecodingStrategy {get}
  
  func getUrlParameters(baseParameters: ServiceParameters?) -> ServiceParameters?
  func getBodyParameters(baseParameters: ServiceParameters?) -> ServiceParameters?
}

public extension RequestProtocol {
  var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy { .convertFromSnakeCase }
}
