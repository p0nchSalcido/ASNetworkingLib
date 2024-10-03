//
//  JSONEncoding.swift
//  NetworkLayer
//
//  Created by Malcolm Kumwenda on 2018/03/05.
//  Copyright © 2018 Malcolm Kumwenda. All rights reserved.
//

import Foundation

public struct JSONParameterEncoder: ParameterEncoder {
    public func encode(urlRequest: inout URLRequest, with parameters: ServiceParameters) throws {
      //Encode for JSON Content-Type
      if let contentType = urlRequest.value(forHTTPHeaderField: "Content-Type"),
        contentType == "application/json",
        let JSONData = try? JSONSerialization.data(withJSONObject: parameters, options: []) {
        urlRequest.httpBody = JSONData
      } else {
        //Default encode
        var bodyData = ""
        for (key,value) in parameters{
          let scapedKey = key.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
          let scapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)?.replacingOccurrences(of: "+", with: "%2B")
          if let scapeKeyString = scapedKey, let scapedValueString = scapedValue {
            bodyData += "\(scapeKeyString)=\(scapedValueString)" + (parameters.count == 1 ? "" : "&")
          }
        }
        urlRequest.httpBody = bodyData.data(using: .utf8, allowLossyConversion: true)
      }
      //Add form encode if URLRequest dont contains Content-Type
      if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
      }
    }
}
