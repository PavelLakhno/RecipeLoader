//
//  NetworkManager.swift
//  RecipeLoader
//
//  Created by user on 17.11.2025.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        session = URLSession(configuration: configuration)
    }
    
    func fetchHTML(from urlString: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15",
                        forHTTPHeaderField: "User-Agent")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            // Пробуем разные кодировки
            let encodings: [String.Encoding] = [.windowsCP1251, .utf8, .isoLatin1]
            
            for encoding in encodings {
                if let html = String(data: data, encoding: encoding) {
                    completion(.success(html))
                    return
                }
            }
            
            completion(.failure(NetworkError.encodingFailed))
        }
        task.resume()
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Неверный URL"
        case .noData: return "Нет данных в ответе"
        case .encodingFailed: return "Не удалось декодировать HTML"
        }
    }
}
