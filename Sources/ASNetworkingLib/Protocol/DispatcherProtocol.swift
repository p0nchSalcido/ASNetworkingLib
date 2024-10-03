//
//  DispatcherProtocol.swift
//  Pokedex
//
//  Created by Luis Alonso Salcido Martínez on 16/05/24.
//

import Foundation

public enum HttpProtocol: String {
  case https = "https://"
  case http  = "http://"
}

public struct Environment {
  public var httpProtocol: HttpProtocol
  public var host: String
  public var port: String
  
  public init(httpProtocol: HttpProtocol, host: String, port: String) {
    self.httpProtocol = httpProtocol
    self.host = host
    self.port = port
  }
  
  public func baseURLString() -> String {
    return httpProtocol.rawValue + host + port
  }
}

protocol DispatcherProtocol {
  init(environment: Environment)
  func fetch(uri:String?, request:RequestProtocol, baseParams: ServiceParameters?) async -> Result<Response,NetworkError>
}
