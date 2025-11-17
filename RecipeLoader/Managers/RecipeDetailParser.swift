//
//  RecipeDetailParser.swift
//  RecipeLoader
//
//  Created by user on 13.11.2025.
//

import Foundation
import SwiftSoup

final class RecipeDetailParser {
    
    static func parseDetailedRecipe(from html: String, url: String) -> Recipe? {
        do {
            let document = try SwiftSoup.parse(html)
            
            let recipeId = extractRecipeId(from: url)
            let title = parseTitle(from: document)
            let description = parseDescription(from: document)
            let mainImage = parseMainImage(from: document)
            let categories = parseCategories(from: document)
            let cuisine = parseCuisine(from: document)
            let ingredients = parseIngredients(from: document)
            let (cookingTime, servings) = parseTimeAndServings(from: document)
            let nutrition = parseNutrition(from: document)
            let instructions = parseInstructions(from: document)
            let tags = parseTags(from: document)
            let addedDate = parseAddedDate(from: document)
            
            return Recipe(
                id: recipeId,
                title: title,
                source: "Povarenok.ru",
                url: url,
                imageUrl: mainImage,
                description: description,
                categories: categories,
                ingredients: ingredients,
                nutrition: nutrition,
                instructions: instructions,
                tags: tags,
                cookingTime: cookingTime,
                servings: servings,
                cuisine: cuisine,
                addedDate: addedDate
            )
            
        } catch {
            print("❌ Ошибка парсинга детального рецепта: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private static func extractRecipeId(from url: String) -> String {
        if let range = url.range(of: "/recipes/show/(\\d+)/", options: .regularExpression) {
            return String(url[range])
        }
        return UUID().uuidString
    }
    
    private static func parseTitle(from document: Document) -> String {
        (try? document.select("h1[itemprop=name]").text()) ?? ""
    }
    
    private static func parseDescription(from document: Document) -> String {
        (try? document.select("div.article-text[itemprop=description] p").text()) ?? ""
    }
    
    private static func parseMainImage(from document: Document) -> String? {
        guard let imageSrc = try? document.select("img[itemprop=image]").first()?.attr("src"),
              !imageSrc.isEmpty else { return nil }
        
        return imageSrc.hasPrefix("http") ? imageSrc : "https:\(imageSrc)"
    }
    
    private static func parseCategories(from document: Document) -> [String] {
        guard let categoryElements = try? document.select("span[itemprop=recipeCategory] a") else { return [] }
        return categoryElements.compactMap { try? $0.text() }.filter { !$0.isEmpty }
    }
    
    private static func parseCuisine(from document: Document) -> String? {
        guard let cuisineElement = try? document.select("span[itemprop=recipeCuisine] a").first(),
              let cuisine = try? cuisineElement.text(),
              !cuisine.isEmpty else { return nil }
        return cuisine
    }
    
    private static func parseIngredients(from document: Document) -> [Ingredient] {
        guard let ingredientElements = try? document.select("li[itemprop=recipeIngredient]") else { return [] }
        
        return ingredientElements.compactMap { element in
            guard let name = try? element.select("a span").text(),
                  !name.isEmpty else { return nil }
            
            let amount = (try? element.select("span").last()?.text()) ?? ""
            let ingredientUrl = (try? element.select("a").attr("href")) ?? ""
            
            let fullUrl = ingredientUrl.hasPrefix("http") ? ingredientUrl : "https://www.povarenok.ru\(ingredientUrl)"
            
            return Ingredient(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: amount.trimmingCharacters(in: .whitespacesAndNewlines),
                url: fullUrl.isEmpty ? nil : fullUrl
            )
        }
    }
    
    private static func parseTimeAndServings(from document: Document) -> (String?, String?) {
        let cookingTime = parseCookingTime(from: document)
        let servings = parseServings(from: document)
        return (cookingTime, servings)
    }
    
    private static func parseCookingTime(from document: Document) -> String? {
        let timeSelectors = [
            "time[itemprop=totalTime]",
            "time[datetime]",
            "[itemprop=totalTime]",
            ".cooking-time",
            ".recipe-time"
        ]
        
        // Поиск через селекторы
        for selector in timeSelectors {
            if let timeElement = try? document.select(selector).first(),
               let timeText = try? timeElement.text(),
               !timeText.isEmpty,
               let formattedTime = formatCookingTime(timeText) {
                return formattedTime
            }
        }
        
        // Поиск в тексте документа
        guard let documentText = try? document.text() else { return nil }
        
        let timePatterns = [
            "Время приготовления:\\s*([^\\n]+)",
            "Готовится:\\s*([^\\n]+)",
            "Приготовление:\\s*([^\\n]+)",
            "\\b(\\d+\\s*(?:мин|минут|час|часа))\\b"
        ]
        
        for pattern in timePatterns {
            if let range = documentText.range(of: pattern, options: .regularExpression) {
                let match = String(documentText[range])
                if let formattedTime = formatCookingTime(match) {
                    return formattedTime
                }
            }
        }
        
        return nil
    }
    
    private static func parseServings(from document: Document) -> String? {
        let servingsSelectors = [
            "span[itemprop=recipeYield]",
            "[itemprop=recipeYield]",
            ".servings",
            ".recipe-yield"
        ]
        
        // Поиск через селекторы
        for selector in servingsSelectors {
            if let servingsElement = try? document.select(selector).first(),
               let servingsText = try? servingsElement.text(),
               !servingsText.isEmpty,
               let formattedServings = formatServings(servingsText) {
                return formattedServings
            }
        }
        
        // Поиск в тексте документа
        guard let documentText = try? document.text() else { return nil }
        
        let servingsPatterns = [
            "Количество порций:\\s*([^\\n]+)",
            "Порций:\\s*([^\\n]+)",
            "На\\s+(\\d+\\s*(?:порц|порции|порций|чел|персон))",
            "\\b(\\d+\\s*(?:порц|порции|порций))\\b"
        ]
        
        for pattern in servingsPatterns {
            if let range = documentText.range(of: pattern, options: .regularExpression) {
                let match = String(documentText[range])
                if let formattedServings = formatServings(match) {
                    return formattedServings
                }
            }
        }
        
        return nil
    }
    
    private static func parseNutrition(from document: Document) -> NutritionInfo? {
        guard let nutritionElement = try? document.select("div[itemprop=nutrition]").first() else {
            return nil
        }
        
        let calories = (try? nutritionElement.select("strong[itemprop=calories]").text()) ?? ""
        let protein = (try? nutritionElement.select("strong[itemprop=proteinContent]").text()) ?? ""
        let fat = (try? nutritionElement.select("strong[itemprop=fatContent]").text()) ?? ""
        let carbohydrates = (try? nutritionElement.select("strong[itemprop=carbohydrateContent]").text()) ?? ""
        
        // Получаем значения на 100г
        let (caloriesPer100g, proteinPer100g, fatPer100g, carbohydratesPer100g) = parseNutritionPer100g(from: nutritionElement)
        
        return NutritionInfo(
            calories: calories,
            protein: protein,
            fat: fat,
            carbohydrates: carbohydrates,
            caloriesPer100g: caloriesPer100g,
            proteinPer100g: proteinPer100g,
            fatPer100g: fatPer100g,
            carbohydratesPer100g: carbohydratesPer100g
        )
    }
    
    private static func parseNutritionPer100g(from nutritionElement: Element) -> (String, String, String, String) {
        guard let nutritionRows = try? nutritionElement.select("tr") else {
            return ("", "", "", "")
        }
        
        var nutritionPer100g: [String] = []
        
        for row in nutritionRows {
            guard let cells = try? row.select("td") else { continue }
            
            for cell in cells {
                if let strong = try? cell.select("strong").text(), !strong.isEmpty {
                    nutritionPer100g.append(strong)
                }
            }
        }
        
        let caloriesPer100g = nutritionPer100g.count > 0 ? nutritionPer100g[0] : ""
        let proteinPer100g = nutritionPer100g.count > 1 ? nutritionPer100g[1] : ""
        let fatPer100g = nutritionPer100g.count > 2 ? nutritionPer100g[2] : ""
        let carbohydratesPer100g = nutritionPer100g.count > 3 ? nutritionPer100g[3] : ""
        
        return (caloriesPer100g, proteinPer100g, fatPer100g, carbohydratesPer100g)
    }
    
    private static func parseInstructions(from document: Document) -> [InstructionStep] {
        let stepSelectors = [
            "li.cooking-bl",
            "li[itemprop=recipeInstructions]",
            ".cooking-steps li",
            ".recipe-steps li"
        ]
        
        for selector in stepSelectors {
            guard let stepElements = try? document.select(selector),
                  !stepElements.isEmpty else { continue }
            
            let steps = stepElements.enumerated().compactMap { index, element -> InstructionStep? in
                guard let stepText = try? element.select("div p, .step-text, .instruction-text").text(),
                      !stepText.isEmpty else { return nil }
                
                let stepImage = (try? element.select("img").attr("src")) ?? ""
                let fullImageUrl = stepImage.isEmpty ? nil : (stepImage.hasPrefix("http") ? stepImage : "https:\(stepImage)")
                
                return InstructionStep(
                    stepNumber: index + 1,
                    text: stepText.trimmingCharacters(in: .whitespacesAndNewlines),
                    imageUrl: fullImageUrl
                )
            }
            
            if !steps.isEmpty {
                return steps
            }
        }
        
        return []
    }
    
    private static func parseTags(from document: Document) -> [String] {
        guard let tagElements = try? document.select("div.article-tags a") else { return [] }
        return tagElements.compactMap { try? $0.text() }.filter { !$0.isEmpty }
    }
    
    private static func parseAddedDate(from document: Document) -> String? {
        let dateSelectors = [
            ".article-footer .i-time",
            ".recipe-date",
            ".date-added",
            "[itemprop=datePublished]",
            "time[datetime]",
            ".i-time"
        ]
        
        // Поиск через селекторы
        for selector in dateSelectors {
            if let dateElement = try? document.select(selector).first(),
               let dateText = try? dateElement.text(),
               !dateText.isEmpty,
               let formattedDate = formatDetailDate(dateText) {
                return formattedDate
            }
        }
        
        // Поиск в тексте
        guard let documentText = try? document.text() else { return nil }
        
        let datePatterns = [
            "Добавлено:\\s*([^\\n]+)",
            "Опубликовано:\\s*([^\\n]+)",
            "Создано:\\s*([^\\n]+)",
            "\\d{1,2}\\s+[а-я]+\\s+\\d{4}",
            "\\d{2}\\.\\d{2}\\.\\d{4}"
        ]
        
        for pattern in datePatterns {
            if let range = documentText.range(of: pattern, options: .regularExpression) {
                let match = String(documentText[range])
                if let formattedDate = formatDetailDate(match) {
                    return formattedDate
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Formatting Methods
    
    private static func formatCookingTime(_ time: String) -> String? {
        let cleaned = time.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        
        // Форматируем PT40M -> 40 мин
        if cleaned.hasPrefix("PT") {
            let timeString = cleaned.replacingOccurrences(of: "PT", with: "")
            if let minutesRange = timeString.range(of: "\\d+", options: .regularExpression) {
                let minutes = String(timeString[minutesRange])
                return "\(minutes) мин"
            }
        }
        
        // Убираем лишний текст
        let patternsToRemove = [
            "Время приготовления:",
            "Готовится:",
            "Приготовление:",
            "время",
            "приготовления"
        ]
        
        var formatted = cleaned
        for pattern in patternsToRemove {
            formatted = formatted.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func formatServings(_ servings: String) -> String? {
        let cleaned = servings.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        
        // Извлекаем только цифры и базовые единицы
        if let numberRange = cleaned.range(of: "\\d+", options: .regularExpression) {
            let number = String(cleaned[numberRange])
            
            // Определяем единицы измерения
            if cleaned.contains("порц") || cleaned.contains("serving") {
                return "\(number) порц"
            } else if cleaned.contains("чел") || cleaned.contains("персон") {
                return "\(number) чел"
            } else {
                return "\(number) порц"
            }
        }
        
        // Убираем лишний текст
        let patternsToRemove = [
            "Количество порций:",
            "Порций:",
            "На",
            "порций",
            "порции"
        ]
        
        var formatted = cleaned
        for pattern in patternsToRemove {
            formatted = formatted.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func formatDetailDate(_ dateString: String) -> String? {
        let cleaned = dateString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Убираем префиксы
        let prefixesToRemove = ["добавлено:", "опубликовано:", "создано:", "date:"]
        var formatted = cleaned
        
        for prefix in prefixesToRemove {
            formatted = formatted.replacingOccurrences(of: prefix, with: "", options: .caseInsensitive)
        }
        
        formatted = formatted.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !formatted.isEmpty else { return nil }
        
        // Приводим к формату как в списке рецептов
        if formatted.contains("сегодня") || formatted.contains("today") {
            return "сегодня"
        } else if formatted.contains("вчера") || formatted.contains("yesterday") {
            return "вчера"
        } else if formatted.contains("позавчера") {
            return "2 дня назад"
        }
        
        // Пробуем распарсить относительные даты
        if let relativeDate = parseRelativeDate(formatted) {
            return relativeDate
        }
        
        return String(formatted.prefix(20))
    }
    
    private static func parseRelativeDate(_ dateString: String) -> String? {
        let patterns = [
            (pattern: "(\\d+)\\s*дн", replacement: "$1 дней назад"),
            (pattern: "(\\d+)\\s*недел", replacement: "$1 недель назад"),
            (pattern: "(\\d+)\\s*месяц", replacement: "$1 месяцев назад"),
            (pattern: "(\\d+)\\s*год", replacement: "$1 лет назад")
        ]
        
        for (pattern, replacement) in patterns {
            if let range = dateString.range(of: pattern, options: .regularExpression) {
                let number = String(dateString[range])
                    .replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
                return replacement.replacingOccurrences(of: "$1", with: number)
            }
        }
        
        return nil
    }
}
