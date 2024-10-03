//
//  ASNetworkError.swift
//  Pokedex
//
//  Created by Luis Alonso Salcido Martínez on 16/05/24.
//

import Foundation

public enum ASNetworkDefaultError: String {
  case parseFailed = "Error with object parce"
  case wrongStructure = "Wrong Structure"
  case requestFailed = "Request Failed"
  case missingURL = "Missing URL"
}

public struct ASNetworkError: Error, LocalizedError {
  
  public let message: String
  public let httpCode: Int
  
  public static func errorWithDefault(_ defaultError: ASNetworkDefaultError) -> ASNetworkError {
    return ASNetworkError.errorWithMesssage(defaultError.rawValue)
  }
  
  public static func errorWithMesssage(_ message: String, code: Int = 500) -> ASNetworkError {
    return ASNetworkError(message: message,
                        httpCode: code)
  }
  
  public static func errorForServiceResponse(error: Error) -> ASNetworkError {
    let errorMessage = error.localizedDescription
    let httpCode = (error as NSError).code
    return ASNetworkError(message: errorMessage, httpCode: httpCode)
  }
}
