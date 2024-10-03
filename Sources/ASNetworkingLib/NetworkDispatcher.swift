//
//  NetworkDispatcher.swift
//  Pokedex
//
//  Created by Luis Alonso Salcido Martínez on 16/05/24.
//

import Foundation
import Combine

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
                    baseParams: ServiceParameters?,
                    completion: @escaping (Result<Response,ASNetworkError>) -> Void) {
    let session = URLSession.shared
    DispatchQueue.global(qos: .background).async {
      guard let urlRequest = self.getUrlRequest(for: uri, request: request, parameters: baseParams) else {
        completion(.failure(ASNetworkError.errorWithDefault(.requestFailed)))
        return
      }
      self.task = session.dataTask(with: urlRequest, completionHandler: self.validateTask(request: request, completion: completion))
      self.task?.resume()
    }
  }
  
  private func validateTask(request: RequestProtocol?,
                            completion:@escaping (Result<Response,ASNetworkError>) -> Void) -> ((Data?, URLResponse?, Error?) -> Void) {
    
    return { (data,response,error) in
      // Validation of task error
      if let sesionError = error {
        completion(.failure(ASNetworkError.errorForServiceResponse(error:sesionError)))
        return
      }
      //Validate of sessionResponse
      let sesionResponse = Response(data: data, request: request)
      //Send Success
      completion(.success(sesionResponse))
    }
  }
  
  //MARK: - URLRequest methods
  private func getUrlRequest(for uri:String?, request: RequestProtocol, parameters: ServiceParameters?) -> URLRequest? {
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
      throw ASNetworkError.errorWithDefault(.missingURL)
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
      throw ASNetworkError.errorWithDefault(.missingURL)
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

//MARK: - AsyncDispatcherProtocol functions
extension NetworkDispatcher: AsyncDispatcherProtocol {
  public func fetch(uri:String? = nil,
                    request:RequestProtocol,
                    baseParams: ServiceParameters? = nil) async throws -> Response {
    let session = URLSession.shared
    guard let urlRequest = self.getUrlRequest(for: uri, request: request, parameters: baseParams)  else {
      throw ASNetworkError.errorWithDefault(.missingURL)
    }
    do {
      let result = try await session.data(for: urlRequest)
      
      guard let response = result.1 as? HTTPURLResponse,
            response.statusCode == 200 else {
        throw ASNetworkError.errorWithDefault(.requestFailed)
      }
      
      return Response(data: result.0, request: request)
    } catch let sesionError {
      throw ASNetworkError.errorForServiceResponse(error:sesionError)
    }
  }
  
  public func fetchResult(uri:String? = nil,
                          request:RequestProtocol,
                          baseParams: ServiceParameters? = nil) async -> Result<Response, ASNetworkError> {
    do {
      let result = try await fetch(uri: uri, request: request, baseParams: baseParams)
      return .success(result)
    } catch let error {
      if let asError = error as? ASNetworkError {
        return .failure(asError)
      } else {
        return .failure(ASNetworkError.errorWithDefault(.requestFailed))
      }
    }
  }
}

//MARK: - PublisherDispatcherProtocol functions
extension NetworkDispatcher: PublisherDispatcherProtocol {
  public func fetchPublisher(uri:String? = nil,
                             request:RequestProtocol,
                             baseParams: ServiceParameters? = nil) -> AnyPublisher<Response, ASNetworkError> {
    let session = URLSession.shared
    guard let urlRequest = self.getUrlRequest(for: uri, request: request, parameters: baseParams) else {
      return Fail<Response, ASNetworkError>(error: ASNetworkError.errorWithDefault(.requestFailed))
        .eraseToAnyPublisher()
    }
      
    return session.dataTaskPublisher(for: urlRequest)
      .tryMap { data, response in
        guard let response = response as? HTTPURLResponse,
              response.statusCode == 200 else {
          throw ASNetworkError.errorWithDefault(.requestFailed)
        }
        return Response(data: data, request: request)
      }.mapError { error in error as? ASNetworkError ?? ASNetworkError.errorWithDefault(.requestFailed) }
      .eraseToAnyPublisher()
  }
}
