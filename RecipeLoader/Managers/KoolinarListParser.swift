//
//  KoolinarListParser.swift
//  RecipeLoader
//
//  Created by user on 19.11.2025.
//

import Foundation
import SwiftSoup

final class KoolinarListParser {
    
    static func parseRecipes(from html: String, baseURL: String) -> [Recipe] {
        do {
            let document = try SwiftSoup.parse(html)
            var recipes: [Recipe] = []
            
            let recipeElements = try document.select("div.b-item")
            print("🔍 Найдено элементов div.b-item: \(recipeElements.count)")
            
            for element in recipeElements {
                if let recipe = parseRecipeElement(element, baseURL: baseURL) {
                    recipes.append(recipe)
                }
            }
            
            return recipes
        } catch {
            print("❌ Ошибка парсинга списка Koolinar: \(error)")
            return []
        }
    }
    
    private static func parseRecipeElement(_ element: Element, baseURL: String) -> Recipe? {
        // Заголовок и ссылка
        guard let titleLink = try? element.select("a.b-item__main").first(),
              let titleElement = try? element.select("span.b-item__title").first(),
              let title = try? titleElement.text(),
              let href = try? titleLink.attr("href"),
              !title.isEmpty else {
            return nil
        }
        
        // Изображение
        let imageUrl = parseImageUrl(from: element, baseURL: baseURL)
        
        // Описание
        let description = parseDescription(from: element)
        
        // Дата добавления
        let addedDate = parseAddedDate(from: element)
        
        let fullUrl = href.hasPrefix("http") ? href : "\(baseURL)\(href)"
        
        return Recipe(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            source: "Koolinar.ru",
            url: fullUrl,
            imageUrl: imageUrl,
            description: description,
            categories: [],
            tags: [],
            cookingTime: nil,
            servings: nil,
            addedDate: addedDate
        )
    }
    
    private static func parseImageUrl(from element: Element, baseURL: String) -> String? {
        guard let imageElement = try? element.select("a.b-item__main img").first(),
              let imageSrc = try? imageElement.attr("src"),
              !imageSrc.isEmpty else { return nil }
        
        return imageSrc.hasPrefix("http") ? imageSrc : "\(baseURL)\(imageSrc)"
    }
    
    private static func parseDescription(from element: Element) -> String? {
        if let descriptionElement = try? element.select("div.b-item__description").first(),
           let description = try? descriptionElement.text(),
           !description.isEmpty {
            return description.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    
    private static func parseAddedDate(from element: Element) -> String? {
        if let dateElement = try? element.select(".date-font").first(),
           let dateText = try? dateElement.text(),
           !dateText.isEmpty {
            return formatKoolinarDate(dateText)
        }
        return nil
    }
    
    private static func formatKoolinarDate(_ dateString: String) -> String {
        let cleaned = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let commaRange = cleaned.range(of: ",") {
            return String(cleaned[..<commaRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleaned
    }
}
