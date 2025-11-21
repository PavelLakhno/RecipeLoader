//
//  GastronomDetailParser.swift
//  RecipeLoader
//
//  Created by user on 20.11.2025.
//

//import Foundation
//import SwiftSoup
//
//final class GastronomDetailParser {
//    
//    static func parseDetailedRecipe(from html: String, url: String) -> Recipe? {
//        do {
//            let document = try SwiftSoup.parse(html)
//            
//            print("🔍 Начинаем парсинг детальной страницы Gastronom...")
//            
//            // Сначала пытаемся распарсить из JSON-LD
//            if let recipeFromJson = parseFromJsonLd(from: document, url: url) {
//                print("✅ Успешно распарсено из JSON-LD")
//                return recipeFromJson
//            }
//            
//            // Если JSON-LD нет или не удалось распарсить, пробуем HTML
//            print("❌ JSON-LD не найден, пробуем HTML парсинг")
//            return parseFromHtml(from: document, url: url)
//            
//        } catch {
//            print("❌ Ошибка парсинга детального рецепта Gastronom: \(error)")
//            return nil
//        }
//    }
//    
//    // MARK: - Парсинг из JSON-LD
//    private static func parseFromJsonLd(from document: Document, url: String) -> Recipe? {
//        do {
//            // Ищем все JSON-LD скрипты
//            let jsonLdScripts = try document.select("script[type='application/ld+json']")
//            
//            for script in jsonLdScripts {
//                let jsonString = try script.html()
//                
//                // Пробуем разные подходы к парсингу JSON
//                if let recipe = parseJsonLdWithMultipleObjects(jsonString, url: url) {
//                    return recipe
//                }
//            }
//        } catch {
//            print("❌ Ошибка поиска JSON-LD: \(error)")
//        }
//        
//        return nil
//    }
//    
//    private static func parseJsonLdWithMultipleObjects(_ jsonString: String, url: String) -> Recipe? {
//        // Очищаем JSON строку
//        let cleanJson = jsonString
//            .replacingOccurrences(of: "\n", with: "")
////            .replacingOccurrences(of: "\t", 
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        // Пробуем разные стратегии парсинга
//        
//        // Стратегия 1: Пробуем распарсить как массив JSON объектов
//        if let jsonArrayData = cleanJson.data(using: .utf8),
//           let jsonArray = try? JSONSerialization.jsonObject(with: jsonArrayData) as? [[String: Any]] {
//            
//            for jsonDict in jsonArray {
//                if let recipe = parseSingleJsonObject(jsonDict, url: url) {
//                    return recipe
//                }
//            }
//        }
//        
//        // Стратегия 2: Пробуем найти отдельные JSON объекты в строке
//        let jsonObjects = extractJsonObjects(from: cleanJson)
//        for jsonObjectString in jsonObjects {
//            if let jsonData = jsonObjectString.data(using: .utf8),
//               let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
//               let recipe = parseSingleJsonObject(jsonDict, url: url) {
//                return recipe
//            }
//        }
//        
//        // Стратегия 3: Пробуем исправить JSON вручную (удаляем лишние фигурные скобки)
//        if let fixedJson = tryFixJson(cleanJson),
//           let jsonData = fixedJson.data(using: .utf8),
//           let jsonDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
//           let recipe = parseSingleJsonObject(jsonDict, url: url) {
//            return recipe
//        }
//        
//        return nil
//    }
//    
//    private static func extractJsonObjects(from jsonString: String) -> [String] {
//        var objects: [String] = []
//        var currentObject = ""
//        var braceCount = 0
//        var inString = false
//        var escapeNext = false
//        
//        for char in jsonString {
//            if escapeNext {
//                currentObject.append(char)
//                escapeNext = false
//                continue
//            }
//            
//            if char == "\\" {
//                currentObject.append(char)
//                escapeNext = true
//                continue
//            }
//            
//            if char == "\"" {
//                inString.toggle()
//            }
//            
//            if !inString {
//                if char == "{" {
//                    braceCount += 1
//                    if braceCount == 1 {
//                        currentObject = "{"
//                        continue
//                    }
//                } else if char == "}" {
//                    braceCount -= 1
//                    if braceCount == 0 {
//                        currentObject.append(char)
//                        objects.append(currentObject)
//                        currentObject = ""
//                        continue
//                    }
//                }
//            }
//            
//            if braceCount > 0 {
//                currentObject.append(char)
//            }
//        }
//        
//        return objects
//    }
//    
//    private static func tryFixJson(_ jsonString: String) -> String? {
//        // Пробуем найти начало первого JSON объекта и конец последнего
//        if let startIndex = jsonString.firstIndex(of: "{"),
//           let endIndex = jsonString.lastIndex(of: "}") {
//            let fixed = String(jsonString[startIndex...endIndex])
//            return fixed
//        }
//        return nil
//    }
//    
//    private static func parseSingleJsonObject(_ jsonDict: [String: Any], url: String) -> Recipe? {
//        // Проверяем, это рецепт?
//        guard let type = jsonDict["@type"] as? String,
//              type == "Recipe" else {
//            return nil
//        }
//        
//        print("✅ Найден JSON-LD рецепта")
//        
//        // Основная информация
//        guard let title = jsonDict["name"] as? String else {
//            print("❌ Не найден заголовок в JSON")
//            return nil
//        }
//        
//        let description = jsonDict["description"] as? String
//        let imageUrl = jsonDict["image"] as? String
//        
//        print("📝 Заголовок: \(title)")
//        print("📝 Описание: \(description?.prefix(50) ?? "nil")...")
//        print("🖼️ Изображение: \(imageUrl ?? "nil")")
//        
//        // Ингредиенты
//        let ingredients = parseIngredientsFromJson(jsonDict)
//        print("🥕 Ингредиенты: \(ingredients.count)")
//        
//        // Инструкции
//        let instructions = parseInstructionsFromJson(jsonDict)
//        print("👨‍🍳 Инструкции: \(instructions.count)")
//        
//        // Время и порции
//        let (cookingTime, servings) = parseTimeAndServingsFromJson(jsonDict)
//        print("⏱ Время: \(cookingTime ?? "nil")")
//        print("🍽 Порции: \(servings ?? "nil")")
//        
//        // Категории
//        let categories = parseCategoriesFromJson(jsonDict)
//        print("📁 Категории: \(categories)")
//        
//        return Recipe(
//            id: extractRecipeId(from: url),
//            title: title,
//            source: "Gastronom.ru",
//            url: url,
//            imageUrl: imageUrl,
//            description: description,
//            categories: categories,
//            ingredients: ingredients,
//            nutrition: nil,
//            instructions: instructions,
//            tags: [],
//            cookingTime: cookingTime,
//            servings: servings,
//            cuisine: nil,
//            addedDate: nil
//        )
//    }
//    
//    private static func parseIngredientsFromJson(_ jsonDict: [String: Any]) -> [Ingredient] {
//        guard let ingredientsArray = jsonDict["recipeIngredient"] as? [String] else {
//            print("❌ Ингредиенты не найдены в JSON")
//            return []
//        }
//        
//        let parsedIngredients = ingredientsArray.map { ingredientString in
//            // Удаляем HTML теги если есть
//            let cleanString: String
//            do {
//                let doc = try SwiftSoup.parse(ingredientString)
//                cleanString = try doc.text()
//            } catch {
//                cleanString = ingredientString
//            }
//            
//            // Разные варианты разделителей
//            let separators = [" - ", " – ", " — ", " "]
//            
//            for separator in separators {
//                let components = cleanString.components(separatedBy: separator)
//                if components.count >= 2 {
//                    // Проверяем, содержит ли первая часть количество (цифры, единицы измерения)
//                    let firstPart = components[0].trimmingCharacters(in: .whitespaces)
//                    let hasAmount = firstPart.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil ||
//                                   firstPart.contains("г") || firstPart.contains("мл") ||
//                                   firstPart.contains("кг") || firstPart.contains("ч") ||
//                                   firstPart.contains("шт") || firstPart.contains("ст") ||
//                                   firstPart.contains("ч.л.") || firstPart.contains("ст.л.")
//                    
//                    if hasAmount {
//                        let name = components.dropFirst().joined(separator: separator).trimmingCharacters(in: .whitespaces)
//                        return Ingredient(
//                            name: name,
//                            amount: firstPart,
//                            url: nil
//                        )
//                    }
//                }
//            }
//            
//            // Если разделителей нет, используем всю строку как название
//            return Ingredient(
//                name: cleanString.trimmingCharacters(in: .whitespaces),
//                amount: "",
//                url: nil
//            )
//        }
//        
//        print("📋 Распарсенные ингредиенты:")
//        parsedIngredients.forEach { ingredient in
//            print("   - \(ingredient.amount) \(ingredient.name)")
//        }
//        
//        return parsedIngredients
//    }
////    private static func parseIngredientsFromJson(_ jsonDict: [String: Any]) -> [Ingredient] {
////        guard let ingredientsArray = jsonDict["recipeIngredient"] as? [String] else {
////            print("❌ Ингредиенты не найдены в JSON")
////            return []
////        }
////        
////        let parsedIngredients = ingredientsArray.map { ingredientString in
////            // Разные варианты разделителей
////            let separators = [" - ", " – ", " — "]
////            
////            for separator in separators {
////                let components = ingredientString.components(separatedBy: separator)
////                if components.count >= 2 {
////                    return Ingredient(
////                        name: components[1].trimmingCharacters(in: .whitespaces),
////                        amount: components[0].trimmingCharacters(in: .whitespaces),
////                        url: nil
////                    )
////                }
////            }
////            
////            // Если разделителей нет, используем всю строку как название
////            return Ingredient(
////                name: ingredientString.trimmingCharacters(in: .whitespaces),
////                amount: "",
////                url: nil
////            )
////        }
////        
////        print("📋 Распарсенные ингредиенты:")
////        parsedIngredients.forEach { ingredient in
////            print("   - \(ingredient.amount) \(ingredient.name)")
////        }
////        
////        return parsedIngredients
////    }
//    
//    private static func parseInstructionsFromJson(_ jsonDict: [String: Any]) -> [InstructionStep] {
//        var instructions: [InstructionStep] = []
//        
//        // Формат 1: Массив объектов с текстом
//        if let instructionsArray = jsonDict["recipeInstructions"] as? [[String: Any]] {
//            instructions = instructionsArray.enumerated().compactMap { index, instructionDict in
//                guard let text = instructionDict["text"] as? String else { return nil }
//                return InstructionStep(
//                    stepNumber: index + 1,
//                    text: cleanInstructionText(text),
//                    imageUrl: instructionDict["image"] as? String
//                )
//            }
//        }
//        // Формат 2: Просто массив строк
//        else if let instructionsArray = jsonDict["recipeInstructions"] as? [String] {
//            instructions = instructionsArray.enumerated().map { index, text in
//                InstructionStep(
//                    stepNumber: index + 1,
//                    text: cleanInstructionText(text),
//                    imageUrl: nil
//                )
//            }
//        }
//        
//        print("📋 Распарсенные инструкции:")
//        instructions.forEach { instruction in
//            print("   - Шаг \(instruction.stepNumber): \(instruction.text.prefix(50))...")
//        }
//        
//        return instructions
//    }
//    
//    private static func cleanInstructionText(_ text: String) -> String {
//        do {
//            let doc = try SwiftSoup.parse(text)
//            let cleanText = try doc.text()
//            return cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
//        } catch {
//            return text.trimmingCharacters(in: .whitespacesAndNewlines)
//        }
//    }
//    
//    private static func parseTimeAndServingsFromJson(_ jsonDict: [String: Any]) -> (String?, String?) {
//        var cookingTime: String?
//        var servings: String?
//        
//        // Время приготовления
//        if let cookTime = jsonDict["cookTime"] as? String {
//            cookingTime = parseISODuration(cookTime)
//        } else if let totalTime = jsonDict["totalTime"] as? String {
//            cookingTime = parseISODuration(totalTime)
//        }
//        
//        // Количество порций
//        if let recipeYield = jsonDict["recipeYield"] as? String {
//            servings = recipeYield
//        } else if let recipeYield = jsonDict["recipeYield"] as? Int {
//            servings = "\(recipeYield)"
//        }
//        
//        return (cookingTime, servings)
//    }
//    
//    private static func parseISODuration(_ duration: String) -> String {
//        let pattern = "PT(?:([0-9]+)H)?(?:([0-9]+)M)?"
//        
//        do {
//            let regex = try NSRegularExpression(pattern: pattern)
//            let nsRange = NSRange(duration.startIndex..., in: duration)
//            
//            if let match = regex.firstMatch(in: duration, range: nsRange) {
//                var hours = ""
//                var minutes = ""
//                
//                if match.range(at: 1).location != NSNotFound,
//                   let hourRange = Range(match.range(at: 1), in: duration) {
//                    hours = String(duration[hourRange])
//                }
//                
//                if match.range(at: 2).location != NSNotFound,
//                   let minuteRange = Range(match.range(at: 2), in: duration) {
//                    minutes = String(duration[minuteRange])
//                }
//                
//                if !hours.isEmpty && !minutes.isEmpty {
//                    return "\(hours) ч \(minutes) мин"
//                } else if !hours.isEmpty {
//                    return "\(hours) ч"
//                } else if !minutes.isEmpty {
//                    return "\(minutes) мин"
//                }
//            }
//        } catch {
//            print("❌ Ошибка парсинга ISO duration: \(error)")
//        }
//        
//        return duration
//    }
//    
//    private static func parseCategoriesFromJson(_ jsonDict: [String: Any]) -> [String] {
//        var categories: [String] = []
//        
//        if let category = jsonDict["recipeCategory"] as? String {
//            categories.append(category)
//        } else if let categoriesArray = jsonDict["recipeCategory"] as? [String] {
//            categories.append(contentsOf: categoriesArray)
//        }
//        
//        return categories
//    }
//    
//    // MARK: - Резервный HTML парсинг
//    private static func parseFromHtml(from document: Document, url: String) -> Recipe? {
//        print("🔍 Начинаем HTML парсинг...")
//        
//        let title = parseTitle(from: document)
//        let description = parseDescription(from: document)
//        let mainImage = parseMainImage(from: document)
//        
//        print("📝 HTML - Заголовок: \(title)")
//        print("📝 HTML - Описание: \(description?.prefix(50) ?? "nil")...")
//        print("🖼️ HTML - Изображение: \(mainImage ?? "nil")")
//        
//        let ingredients = parseIngredientsFromHtml(from: document)
//        let instructions = parseInstructionsFromHtml(from: document)
//        let (cookingTime, servings) = parseTimeAndServingsFromHtml(from: document)
//        
//        print("🥕 HTML - Ингредиенты: \(ingredients.count)")
//        print("👨‍🍳 HTML - Инструкции: \(instructions.count)")
//        print("⏱ HTML - Время: \(cookingTime ?? "nil")")
//        print("🍽 HTML - Порции: \(servings ?? "nil")")
//        
//        // Если не нашли ингредиенты и инструкции, пробуем альтернативные методы
//        var finalIngredients = ingredients
//        var finalInstructions = instructions
//        
//        if ingredients.isEmpty {
//            finalIngredients = parseIngredientsFromText(from: document)
//            print("🥕 Альтернативные ингредиенты: \(finalIngredients.count)")
//        }
//        
//        if instructions.isEmpty {
//            finalInstructions = parseInstructionsFromText(from: document)
//            print("👨‍🍳 Альтернативные инструкции: \(finalInstructions.count)")
//        }
//        
//        return Recipe(
//            id: extractRecipeId(from: url),
//            title: title,
//            source: "Gastronom.ru",
//            url: url,
//            imageUrl: mainImage,
//            description: description,
//            categories: [],
//            ingredients: finalIngredients,
//            nutrition: nil,
//            instructions: finalInstructions,
//            tags: [],
//            cookingTime: cookingTime,
//            servings: servings,
//            cuisine: nil,
//            addedDate: nil
//        )
//    }
//    
//    private static func parseIngredientsFromHtml(from document: Document) -> [Ingredient] {
//        let ingredientSelectors = [
//            "div[itemprop=recipeIngredient]",
//            ".ingredients-list li",
//            ".recipe-ingredients li",
//            ".ingredient-item",
//            "[data-ingredient]",
//            ".b-ingredient",
//            ".ingredient",
//            ".recipe-ingredient"
//        ]
//        
//        for selector in ingredientSelectors {
//            do {
//                let elements = try document.select(selector)
//                if !elements.isEmpty() {
//                    print("✅ Найден селектор ингредиентов: \(selector), элементов: \(elements.count)")
//                    
//                    let ingredients = try elements.compactMap { element -> Ingredient? in
//                        let fullText = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
//                        guard !fullText.isEmpty else { return nil }
//                        
//                        // Для селектора div[itemprop=recipeIngredient] - специальная обработка
//                        if selector == "div[itemprop=recipeIngredient]" {
//                            // Извлекаем обычный текст (название) и жирный текст (количество)
//                            let normalText = try element.ownText().trimmingCharacters(in: .whitespacesAndNewlines)
//                            let boldElements = try element.select("span._bold_1e2lm_28, span[class*='bold'], b, strong")
//                            let boldText = try boldElements.text().trimmingCharacters(in: .whitespacesAndNewlines)
//                            
//                            if !normalText.isEmpty && !boldText.isEmpty {
//                                return Ingredient(
//                                    name: normalText,
//                                    amount: boldText,
//                                    url: nil
//                                )
//                            } else if !normalText.isEmpty {
//                                // Если нет жирного текста, пробуем разделить по пробелу
//                                let components = normalText.components(separatedBy: " ")
//                                if components.count >= 2 {
//                                    let amount = components[0]
//                                    let name = components.dropFirst().joined(separator: " ")
//                                    return Ingredient(name: name, amount: amount, url: nil)
//                                }
//                            }
//                        }
//                        
//                        // Стандартная обработка для других селекторов
//                        let separators = [" - ", " – ", " — "]
//                        for separator in separators {
//                            let components = fullText.components(separatedBy: separator)
//                            if components.count >= 2 {
//                                return Ingredient(
//                                    name: components[1].trimmingCharacters(in: .whitespaces),
//                                    amount: components[0].trimmingCharacters(in: .whitespaces),
//                                    url: nil
//                                )
//                            }
//                        }
//                        
//                        return Ingredient(
//                            name: fullText,
//                            amount: "",
//                            url: nil
//                        )
//                    }
//                    
//                    if !ingredients.isEmpty {
//                        return ingredients
//                    }
//                }
//            } catch {
//                print("❌ Ошибка парсинга ингредиентов для селектора \(selector): \(error)")
//                continue
//            }
//        }
//        
//        return []
//    }
////    private static func parseIngredientsFromHtml(from document: Document) -> [Ingredient] {
////        let ingredientSelectors = [
////            ".ingredients-list li",
////            ".recipe-ingredients li",
////            ".ingredient-item",
////            "[data-ingredient]",
////            ".b-ingredient",
////            ".ingredient",
////            ".recipe-ingredient"
////        ]
////        
////        for selector in ingredientSelectors {
////            do {
////                let elements = try document.select(selector)
////                if !elements.isEmpty() {
////                    print("✅ Найден селектор ингредиентов: \(selector), элементов: \(elements.count)")
////                    
////                    let ingredients = try elements.compactMap { element -> Ingredient? in
////                        let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
////                        guard !text.isEmpty else { return nil }
////                        
////                        // Пробуем разные разделители
////                        let separators = [" - ", " – ", " — "]
////                        for separator in separators {
////                            let components = text.components(separatedBy: separator)
////                            if components.count >= 2 {
////                                return Ingredient(
////                                    name: components[1].trimmingCharacters(in: .whitespaces),
////                                    amount: components[0].trimmingCharacters(in: .whitespaces),
////                                    url: nil
////                                )
////                            }
////                        }
////                        
////                        return Ingredient(
////                            name: text,
////                            amount: "",
////                            url: nil
////                        )
////                    }
////                    
////                    if !ingredients.isEmpty {
////                        return ingredients
////                    }
////                }
////            } catch {
////                continue
////            }
////        }
////        
////        return []
////    }
//    
//    
//    private static func parseIngredientsFromText(from document: Document) -> [Ingredient] {
//        // Альтернативный метод: ищем текст, который выглядит как ингредиенты
//        do {
//            let bodyText = try document.text()
//            
//            // Ищем паттерны типа "Ингредиент - количество"
//            let pattern = "([а-яА-Яa-zA-Z\\s]+)\\s*[-–—]\\s*([\\d\\s.,/]+[гмлкгчшт]?)"
//            let regex = try NSRegularExpression(pattern: pattern)
//            let matches = regex.matches(in: bodyText, range: NSRange(bodyText.startIndex..., in: bodyText))
//            
//            return matches.compactMap { match in
//                guard let nameRange = Range(match.range(at: 1), in: bodyText),
//                      let amountRange = Range(match.range(at: 2), in: bodyText) else {
//                    return nil
//                }
//                
//                let name = String(bodyText[nameRange]).trimmingCharacters(in: .whitespaces)
//                let amount = String(bodyText[amountRange]).trimmingCharacters(in: .whitespaces)
//                
//                return Ingredient(name: name, amount: amount, url: nil)
//            }
//        } catch {
//            return []
//        }
//    }
//    
//    private static func parseInstructionsFromHtml(from document: Document) -> [InstructionStep] {
//        let instructionSelectors = [
//            "div._editorjsContent_s0mz7_2",
//            ".instructions-list li",
//            ".recipe-steps li",
//            ".cooking-steps li",
//            "[data-step]",
//            ".step",
//            ".recipe-step",
//            ".cooking-step"
//        ]
//        
//        for selector in instructionSelectors {
//            do {
//                let elements = try document.select(selector)
//                if !elements.isEmpty() {
//                    print("✅ Найден селектор инструкций: \(selector), элементов: \(elements.count)")
//                    
//                    var instructions: [InstructionStep] = []
//                    var stepNumber = 1
//                    
//                    for element in elements {
//                        // Для селектора div._editorjsContent_s0mz7_2 - специальная обработка
//                        if selector == "div._editorjsContent_s0mz7_2" {
//                            // Ищем заголовки шагов (h2)
//                            let stepHeaders = try element.select("h2")
//                            if !stepHeaders.isEmpty() {
//                                for header in stepHeaders {
//                                    let headerText = try header.text()
//                                    print("🔍 Найден заголовок шага: \(headerText)")
//                                    
//                                    // Ищем текст инструкции (параграфы)
//                                    let paragraphs = try element.select("p")
//                                    var instructionText = ""
//                                    
//                                    for paragraph in paragraphs {
//                                        let text = try paragraph.text().trimmingCharacters(in: .whitespacesAndNewlines)
//                                        if !text.isEmpty {
//                                            if !instructionText.isEmpty {
//                                                instructionText += " "
//                                            }
//                                            instructionText += text
//                                        }
//                                    }
//                                    
//                                    // Ищем изображение шага
//                                    let stepImage = try element.select("figure img").first()
//                                    let imageUrl = try stepImage?.attr("src")
//                                    
//                                    if !instructionText.isEmpty {
//                                        let instruction = InstructionStep(
//                                            stepNumber: stepNumber,
//                                            text: instructionText,
//                                            imageUrl: imageUrl
//                                        )
//                                        instructions.append(instruction)
//                                        stepNumber += 1
//                                        
//                                        print("📝 Шаг \(instruction.stepNumber): \(instruction.text.prefix(50))...")
//                                        print("🖼️ Изображение шага: \(imageUrl ?? "нет")")
//                                    }
//                                }
//                            } else {
//                                // Если нет заголовков, ищем любой текст и изображения
//                                let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
//                                let stepImage = try element.select("figure img").first()
//                                let imageUrl = try stepImage?.attr("src")
//                                
//                                if !text.isEmpty {
//                                    let instruction = InstructionStep(
//                                        stepNumber: stepNumber,
//                                        text: text,
//                                        imageUrl: imageUrl
//                                    )
//                                    instructions.append(instruction)
//                                    stepNumber += 1
//                                }
//                            }
//                        } else {
//                            // Стандартная обработка для других селекторов
//                            let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
//                            guard !text.isEmpty else { continue }
//                            
//                            let instruction = InstructionStep(
//                                stepNumber: stepNumber,
//                                text: text,
//                                imageUrl: nil
//                            )
//                            instructions.append(instruction)
//                            stepNumber += 1
//                        }
//                    }
//                    
//                    if !instructions.isEmpty {
//                        return instructions
//                    }
//                }
//            } catch {
//                print("❌ Ошибка парсинга инструкций для селектора \(selector): \(error)")
//                continue
//            }
//        }
//        
//        return []
//    }
////    private static func parseInstructionsFromHtml(from document: Document) -> [InstructionStep] {
////        let instructionSelectors = [
////            ".instructions-list li",
////            ".recipe-steps li",
////            ".cooking-steps li",
////            "[data-step]",
////            ".step",
////            ".recipe-step",
////            ".cooking-step"
////        ]
////        
////        for selector in instructionSelectors {
////            do {
////                let elements = try document.select(selector)
////                if !elements.isEmpty() {
////                    print("✅ Найден селектор инструкций: \(selector), элементов: \(elements.count)")
////                    
////                    let instructions = try elements.enumerated().compactMap { index, element -> InstructionStep? in
////                        let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
////                        guard !text.isEmpty else { return nil }
////                        
////                        return InstructionStep(
////                            stepNumber: index + 1,
////                            text: text,
////                            imageUrl: nil
////                        )
////                    }
////                    
////                    if !instructions.isEmpty {
////                        return instructions
////                    }
////                }
////            } catch {
////                continue
////            }
////        }
////        
////        return []
////    }
//    
//    private static func parseInstructionsFromText(from document: Document) -> [InstructionStep] {
//        // Альтернативный метод: ищем шаги по заголовкам h2
//        do {
//            let stepHeaders = try document.select("h2")
//            var instructions: [InstructionStep] = []
//            
//            for (index, header) in stepHeaders.enumerated() {
//                let headerText = try header.text()
//                if headerText.lowercased().contains("шаг") {
//                    // Ищем следующий элемент с текстом инструкции
//                    var instructionText = ""
//                    var nextElement = try header.nextElementSibling()
//                    
//                    while nextElement != nil {
//                        if let element = nextElement {
//                            let tagName = element.tagName()
//                            if tagName == "p" {
//                                let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
//                                if !text.isEmpty {
//                                    if !instructionText.isEmpty {
//                                        instructionText += " "
//                                    }
//                                    instructionText += text
//                                }
//                            } else if tagName == "h2" || tagName == "h3" {
//                                // Достигли следующего заголовка - останавливаемся
//                                break
//                            }
//                            
//                            // Ищем изображение в текущем блоке
//                            let stepImage = try element.select("img").first()
//                            let imageUrl = try stepImage?.attr("src")
//                            
//                            if !instructionText.isEmpty {
//                                let instruction = InstructionStep(
//                                    stepNumber: index + 1,
//                                    text: instructionText,
//                                    imageUrl: imageUrl
//                                )
//                                instructions.append(instruction)
//                                break
//                            }
//                            
//                            nextElement = try element.nextElementSibling()
//                        }
//                    }
//                }
//            }
//            
//            if !instructions.isEmpty {
//                return instructions
//            }
//        } catch {
//            print("❌ Ошибка альтернативного парсинга инструкций: \(error)")
//        }
//        
//        return []
//    }
//    
////    private static func parseInstructionsFromText(from document: Document) -> [InstructionStep] {
////        // Альтернативный метод: ищем пронумерованные шаги
////        do {
////            let numberedSteps = try document.select("ol li, .step-number, [class*='step']")
////            if !numberedSteps.isEmpty() {
////                return numberedSteps.enumerated().compactMap { index, element in
////                    guard let text = try? element.text().trimmingCharacters(in: .whitespacesAndNewlines),
////                          !text.isEmpty else { return nil }
////                    
////                    return InstructionStep(
////                        stepNumber: index + 1,
////                        text: text,
////                        imageUrl: nil
////                    )
////                }
////            }
////        } catch {
////            return []
////        }
////        
////        return []
////    }
//    
//    private static func parseTimeAndServingsFromHtml(from document: Document) -> (String?, String?) {
//        let timeSelectors = [".cooking-time", ".recipe-time", ".time", "[data-time]"]
//        let servingsSelectors = [".servings", ".recipe-yield", ".portions", "[data-servings]"]
//        
//        var cookingTime: String?
//        var servings: String?
//        
//        for selector in timeSelectors {
//            if let time = try? document.select(selector).first()?.text(),
//               !time.isEmpty {
//                cookingTime = time.trimmingCharacters(in: .whitespacesAndNewlines)
//                break
//            }
//        }
//        
//        for selector in servingsSelectors {
//            if let serving = try? document.select(selector).first()?.text(),
//               !serving.isEmpty {
//                servings = serving.trimmingCharacters(in: .whitespacesAndNewlines)
//                break
//            }
//        }
//        
//        return (cookingTime, servings)
//    }
//    
//    // MARK: - Вспомогательные методы
//    
//    private static func extractRecipeId(from url: String) -> String {
//        if let regex = try? NSRegularExpression(pattern: "/recipe/(\\d+)"),
//           let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
//           let range = Range(match.range(at: 1), in: url) {
//            return String(url[range])
//        }
//        return UUID().uuidString
//    }
//    
//    private static func parseTitle(from document: Document) -> String {
//        let titleSelectors = ["h1", ".recipe-title", ".title", "[data-title]"]
//        
//        for selector in titleSelectors {
//            if let title = try? document.select(selector).first()?.text(),
//               !title.isEmpty {
//                return title.trimmingCharacters(in: .whitespacesAndNewlines)
//            }
//        }
//        
//        return "Без названия"
//    }
//    
//    private static func parseDescription(from document: Document) -> String? {
//        let descriptionSelectors = [".recipe-description", ".description", "[data-description]"]
//        
//        for selector in descriptionSelectors {
//            if let description = try? document.select(selector).first()?.text(),
//               !description.isEmpty {
//                return description.trimmingCharacters(in: .whitespacesAndNewlines)
//            }
//        }
//        
//        return nil
//    }
//    
//    private static func parseMainImage(from document: Document) -> String? {
//        let imageSelectors = [
//            "img.recipe-image",
//            ".recipe-image img",
//            ".main-image img",
//            "[data-image]"
//        ]
//        
//        for selector in imageSelectors {
//            if let imageElement = try? document.select(selector).first(),
//               let imageSrc = try? imageElement.attr("src"),
//               !imageSrc.isEmpty {
//                return imageSrc.hasPrefix("http") ? imageSrc : "https://www.gastronom.ru\(imageSrc)"
//            }
//        }
//        
//        if let metaImage = try? document.select("meta[property=og:image]").first()?.attr("content"),
//           !metaImage.isEmpty {
//            return metaImage
//        }
//        
//        return nil
//    }
//}

import Foundation
import SwiftSoup

final class GastronomDetailParser {
    
    static func parseDetailedRecipe(from html: String, url: String) -> Recipe? {
        do {
            let document = try SwiftSoup.parse(html)
            
            print("🔍 Начинаем парсинг детальной страницы Gastronom...")
            
            // Пробуем HTML парсинг для новой структуры Gastronom
            return parseModernGastronomPage(from: document, url: url)
            
        } catch {
            print("❌ Ошибка парсинга детального рецепта Gastronom: \(error)")
            return nil
        }
    }
    
    // MARK: - Парсинг современной версии сайта Gastronom
    private static func parseModernGastronomPage(from document: Document, url: String) -> Recipe? {
        print("🔍 Парсинг современной версии Gastronom...")
        
        let title = parseModernTitle(from: document)
        let description = parseModernDescription(from: document)
        let mainImage = parseModernMainImage(from: document)
        
        print("📝 Заголовок: \(title)")
        print("📝 Описание: \(description?.prefix(50) ?? "nil")...")
        print("🖼️ Главное изображение: \(mainImage ?? "nil")")
        
        let ingredients = parseModernIngredients(from: document)
        let instructions = parseModernInstructions(from: document)
        let (cookingTime, servings) = parseModernTimeAndServings(from: document)
        
        print("🥕 Ингредиенты: \(ingredients.count)")
        print("👨‍🍳 Инструкции: \(instructions.count)")
        print("⏱ Время: \(cookingTime ?? "nil")")
        print("🍽 Порции: \(servings ?? "nil")")
        
        return Recipe(
            id: extractRecipeId(from: url),
            title: title,
            source: "Gastronom.ru",
            url: url,
            imageUrl: mainImage,
            description: description,
            categories: [],
            ingredients: ingredients,
            nutrition: nil,
            instructions: instructions,
            tags: [],
            cookingTime: cookingTime,
            servings: servings,
            cuisine: nil,
            addedDate: nil
        )
    }
    
    // MARK: - Парсинг ингредиентов из новой структуры
    private static func parseModernIngredients(from document: Document) -> [Ingredient] {
        var ingredients: [Ingredient] = []
        
        // Способ 1: Ищем по itemprop="recipeIngredient"
        do {
            let ingredientElements = try document.select("div[itemprop=recipeIngredient]")
            if !ingredientElements.isEmpty() {
                print("✅ Найдены ингредиенты через itemprop: \(ingredientElements.count)")
                
                for element in ingredientElements {
                    let fullText = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Извлекаем обычный текст (название) и жирный текст (количество)
                    let normalText = element.ownText().trimmingCharacters(in: .whitespacesAndNewlines)
                    let boldElements = try element.select("span._bold_1e2lm_28, .bold, b, strong")
                    let boldText = try boldElements.text().trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !normalText.isEmpty && !boldText.isEmpty {
                        let ingredient = Ingredient(
                            name: normalText,
                            amount: boldText,
                            url: nil
                        )
                        ingredients.append(ingredient)
                        print("   - \(boldText) \(normalText)")
                    } else if !fullText.isEmpty {
                        // Резервный метод: пробуем разделить по последнему пробелу
                        let components = fullText.split(separator: " ").map(String.init)
                        if components.count >= 2, let last = components.last {
                            let amount = last
                            let name = components.dropLast().joined(separator: " ")
                            let ingredient = Ingredient(name: name, amount: amount, url: nil)
                            ingredients.append(ingredient)
                            print("   - \(amount) \(name)")
                        } else {
                            let ingredient = Ingredient(name: fullText, amount: "", url: nil)
                            ingredients.append(ingredient)
                            print("   - \(fullText)")
                        }
                    }
                }
                
                if !ingredients.isEmpty {
                    return ingredients
                }
            }
        } catch {
            print("❌ Ошибка парсинга ингредиентов через itemprop: \(error)")
        }
        
        // Способ 2: Ищем по классам
        let ingredientSelectors = [
            "._step_1e2lm_19 div", // основной селектор для новых страниц
            "._ingredient_1e2lm_1",
            ".recipe-ingredient",
            ".ingredient-item"
        ]
        
        for selector in ingredientSelectors {
            do {
                let elements = try document.select(selector)
                if !elements.isEmpty() {
                    print("✅ Найден селектор ингредиентов: \(selector), элементов: \(elements.count)")
                    
                    for element in elements {
                        let fullText = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !fullText.isEmpty else { continue }
                        
                        // Пробуем разные разделители
                        let separators = [" - ", " – ", " — "]
                        var found = false
                        
                        for separator in separators {
                            let components = fullText.components(separatedBy: separator)
                            if components.count >= 2 {
                                let name = components[1].trimmingCharacters(in: .whitespaces)
                                let amount = components[0].trimmingCharacters(in: .whitespaces)
                                let ingredient = Ingredient(name: name, amount: amount, url: nil)
                                ingredients.append(ingredient)
                                found = true
                                print("   - \(amount) \(name)")
                                break
                            }
                        }
                        
                        if !found {
                            // Если разделителей нет, используем всю строку как название
                            let ingredient = Ingredient(name: fullText, amount: "", url: nil)
                            ingredients.append(ingredient)
                            print("   - \(fullText)")
                        }
                    }
                    
                    if !ingredients.isEmpty {
                        return ingredients
                    }
                }
            } catch {
                print("❌ Ошибка парсинга ингредиентов для селектора \(selector): \(error)")
                continue
            }
        }
        
        print("❌ Не найдены ингредиенты")
        return []
    }
    
    // MARK: - Парсинг инструкций из новой структуры
    private static func parseModernInstructions(from document: Document) -> [InstructionStep] {
        var instructions: [InstructionStep] = []
        
        // Способ 1: Ищем блоки с шагами по классу _editorjsContent_s0mz7_2
            do {
                let stepContainers = try document.select("div._editorjsContent_s0mz7_2")
                if !stepContainers.isEmpty() {
                    print("✅ Найдены контейнеры шагов: \(stepContainers.count)")
                    
                    var stepNumber = 0
                    
                    for container in stepContainers {
                        // Извлекаем заголовок шага
                        let stepHeader = try container.select("h2").first()?.text() ?? ""
                        
                        // Извлекаем текст шага из всех параграфов
                        let paragraphs = try container.select("p")
                        var stepText = ""
                        
                        for paragraph in paragraphs {
                            let text = try paragraph.text().trimmingCharacters(in: .whitespacesAndNewlines)
                            if !text.isEmpty {
                                if !stepText.isEmpty {
                                    stepText += " "
                                }
                                stepText += text
                            }
                        }
                        
                        // Извлекаем изображение шага
                        let stepImage = try container.select("figure img").first()
                        let imageUrl = try stepImage?.attr("src")
                        
                        // Пропускаем шаг, если это описание (нет изображения и текст слишком общий)
                        let isDescriptionStep = imageUrl == nil &&
                            (stepText.lowercased().contains("осенью") ||
                             stepText.lowercased().contains("зимой") ||
                             stepText.count > 200) // Длинный текст вероятно описание
                        
                        if !stepText.isEmpty && !isDescriptionStep {
                            stepNumber += 1
                            
                            // Убираем "Шаг X" из текста если есть
                            var cleanStepText = stepText
                            if stepHeader.lowercased().contains("шаг") {
                                // Оставляем только чистый текст без заголовка шага
                                cleanStepText = stepText.replacingOccurrences(of: stepHeader, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                            
                            let instruction = InstructionStep(
                                stepNumber: stepNumber,
                                text: cleanStepText,
                                imageUrl: imageUrl
                            )
                            instructions.append(instruction)
                            
                            print("👨‍🍳 Шаг \(stepNumber): \(cleanStepText.prefix(50))...")
                            print("🖼️ Изображение: \(imageUrl ?? "нет")")
                        } else if isDescriptionStep {
                            print("⏩ Пропускаем шаг-описание: \(stepText.prefix(50))...")
                        }
                    }
                    
                    if !instructions.isEmpty {
                        return instructions
                    }
                }
            } catch {
                print("❌ Ошибка парсинга инструкций через _editorjsContent: \(error)")
            }
        
        // Способ 2: Ищем по другим селекторам
        let instructionSelectors = [
            ".recipe-step",
            ".cooking-step",
            ".instruction-step",
            "[data-step]"
        ]
        
        for selector in instructionSelectors {
            do {
                let elements = try document.select(selector)
                if !elements.isEmpty() {
                    print("✅ Найден селектор инструкций: \(selector), элементов: \(elements.count)")
                    
                    for (index, element) in elements.enumerated() {
                        let text = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { continue }
                        
                        let instruction = InstructionStep(
                            stepNumber: index + 1,
                            text: text,
                            imageUrl: nil
                        )
                        instructions.append(instruction)
                    }
                    
                    if !instructions.isEmpty {
                        return instructions
                    }
                }
            } catch {
                print("❌ Ошибка парсинга инструкций для селектора \(selector): \(error)")
                continue
            }
        }
        
        print("❌ Не найдены инструкции")
        return []
    }
    
    // MARK: - Парсинг основной информации
    private static func parseModernTitle(from document: Document) -> String {
        let titleSelectors = [
            "h1._title_1e2lm_19",
            "h1.recipe-title",
            "h1",
            ".recipe-title",
            "[data-title]"
        ]
        
        for selector in titleSelectors {
            do {
                if let title = try document.select(selector).first()?.text(),
                   !title.isEmpty {
                    return title.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } catch {
                continue
            }
        }
        
        return "Без названия"
    }
    
    private static func parseModernDescription(from document: Document) -> String? {
        let descriptionSelectors = [
            "._description_1e2lm_33",
            ".recipe-description",
            ".description",
            "[data-description]"
        ]
        
        for selector in descriptionSelectors {
            do {
                if let description = try document.select(selector).first()?.text(),
                   !description.isEmpty {
                    return description.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } catch {
                continue
            }
        }
        
        return nil
    }
    
    private static func parseModernMainImage(from document: Document) -> String? {
        let imageSelectors = [
            "._image_1e2lm_9 img",
            ".recipe-image img",
            ".main-image img",
            "meta[property=og:image]"
        ]
        
        for selector in imageSelectors {
            do {
                if selector.contains("meta") {
                    if let imageUrl = try document.select(selector).first()?.attr("content"),
                       !imageUrl.isEmpty {
                        return imageUrl
                    }
                } else {
                    if let imageElement = try document.select(selector).first(),
                       let imageSrc = try? imageElement.attr("src"),
                       !imageSrc.isEmpty {
                        return imageSrc.hasPrefix("http") ? imageSrc : "https://www.gastronom.ru\(imageSrc)"
                    }
                }
            } catch {
                continue
            }
        }
        
        return nil
    }
    
    private static func parseModernTimeAndServings(from document: Document) -> (String?, String?) {
        var cookingTime: String?
        var servings: String?
        
        // Время приготовления
        let timeSelectors = [
            "._time_1e2lm_39",
            ".cooking-time",
            ".recipe-time",
            "[data-time]"
        ]
        
        for selector in timeSelectors {
            do {
                if let time = try document.select(selector).first()?.text(),
                   !time.isEmpty {
                    cookingTime = time.trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            } catch {
                continue
            }
        }
        
        // Количество порций
        let servingsSelectors = [
            "._portions_1e2lm_44",
            ".servings",
            ".recipe-yield",
            "[data-servings]"
        ]
        
        for selector in servingsSelectors {
            do {
                if let serving = try document.select(selector).first()?.text(),
                   !serving.isEmpty {
                    servings = serving.trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            } catch {
                continue
            }
        }
        
        return (cookingTime, servings)
    }
    
    // MARK: - Вспомогательные методы
    private static func extractRecipeId(from url: String) -> String {
        if let regex = try? NSRegularExpression(pattern: "/recipe/(\\d+)"),
           let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
           let range = Range(match.range(at: 1), in: url) {
            return String(url[range])
        }
        return UUID().uuidString
    }
}
