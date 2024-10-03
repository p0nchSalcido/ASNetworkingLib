//
//  NetworkError.swift
//  Pokedex
//
//  Created by Luis Alonso Salcido Martínez on 16/05/24.
//

import Foundation

public enum DefaultNetworkErrors: String {
  case parseFailed = "Error with object parce"
  case wrongStructure = "Wrong Structure"
  case recuestFailed = "Request Failed"
  case missingURL = "Missing URL"
}

public struct NetworkError: Error, LocalizedError {
  
  public let message: String
  public let httpCode: Int
  
  public static func errorWithDefault(_ defaultError: DefaultNetworkErrors) -> NetworkError {
    return NetworkError.errorWithMesssage(defaultError.rawValue)
  }
  
  public static func errorWithMesssage(_ message: String, code: Int = 500) -> NetworkError {
    return NetworkError(message: message,
                        httpCode: code)
  }
  
  public static func errorForServiceResponse(error: Error) -> NetworkError {
    let errorMessage = error.localizedDescription
    let httpCode = (error as NSError).code
    return NetworkError(message: errorMessage, httpCode: httpCode)
  }
}
