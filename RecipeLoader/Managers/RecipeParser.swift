//
//  RecipeParser.swift
//  RecipeLoader
//
//  Created by user on 17.11.2025.
//

import Foundation
import SwiftSoup

final class RecipeParser {
    
    static func parseRecipes(from html: String, baseURL: String) -> [Recipe] {
        do {
            let document = try SwiftSoup.parse(html)
            let recipeElements = try document.select("article.item-bl")
            var recipes: [Recipe] = []
            
            for element in recipeElements {
                if let recipe = parseRecipeElement(element, baseURL: baseURL) {
                    recipes.append(recipe)
                }
            }
            
            return recipes
        } catch {
            print("❌ Ошибка парсинга: \(error)")
            return []
        }
    }
    
    private static func parseRecipeElement(_ element: Element, baseURL: String) -> Recipe? {
        guard let titleLink = try? element.select("h2 a").first(),
              let title = try? titleLink.text(),
              let href = try? titleLink.attr("href"),
              !title.isEmpty else { return nil }
        
        let imageUrl = parseImageUrl(from: element)
        let description = parseDescription(from: element)
        let categories = parseCategories(from: element)
        let tags = parseTags(from: element)
        let (cookingTime, servings) = parseTimeAndServings(from: element)
        let addedDate = parseAddedDate(from: element)
        
        let fullUrl = href.hasPrefix("http") ? href : "\(baseURL)\(href)"
        
        return Recipe(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            source: "Povarenok.ru",
            url: fullUrl,
            imageUrl: imageUrl,
            description: description,
            categories: categories,
            tags: tags,
            cookingTime: cookingTime,
            servings: servings,
            addedDate: addedDate
        )
    }
    
    private static func parseImageUrl(from element: Element) -> String? {
        guard let imageElement = try? element.select(".m-img img").first(),
              let imageSrc = try? imageElement.attr("src"),
              !imageSrc.isEmpty else { return nil }
        
        return imageSrc.hasPrefix("http") ? imageSrc : "https:\(imageSrc)"
    }
    
    private static func parseDescription(from element: Element) -> String? {
        // Стратегия 1: Ищем параграф после article-breadcrumbs
        if let breadcrumbs = try? element.select(".article-breadcrumbs").first(),
           let nextParagraph = try? breadcrumbs.nextElementSibling(),
           nextParagraph.tagName() == "p" {
            let description = try? nextParagraph.text()
            if let description = description, !description.isEmpty && description.count > 20 {
                return description.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Стратегия 2: Ищем любой параграф в элементе, но исключаем теги и категории
        guard let paragraphs = try? element.select("p") else { return nil }
        
        for paragraph in paragraphs {
            guard let text = try? paragraph.text().trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty,
                  text.count > 20,
                  text.count < 300,
                  !text.lowercased().contains("категория:"),
                  !text.lowercased().contains("ингредиенты:"),
                  !text.lowercased().contains("теги:"),
                  !text.lowercased().contains("назначение:") else { continue }
            
            return text
        }
        
        return nil
    }
    
    private static func parseCategories(from element: Element) -> [String] {
        guard let categoryLinks = try? element.select(".article-breadcrumbs a") else { return [] }
        return categoryLinks.compactMap {
            try? $0.text().trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
    }
    
    private static func parseTags(from element: Element) -> [String] {
        guard let tagElements = try? element.select(".article-tags .tab-content a") else { return [] }
        return tagElements.compactMap {
            try? $0.text().trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
    }
    
    private static func parseTimeAndServings(from element: Element) -> (String?, String?) {
        var cookingTime: String?
        var servings: String?
        
        // Стратегия 1: Ищем в тексте элемента
        guard let elementText = try? element.text() else {
            return (nil, nil)
        }
        
        // Время приготовления
        let timePatterns = [
            "\\d+\\s*мин",           // 40 мин
            "\\d+\\s*минут",         // 40 минут
            "\\d+\\s*час",           // 1 час
            "\\d+\\s*часа",          // 2 часа
            "PT\\w+",                // PT40M (формат времени)
            "\\d+\\s*-\\s*\\d+\\s*мин" // 30-40 мин
        ]
        
        for pattern in timePatterns {
            if let timeRange = elementText.range(of: pattern, options: .regularExpression) {
                cookingTime = String(elementText[timeRange])
                break
            }
        }
        
        // Количество порций
        let servingsPatterns = [
            "\\d+\\s*порц",          // 4 порц
            "\\d+\\s*порции",        // 4 порции
            "\\d+\\s*порций",        // 4 порций
            "\\d+\\s*servings",      // 4 servings
            "\\d+\\s*чел",           // 4 чел
            "\\d+\\s*персоны"        // 4 персоны
        ]
        
        for pattern in servingsPatterns {
            if let servingsRange = elementText.range(of: pattern, options: .regularExpression) {
                servings = String(elementText[servingsRange])
                break
            }
        }
        
        // Стратегия 2: Ищем в структурированных данных
        if cookingTime == nil {
            if let timeElement = try? element.select("time[datetime]").first() {
                cookingTime = try? timeElement.text()
            }
        }
        
        if servings == nil {
            if let servingsElement = try? element.select("[itemprop=recipeYield]").first() {
                servings = try? servingsElement.text()
            }
        }
        
        // Очистка и форматирование
        cookingTime = cookingTime?
            .replacingOccurrences(of: "PT", with: "")
            .replacingOccurrences(of: "M", with: " мин")
            .replacingOccurrences(of: "H", with: " час")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        servings = servings?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (cookingTime, servings)
    }
    
    private static func parseAddedDate(from element: Element) -> String? {
        let timeSelectors = [
            ".i-time",
            ".article-footer .i-time",
            ".time",
            ".date",
            "time",
            "[datetime]"
        ]
        
        for selector in timeSelectors {
            if let timeElement = try? element.select(selector).first(),
               let timeText = try? timeElement.text(),
               !timeText.isEmpty {
                return formatAddedDate(timeText)
            }
        }
        
        // Также проверяем атрибут datetime
        if let timeElement = try? element.select("time").first(),
           let datetime = try? timeElement.attr("datetime"),
           !datetime.isEmpty {
            return formatAddedDate(datetime)
        }
        
        return nil
    }
    
    private static func formatAddedDate(_ dateString: String) -> String {
        let cleaned = dateString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Приводим к единому формату
        if cleaned.contains("сегодня") {
            return "сегодня"
        } else if cleaned.contains("вчера") {
            return "вчера"
        } else if cleaned.contains("позавчера") {
            return "2 дня назад"
        } else if let daysMatch = cleaned.range(of: "\\d+\\s*дн", options: .regularExpression) {
            let days = String(cleaned[daysMatch])
                .replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
            return "\(days) дней назад"
        } else if let weeksMatch = cleaned.range(of: "\\d+\\s*недел", options: .regularExpression) {
            let weeks = String(cleaned[weeksMatch])
                .replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
            return "\(weeks) недель назад"
        }
        
        return cleaned
    }
}
