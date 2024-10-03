//
//  NetworkDispatcher.swift
//  Pokedex
//
//  Created by Luis Alonso Salcido Martínez on 16/05/24.
//

import Foundation

public class NetworkDispatcher: DispatcherProtocol {
  
  // MARK: - Configuration
  private var environment: Environment
  
  // Here you can use URLSession, Alamofire, AFNetworking
  var task: URLSessionTask?
  
  // MARK: - Init
  required public init(environment: Environment) {
    self.environment = environment
  }
  
  // MARK: - Public
  func cancel() {
    self.task?.cancel()
  }
  
  //MARK: - Fetch functions
  public func fetch(uri:String? = nil,
                    request:RequestProtocol,
                    baseParams: ServiceParameters? = nil) async -> Result<Response,NetworkError> {
    let session = URLSession.shared
    if let urlRequest = self.getUrlRequest(for: uri, request: request, parameters: baseParams) {
      do {
        let result = try await session.data(for: urlRequest)
        
        guard let response = result.1 as? HTTPURLResponse,
              response.statusCode == 200 else {
          return .failure(NetworkError.errorWithDefault(.recuestFailed))
        }
      
        return .success(Response(data: result.0, request: request))
      } catch let sesionError {
        return .failure(NetworkError.errorForServiceResponse(error:sesionError))
      }
    } else {
      return .failure(NetworkError.errorWithDefault(.recuestFailed))
    }
  }
  
  //MARK: - URLRequest methods
  public func getUrlRequest(for uri:String?, request: RequestProtocol, parameters: ServiceParameters?) -> URLRequest? {
    let urlRequest = try? request.method == .get ? self.buildRequestGet(uri: uri, from: request, baseParams: parameters) : self.buildRequestPost(uri: uri, from: request, baseParams: parameters)
    return urlRequest
  }
  
  private func setupURL(request: RequestProtocol) -> URL? {
    let baseURL = environment.baseURLString()
    let url = baseURL + request.path
    return URL(string: url)
  }
  
  private func buildRequestGet(uri: String?,
                               from request: RequestProtocol,
                               baseParams: ServiceParameters? = nil) throws -> URLRequest {
    
    // Get URL
    let url: URL
    
    if let uriStr = uri, let validURL = URL(string: uriStr) {
      url = validURL
    } else if let validURL = setupURL(request: request) {
      url = validURL
    } else {
      throw NetworkError.errorWithDefault(.missingURL)
    }
    
    //Get request
    var urlRequest = URLRequest(url: url)
    
    urlRequest.httpMethod = request.method.rawValue
    
    var urlParameters: ServiceParameters? = nil
    var bodyParameters: ServiceParameters? = nil
    
    // If is get method, add base params to url parameters
    urlParameters = request.getUrlParameters(baseParameters: baseParams)
    bodyParameters = request.getBodyParameters(baseParameters: nil)
    
    //Add parameters
    do {
      try self.configureParameters(bodyParameters: bodyParameters,
                                   bodyEncoding: .urlEncoding,
                                   urlParameters: urlParameters,
                                   request: &urlRequest)
      urlRequest.allHTTPHeaderFields = request.headers
      deleteCookies()
      return urlRequest
    } catch {
      throw error
      
    }
  }
  
  private func buildRequestPost(uri: String?,
                                from request: RequestProtocol,
                                baseParams: ServiceParameters? = nil) throws -> URLRequest {
    
    // Get URL
    let url: URL
    
    if let uriStr = uri, let validURL = URL(string: uriStr) {
      url = validURL
    } else if let validURL = setupURL(request: request) {
      url = validURL
    } else {
      throw NetworkError.errorWithDefault(.missingURL)
    }
    //Get request
    var urlRequest = URLRequest(url: url)
    
    urlRequest.httpMethod = request.method.rawValue
    urlRequest.allHTTPHeaderFields = request.headers
    deleteCookies()
    
    var urlParameters: ServiceParameters? = nil
    var bodyParameters: ServiceParameters? = nil
    
    // If is get method, add base params to url parameters
    urlParameters = request.getUrlParameters(baseParameters: baseParams)
    bodyParameters = request.getBodyParameters(baseParameters: baseParams)
    
    //Add parameters
    do {
      try self.configureParameters(bodyParameters: bodyParameters,
                                   bodyEncoding: .urlAndJsonEncoding,
                                   urlParameters: urlParameters,
                                   request: &urlRequest)
      return urlRequest
    } catch {
      throw error
    }
  }
  
  private func configureParameters(bodyParameters: ServiceParameters?,
                                       bodyEncoding: ParameterEncoding,
                                       urlParameters: ServiceParameters?,
                                       request: inout URLRequest) throws {
    do {
      try bodyEncoding.encode(urlRequest: &request,
                              bodyParameters: bodyParameters, urlParameters: urlParameters)
    } catch {
      throw error
    }
  }
  
  private func deleteCookies() {
    let cookieStore = HTTPCookieStorage.shared
    cookieStore.cookies?.forEach({ (cookie) in
      cookieStore.deleteCookie(cookie)
    })
  }
}
