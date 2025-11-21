//
//  GastronomListParser.swift
//  RecipeLoader
//
//  Created by user on 20.11.2025.
//

import Foundation
import SwiftSoup

final class GastronomListParser {
    
    static func parseRecipes(from html: String, baseURL: String) -> [Recipe] {
        do {
            let document = try SwiftSoup.parse(html)
            
            // Ищем JSON данные в script теге
            guard let scriptElement = try? document.select("script#vite-plugin-ssr_pageContext").first(),
                  let jsonString = try? scriptElement.html() else {
                print("❌ Не найден JSON скрипт на странице Gastronom")
                return []
            }
            
            // Парсим JSON напрямую в словари
            guard let jsonData = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let pageProps = json["pageProps"] as? [String: Any],
                  let pagesBySearch = pageProps["pagesBySearch"] as? [String: Any],
                  let results = pagesBySearch["results"] as? [[String: Any]] else {
                print("❌ Ошибка парсинга JSON структуры Gastronom")
                return []
            }
            
            print("🔍 Найдено рецептов в JSON: \(results.count)")
            
            return results.compactMap { result in
                parseRecipeFromJSON(result, baseURL: baseURL)
            }
            
        } catch {
            print("❌ Ошибка парсинга списка Gastronom: \(error)")
            return []
        }
    }
    
    private static func parseRecipeFromJSON(_ result: [String: Any], baseURL: String) -> Recipe? {
        // Извлекаем только нужные данные напрямую
        guard let name = result["name"] as? String,
              let previewContent = result["previewContent"] as? [String: Any],
              let link = previewContent["link"] as? String else {
            return nil
        }
        
        let fullUrl = link.hasPrefix("http") ? link : "\(baseURL)\(link)"
        
        // Извлекаем опциональные поля
        let imageUrl = previewContent["image"] as? String
        let description = previewContent["description"] as? String
        let publishedAt = result["publishedAt"] as? String
        
        // Время приготовления
        let cookingTime: String?
        if let typeSpecificData = previewContent["typeSpecificData"] as? [String: Any],
           let time = typeSpecificData["cookingTime"] as? Int {
            cookingTime = "\(time) мин"
        } else {
            cookingTime = nil
        }
        
        // Дата добавления
        let addedDate = formatGastronomDate(publishedAt)
        
        return Recipe(
            title: name.trimmingCharacters(in: .whitespacesAndNewlines),
            source: "Gastronom.ru",
            url: fullUrl,
            imageUrl: imageUrl,
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines),
            categories: [],
            tags: [],
            cookingTime: cookingTime,
            servings: nil,
            addedDate: addedDate
        )
    }
    
    private static func formatGastronomDate(_ dateString: String?) -> String? {
        guard let dateString = dateString else { return nil }
        
        let dateFormatter = ISO8601DateFormatter()
        guard let date = dateFormatter.date(from: dateString) else { return nil }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd.MM.yyyy"
        outputFormatter.locale = Locale(identifier: "ru_RU")
        
        return outputFormatter.string(from: date)
    }
}
