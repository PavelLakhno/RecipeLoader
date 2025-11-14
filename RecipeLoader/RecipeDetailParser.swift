//
//  RecipeDetailParser.swift
//  RecipeLoader
//
//  Created by user on 13.11.2025.
//

import SwiftSoup
import UIKit

class RecipeDetailParser {
    
//    static func parseDetailedRecipe(from html: String, url: String) -> Recipe? {
//        do {
//            let document = try SwiftSoup.parse(html)
//            
//            // Извлекаем ID из URL
//            let recipeId = extractRecipeId(from: url)
//            
//            // Основная информация
//            let title = try document.select("h1[itemprop=name]").text()
//            let description = try document.select("div.article-text[itemprop=description] p").text()
//            
//            // Главное изображение
//            let mainImage = try document.select("img[itemprop=image]").first()?.attr("src")
//            
//            // Категории
//            let categories = try extractCategories(from: document)
//            
//            // Ингредиенты
//            let ingredients = try extractIngredients(from: document)
//            
//            // Пищевая ценность
//            let nutrition = try extractNutrition(from: document)
//            
//            // Шаги приготовления
//            let instructions = try extractInstructions(from: document)
//            
//            // Теги
//            let tags = try extractTags(from: document)
//            
//            return Recipe(
//                id: recipeId,
//                title: title,
//                source: "Povarenok.ru",
//                url: url,
//                imageUrl: mainImage,
//                description: description,
//                categories: categories,
//                ingredients: ingredients,
//                nutrition: nutrition,
//                instructions: instructions,
//                tags: tags,
//                cookingTime: nil, // Можно извлечь при наличии
//                servings: nil     // Можно извлечь при наличии
//            )
//            
//        } catch {
//            print("❌ Ошибка парсинга детального рецепта: \(error)")
//            return nil
//        }
//    }
    
    private static func extractRecipeId(from url: String) -> String {
        // Извлекаем ID из URL типа: /recipes/show/168450/
        if let range = url.range(of: "/recipes/show/(\\d+)/", options: .regularExpression) {
            return String(url[range])
        }
        return UUID().uuidString
    }
    
    private static func extractCategories(from document: Document) throws -> [String] {
        let categoryElements = try document.select("span[itemprop=recipeCategory] a")
        return try categoryElements.map { try $0.text() }
    }
    
    private static func extractIngredients(from document: Document) throws -> [Ingredient] {
        var ingredients: [Ingredient] = []
        
        let ingredientElements = try document.select("li[itemprop=recipeIngredient]")
        
        for element in ingredientElements {
            let name = try element.select("a span").text()
            let amount = try element.select("span").last()?.text() ?? ""
            let ingredientUrl = try element.select("a").attr("href")
            let fullUrl = ingredientUrl.hasPrefix("http") ? ingredientUrl : "https://www.povarenok.ru\(ingredientUrl)"
            
            if !name.isEmpty {
                let ingredient = Ingredient(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    amount: amount.trimmingCharacters(in: .whitespacesAndNewlines),
                    url: fullUrl.isEmpty ? nil : fullUrl
                )
                ingredients.append(ingredient)
            }
        }
         
        return ingredients
    }
    
    private static func extractNutrition(from document: Document) throws -> NutritionInfo? {
        guard let nutritionElement = try document.select("div[itemprop=nutrition]").first() else {
            return nil
        }
        
        let calories = try nutritionElement.select("strong[itemprop=calories]").text()
        let protein = try nutritionElement.select("strong[itemprop=proteinContent]").text()
        let fat = try nutritionElement.select("strong[itemprop=fatContent]").text()
        let carbohydrates = try nutritionElement.select("strong[itemprop=carbohydrateContent]").text()
        
        // Для значений на 100г (они в следующей таблице)
        let nutritionRows = try nutritionElement.select("tr")
        var nutritionPer100g = [String]()
        
        for row in nutritionRows {
            let cells = try row.select("td")
            if cells.count >= 4 {
                for cell in cells {
                    if let strong = try? cell.select("strong").text(), !strong.isEmpty {
                        nutritionPer100g.append(strong)
                    }
                }
            }
        }
        
        // Предполагаем, что значения на 100г идут после значений для всего блюда
        let caloriesPer100g = nutritionPer100g.count > 0 ? nutritionPer100g[0] : ""
        let proteinPer100g = nutritionPer100g.count > 1 ? nutritionPer100g[1] : ""
        let fatPer100g = nutritionPer100g.count > 2 ? nutritionPer100g[2] : ""
        let carbohydratesPer100g = nutritionPer100g.count > 3 ? nutritionPer100g[3] : ""
        
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

    private static func extractInstructions(from document: Document) throws -> [InstructionStep] {
        var steps: [InstructionStep] = []
        
        // Пробуем разные селекторы для шагов приготовления
        let stepSelectors = [
            "li.cooking-bl",
            "li[itemprop=recipeInstructions]",
            ".cooking-steps li",
            ".recipe-steps li"
        ]
        
        for selector in stepSelectors {
            let stepElements = try document.select(selector)
            print("🔍 Найдено шагов с селектором '\(selector)': \(stepElements.count)")
            
            if !stepElements.isEmpty {
                for (index, element) in stepElements.enumerated() {
                    let stepText = try element.select("div p, .step-text, .instruction-text").text()
                    let stepImage = try element.select("img").attr("src")
                    
                    if !stepText.isEmpty {
                        let fullImageUrl = stepImage.isEmpty ? nil : (stepImage.hasPrefix("http") ? stepImage : "https:\(stepImage)")
                        
                        let step = InstructionStep(
                            stepNumber: index + 1,
                            text: stepText.trimmingCharacters(in: .whitespacesAndNewlines),
                            imageUrl: fullImageUrl
                        )
                        steps.append(step)
                        print("✅ Шаг \(index + 1): \(String(stepText.prefix(50)))...")
                    }
                }
                break // Используем первый работающий селектор
            }
        }
        
        return steps
    }
    
    private static func extractTags(from document: Document) throws -> [String] {
        let tagElements = try document.select("div.article-tags a")
        return try tagElements.map { try $0.text() }
    }
}

extension RecipeDetailParser {
    
    static func parseDetailedRecipe(from html: String, url: String) -> Recipe? {
        do {
            let document = try SwiftSoup.parse(html)
            
            // Извлекаем ID из URL
            let recipeId = extractRecipeId(from: url)
            
            // Основная информация
            let title = try document.select("h1[itemprop=name]").text()
            let description = try document.select("div.article-text[itemprop=description] p").text()
            
            // Главное изображение
            let mainImage = try document.select("img[itemprop=image]").first()?.attr("src")
            
            // Категории
            let categories = try extractCategories(from: document)
            
            // Кухня
            let cuisine = try extractCuisine(from: document)
            
            // Ингредиенты
            let ingredients = try extractIngredients(from: document)
            
            // Время и порции
            let (cookingTime, servings) = try extractTimeAndServings(from: document)
            print("🕒 Время приготовления: \(cookingTime ?? "не найдено")")
            print("🍽 Порций: \(servings ?? "не найдено")")
            print("🏺 Кухня: \(cuisine ?? "не указана")")
            
            // Пищевая ценность
            let nutrition = try extractNutrition(from: document)
            
            // Шаги приготовления
            let instructions = try extractInstructions(from: document)
            
            // Теги
            let tags = try extractTags(from: document)
            
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
                cuisine: cuisine
            )
            
        } catch {
            print("❌ Ошибка парсинга детального рецепта: \(error)")
            return nil
        }
    }
    
    private static func extractCuisine(from document: Document) throws -> String? {
        let cuisineElement = try document.select("span[itemprop=recipeCuisine] a").first()
        return try cuisineElement?.text()
    }
    
//    private static func extractTimeAndServings(from document: Document) throws -> (String?, String?) {
//        var cookingTime: String?
//        var servings: String?
//        
//        // Время приготовления
//        if let timeElement = try document.select("time[itemprop=totalTime]").first() {
//            cookingTime = try timeElement.text()
//        }
//        
//        // Количество порций
//        if let servingsElement = try document.select("span[itemprop=recipeYield]").first() {
//            servings = try servingsElement.text()
//        }
//        
//        return (cookingTime, servings)
//    }
    private static func extractTimeAndServings(from document: Document) throws -> (String?, String?) {
        var cookingTime: String?
        var servings: String?
        
        // Время приготовления - несколько стратегий
        let timeSelectors = [
            "time[itemprop=totalTime]",
            "time[datetime]",
            "[itemprop=totalTime]",
            ".cooking-time",
            ".recipe-time"
        ]
        
        for selector in timeSelectors {
            if let timeElement = try? document.select(selector).first(),
               let timeText = try? timeElement.text(),
               !timeText.isEmpty {
                
                // Форматируем время
                cookingTime = formatCookingTime(timeText)
                if cookingTime != nil { break }
            }
        }
        
        // Если не нашли через селекторы, ищем в тексте
        if cookingTime == nil {
            let documentText = try document.text()
            let timePatterns = [
                "Время приготовления:\\s*([^\\n]+)",
                "Готовится:\\s*([^\\n]+)",
                "Приготовление:\\s*([^\\n]+)",
                "\\b(\\d+\\s*(?:мин|минут|час|часа))\\b"
            ]
            
            for pattern in timePatterns {
                if let range = documentText.range(of: pattern, options: .regularExpression) {
                    let match = String(documentText[range])
                    cookingTime = formatCookingTime(match)
                    if cookingTime != nil { break }
                }
            }
        }
        
        // Количество порций
        let servingsSelectors = [
            "span[itemprop=recipeYield]",
            "[itemprop=recipeYield]",
            ".servings",
            ".recipe-yield"
        ]
        
        for selector in servingsSelectors {
            if let servingsElement = try? document.select(selector).first(),
               let servingsText = try? servingsElement.text(),
               !servingsText.isEmpty {
                
                servings = formatServings(servingsText)
                if servings != nil { break }
            }
        }
        
        // Если не нашли через селекторы, ищем в тексте
        if servings == nil {
            let documentText = try document.text()
            let servingsPatterns = [
                "Количество порций:\\s*([^\\n]+)",
                "Порций:\\s*([^\\n]+)",
                "На\\s+(\\d+\\s*(?:порц|порции|порций|чел|персон))",
                "\\b(\\d+\\s*(?:порц|порции|порций))\\b"
            ]
            
            for pattern in servingsPatterns {
                if let range = documentText.range(of: pattern, options: .regularExpression) {
                    let match = String(documentText[range])
                    servings = formatServings(match)
                    if servings != nil { break }
                }
            }
        }
        
        return (cookingTime, servings)
    }

    // Вспомогательные функции для форматирования
    private static func formatCookingTime(_ time: String) -> String? {
        let cleaned = time.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleaned.isEmpty { return nil }
        
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
        
        if cleaned.isEmpty { return nil }
        
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

}
