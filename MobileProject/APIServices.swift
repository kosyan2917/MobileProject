//
//  APIServices.swift
//  MobileProject
//
//  Created by Никита Косянков on 05.02.2025.
//

import Foundation

enum APIErrors: Error {
    case NoData
    case IncorrectLoginData
    case ServerError
    case BadURL
    case BadServerResponse
}

protocol APIService {
    var base_url: String { get }
    
    func getFiles(token: String) async throws -> Data
    func login(username: String, password: String) async throws -> Data
    func getGPX(token: String, filename: String) async throws -> Data
}

class MockAPIService: APIService {
    let base_token: String = "123456789qwerty"
    func getFiles(token: String) async throws -> Data {
        let gpxFiles = Bundle.main.paths(forResourcesOfType: "gpx", inDirectory: nil)
        let fileNames = gpxFiles.map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent }
        let filesStruct = Files(files: fileNames)
        if let jsonData = try? JSONEncoder().encode(filesStruct) {
            return jsonData
        } else {
            throw APIErrors.NoData
        }
    }
    
    func login(username: String, password: String) async throws -> Data {
        let tokenData: Data
        let tokenStruct: loginResponse = loginResponse(token: base_token)
        if let jsonData = try? JSONEncoder().encode(tokenStruct) {
            tokenData = jsonData
        } else {
            throw APIErrors.NoData
        }
        if username == "test" && password == "test" {
            return tokenData
        } else {
            throw APIErrors.IncorrectLoginData
        }
    }
    
    func getGPX(token: String, filename: String) async throws -> Data {
        if token != base_token {
            throw APIErrors.IncorrectLoginData
        }
        guard let filePath = Bundle.main.path(forResource: filename, ofType: "gpx") else {throw APIErrors.NoData}
        guard let data = FileManager.default.contents(atPath: filePath) else {
            throw APIErrors.NoData
        }
        return data
    }
    
    internal let base_url: String = ""
    
}


class RealAPIService: APIService {
    internal var base_url: String = "http://127.0.0.1:1337/api/"
    
    func makeAPICall(request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    throw APIErrors.BadServerResponse
                }
            }
            return data
        } catch {
            print("\(error)")
            throw APIErrors.ServerError
        }
    }
    
    func getFiles(token: String) async throws -> Data {
        let url = base_url + "files"
        guard let url = URL(string: url) else { throw APIErrors.BadURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        return try await makeAPICall(request: request)
        
    }
    
    func login(username: String, password: String) async throws -> Data {
        let url = base_url + "auth"
        guard let url = URL(string: url) else { throw APIErrors.BadURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "username=\(username)&password=\(password)"
        request.httpBody = body.data(using: .utf8)
        return try await makeAPICall(request: request)
    }
    
    func getGPX(token: String, filename: String) async throws -> Data {
        let url = base_url + "files/\(filename)"
        guard let url = URL(string: url) else { throw  APIErrors.BadURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        return try await makeAPICall(request: request)
        

    }
}

struct loginResponse: Codable {
    var token: String
}

struct Files: Codable {
    var files: [String]
}

let apiService = MockAPIService()
