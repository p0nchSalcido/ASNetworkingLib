//
//  SimpleServiceProtocol.swift
//  Pokedex
//
//  Created by Luis Alonso Salcido Martínez on 16/05/24.
//

import Foundation

public protocol SimpleServiceProtocol {
  var environment: Environment { get set }
  var baseParameters: ServiceParameters? { get set }
  init(environment: Environment, baseParameters: ServiceParameters?)
}
