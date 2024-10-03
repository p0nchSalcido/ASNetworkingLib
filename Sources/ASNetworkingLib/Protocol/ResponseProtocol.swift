//
//  ResponseProtocol.swift
//  Pokedex
//
//  Created by Luis Alonso Salcido Martínez on 16/05/24.
//

import Foundation


public protocol ResponseProtocol {
  var data: Data? {get set}
}

public class Response: ResponseProtocol {
  
  // MARK: - Properties
  let request: RequestProtocol?
  public var data: Data?
  
  public var jsonData: [String:Any]? {
    if let responceData = data, let json = try? JSONSerialization.jsonObject(with: responceData, options: []) {
      return json as? [String:Any]
    }
    return nil
  }
  
  // MARK: - Initialization
  public init(data: Data?, request: RequestProtocol? = nil) {
    self.data = data
    self.request = request
  }
}
