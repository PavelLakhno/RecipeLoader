//
//  KoolinarDetailParser.swift
//  RecipeLoader
//
//  Created by user on 19.11.2025.
//

import Foundation
import SwiftSoup

final class KoolinarDetailParser {
    
    static func parseDetailedRecipe(from html: String, url: String) -> Recipe? {
        do {
            let document = try SwiftSoup.parse(html)
            
            let recipeId = extractRecipeId(from: url)
            let title = parseTitle(from: document)
            let description = parseDescription(from: document)
            let mainImage = parseMainImage(from: document)
            let categories = parseCategories(from: document)
            let ingredients = parseIngredients(from: document)
            let instructions = parseInstructions(from: document)
            let (cookingTime, servings, cuisine) = parseRecipeMeta(from: document)
            let addedDate = parseAddedDate(from: document)
            
            print("✅ Детальный парсинг Koolinar:")
            print("   - Название: \(title)")
            print("   - Описание: \(description ?? "нет")")
            print("   - Ингредиенты: \(ingredients.count)")
            print("   - Инструкции: \(instructions.count)")
            print("   - Время: \(cookingTime ?? "нет")")
            print("   - Порции: \(servings ?? "нет")")
            print("   - Кухня: \(cuisine ?? "нет")")
            
            return Recipe(
                id: recipeId,
                title: title,
                source: "Koolinar.ru",
                url: url,
                imageUrl: mainImage,
                description: description,
                categories: categories,
                ingredients: ingredients,
                nutrition: nil,
                instructions: instructions,
                tags: [],
                cookingTime: cookingTime,
                servings: servings,
                cuisine: cuisine,
                addedDate: addedDate
            )
            
        } catch {
            print("❌ Ошибка парсинга детального рецепта Koolinar: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private static func extractRecipeId(from url: String) -> String {
        if let range = url.range(of: "/recipe/view/(\\d+)", options: .regularExpression) {
            return String(url[range])
        }
        return UUID().uuidString
    }
    
    private static func parseTitle(from document: Document) -> String {
        if let titleElement = try? document.select("h1.fn").first(),
           let title = try? titleElement.text(),
           !title.isEmpty {
            return title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let metaTitle = try? document.select("meta[itemprop=name]").first(),
           let title = try? metaTitle.attr("content"),
           !title.isEmpty {
            return title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return ""
    }
  
    private static func parseDescription(from document: Document) -> String? {
        if let metaDescription = try? document.select("meta[name=Description]").first(),
           let fullContent = try? metaDescription.attr("content"),
           !fullContent.isEmpty {
            
            print("✅ Найден полный контент в meta[name=Description]: \(fullContent)")
            
            let components = fullContent.components(separatedBy: " – ")
            
            if components.count >= 2 {
                let description = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                print("✅ Извлечено описание после разделения: \(description.prefix(50))...")
                return description
            } else {
                print("✅ Тире не найдено, используем весь контент как описание: \(fullContent.prefix(50))...")
                return fullContent.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
       
        print("❌ Описание не найдено ни в одном из мест")
        return nil
    }
    
    private static func parseMainImage(from document: Document) -> String? {
        if let imageMeta = try? document.select("meta[itemprop=image]").first(),
           let imageUrl = try? imageMeta.attr("content"),
           !imageUrl.isEmpty {
            return imageUrl.hasPrefix("http") ? imageUrl : "https://www.koolinar.ru\(imageUrl)"
        }
        
        if let imageElement = try? document.select("img.photo.result-photo").first(),
           let imageSrc = try? imageElement.attr("src"),
           !imageSrc.isEmpty {
            return imageSrc.hasPrefix("http") ? imageSrc : "https://www.koolinar.ru\(imageSrc)"
        }
        
        return nil
    }
    
    private static func parseIngredients(from document: Document) -> [Ingredient] {
        var ingredients: [Ingredient] = []
        
        let ingredientElements = try? document.select("li.ingredient[itemprop=recipeIngredient]")
        
        print("🔍 Найдено элементов ингредиентов: \(ingredientElements?.count ?? 0)")
        
        ingredientElements?.enumerated().forEach { index, element in
            if let ingredientText = try? element.text(),
               !ingredientText.isEmpty {
                
                let cleanedText = ingredientText
                    .replacingOccurrences(of: "&nbsp;", with: " ")
                    .replacingOccurrences(of: "\u{00A0}", with: " ")
                    .replacingOccurrences(of: " ", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                let normalizedText = cleanedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                
                print("🔍 Исходный текст ингредиента \(index): '\(ingredientText)'")
                print("🔍 Нормализованный текст: '\(normalizedText)'")
                
                var name = normalizedText
                var amount = ""
                
                if hasAmountPart(in: normalizedText) {
                    if let separatorRange = findSmartSeparator(in: normalizedText) {
                        name = String(normalizedText[..<separatorRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                        amount = String(normalizedText[separatorRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                        print("✅ Умный разделитель найден")
                    } else {
                        let separators = [" – ", " - ", " — ", " –", "– ", " -", "- ", " —", "— "]
                        var usedSeparator: String?
                        
                        for separator in separators {
                            if normalizedText.contains(separator) {
                                let parts = normalizedText.components(separatedBy: separator)
                                if parts.count >= 2 {
                                    name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                                    amount = parts[1...].joined(separator: separator).trimmingCharacters(in: .whitespacesAndNewlines)
                                    usedSeparator = separator
                                    break
                                }
                            }
                        }
                        
                        if usedSeparator == nil {
                            let pattern = #"(.+?)\s*[–\-—]\s*(.+)$"#
                            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                               let match = regex.firstMatch(in: normalizedText, options: [], range: NSRange(location: 0, length: normalizedText.utf16.count)) {
                                
                                if let nameRange = Range(match.range(at: 1), in: normalizedText) {
                                    if let amountRange = Range(match.range(at: 2), in: normalizedText) {
                                        name = String(normalizedText[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                                        amount = String(normalizedText[amountRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                                        print("✅ Использовано regex")
                                    }
                                }
                            }
                        } else {
                            print("✅ Использован простой разделитель: '\(usedSeparator ?? "неизвестно")'")
                        }
                    }
                } else {
                    print("✅ Нет количества - используем всю строку как название")
                }
                
                print("✅ Название: '\(name)'")
                print("✅ Количество: '\(amount)'")
                
                let ingredient = Ingredient(
                    name: name,
                    amount: amount,
                    url: nil
                )
                ingredients.append(ingredient)
            }
        }
        
        return ingredients
    }
    
    private static func parseInstructions(from document: Document) -> [InstructionStep] {
        var instructions: [InstructionStep] = []
        
        let instructionElements = try? document.select("p.instruction")
        
        instructionElements?.enumerated().forEach { index, element in
            if let instructionText = try? element.text(),
               !instructionText.isEmpty {
                
                let cleanedText = instructionText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let instruction = InstructionStep(
                    stepNumber: index + 1,
                    text: cleanedText,
                    imageUrl: nil
                )
                instructions.append(instruction)
            }
        }
        
        if instructions.isEmpty {
            if let instructionsMeta = try? document.select("meta[itemprop=recipeInstructions]").first(),
               let instructionsText = try? instructionsMeta.attr("content"),
               !instructionsText.isEmpty {
                
                let steps = instructionsText.components(separatedBy: ". ")
                steps.enumerated().forEach { index, stepText in
                    if !stepText.isEmpty && stepText.count > 5 {
                        let instruction = InstructionStep(
                            stepNumber: index + 1,
                            text: stepText.trimmingCharacters(in: .whitespacesAndNewlines),
                            imageUrl: nil
                        )
                        instructions.append(instruction)
                    }
                }
            }
        }
        
        return instructions
    }
    
    private static func parseRecipeMeta(from document: Document) -> (cookingTime: String?, servings: String?, cuisine: String?) {
        var cookingTime: String?
        var servings: String?
        var cuisine: String?
        
        if let metaList = try? document.select("div.recipe-meta ul li") {
            for item in metaList {
                guard let text = try? item.text() else { continue }
                
                if text.contains("Время приготовления:") {
                    cookingTime = text.replacingOccurrences(of: "Время приготовления:", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                } else if text.contains("Порций в рецепте:") {
                    servings = text.replacingOccurrences(of: "Порций в рецепте:", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                } else if text.contains("Кухня:") {
                    if let cuisineLink = try? item.select("a").first(),
                       let cuisineText = try? cuisineLink.text() {
                        cuisine = cuisineText.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }
        
        if cookingTime == nil {
            if let timeMeta = try? document.select("meta[itemprop=totalTime]").first(),
               let timeContent = try? timeMeta.attr("content"),
               !timeContent.isEmpty {
                cookingTime = formatCookingTime(timeContent)
            }
        }
        
        if servings == nil {
            if let servingsMeta = try? document.select("meta[itemprop=recipeYield]").first(),
               let servingsContent = try? servingsMeta.attr("content"),
               !servingsContent.isEmpty {
                servings = servingsContent
            }
        }
        
        if cuisine == nil {
            if let cuisineMeta = try? document.select("meta[itemprop=recipeCuisine]").first(),
               let cuisineContent = try? cuisineMeta.attr("content"),
               !cuisineContent.isEmpty {
                cuisine = cuisineContent
            }
        }
        
        return (cookingTime, servings, cuisine)
    }
    
    private static func parseCategories(from document: Document) -> [String] {
        var categories: [String] = []
        
        if let metaList = try? document.select("div.recipe-meta ul li") {
            for item in metaList {
                guard let text = try? item.text() else { continue }
                
                if text.contains("Каталоги:") {
                    let categoryLinks = try? item.select("a")
                    categoryLinks?.forEach { link in
                        if let categoryText = try? link.text(),
                           !categoryText.isEmpty {
                            categories.append(categoryText.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                    }
                    break
                }
            }
        }
        
        if let categoryMeta = try? document.select("meta[itemprop=recipeCategory]").first(),
           let categoryContent = try? categoryMeta.attr("content"),
           !categoryContent.isEmpty {
            categories.append(categoryContent)
        }
        
        return categories
    }
    
    private static func parseAddedDate(from document: Document) -> String? {
        if let metaList = try? document.select("div.recipe-meta ul li") {
            for item in metaList {
                guard let text = try? item.text() else { continue }
                
                if text.contains("Создан:") {
                    let dateText = text.replacingOccurrences(of: "Создан:", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    return formatKoolinarDate(dateText)
                }
            }
        }
        
        if let dateMeta = try? document.select("meta[itemprop=dateCreated]").first(),
           let dateContent = try? dateMeta.attr("content"),
           !dateContent.isEmpty {
            return formatKoolinarDate(dateContent)
        }
        
        return nil
    }
    
    // MARK: - Вспомогательные методы
    
    private static func hasAmountPart(in text: String) -> Bool {
        if text.hasSuffix(":") {
            return false
        }
        
        let amountPatterns = [
            #"\d+\s*(г|кг|мл|л|шт|ч\.л|ст\.л|стак|зуб|пуч|уп|банк|пач|кус|дольк|веточ|лист|стебель|горст|щепот)"#,
            #"по вкусу"#,
            #"для украшения"#,
            #"\d+\s*$"#,
            #"\d+-\d+"#
        ]
        
        for pattern in amountPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil {
                return true
            }
        }
        
        let numberInNamePatterns = [
            #"\d+-х"#,
            #"\d+-й"#,
            #"\d+-го"#,
            #"\d+-литров"#,
            #"на \d+"#
        ]
        
        for pattern in numberInNamePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil {
                return false
            }
        }
        
        return false
    }
    
    private static func findSmartSeparator(in text: String) -> Range<String.Index>? {
        let separators = [" – ", " - ", " — "]
        
        for separator in separators {
            if let range = text.range(of: separator, options: .backwards) {
                let textBeforeSeparator = String(text[..<range.lowerBound])
                let openBrackets = textBeforeSeparator.filter { $0 == "(" }.count
                let closeBrackets = textBeforeSeparator.filter { $0 == ")" }.count
                
                if openBrackets == closeBrackets {
                    return range
                }
            }
        }
        
        return nil
    }
    
    private static func formatCookingTime(_ timeString: String) -> String {
        if timeString.hasPrefix("PT") {
            let time = String(timeString.dropFirst(2))
            if time.hasSuffix("M") {
                let minutes = String(time.dropLast())
                return "\(minutes) мин."
            }
        }
        return timeString
    }
    
    private static func formatKoolinarDate(_ dateString: String) -> String {
        let cleaned = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let commaRange = cleaned.range(of: ",") {
            return String(cleaned[..<commaRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleaned
    }
}
