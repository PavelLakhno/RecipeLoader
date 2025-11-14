//
//  ViewController.swift
//  RecipeLoader
//
//  Created by user on 12.11.2025.
//
//

import UIKit
import SwiftSoup

class RecipeTableViewController: UITableViewController {
    
    private var recipes: [Recipe] = []
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPovarenokRecipes()
    }
    
    private func setupUI() {
        title = "🍳 Povarenok.ru Рецепты"
        tableView.register(RecipeTableViewCell.self, forCellReuseIdentifier: "RecipeCell")
        tableView.rowHeight = 100
        tableView.separatorStyle = .singleLine
        
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(loadPovarenokRecipes)
        )
    }
    
    @objc private func loadPovarenokRecipes() {
        activityIndicator.startAnimating()
        recipes.removeAll()
        tableView.reloadData()
        
        // Используем правильный URL для получения свежих рецептов
        let urlString = "https://www.povarenok.ru/recipes/?sort=date_create&order=desc"
        
        guard let url = URL(string: urlString) else {
            showErrorData()
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            
            if let error = error {
                print("❌ Ошибка сети: \(error.localizedDescription)")
                self.showErrorData()
                return
            }
            
            guard let data = data,
                  let html = String(data: data, encoding: .windowsCP1251) else {
                print("❌ Не удалось декодировать HTML")
                self.showErrorData()
                return
            }
            
            print("✅ Загружено HTML: \(html.count) символов")
            self.parsePovarenokRecipes(html)
        }
        task.resume()
    }
//    @objc private func loadPovarenokRecipes() {
//        activityIndicator.startAnimating()
//        recipes.removeAll()
//        tableView.reloadData()
//        
//        let url = URL(string: "https://www.povarenok.ru/")!
//        
//        var request = URLRequest(url: url)
//        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
//        request.timeoutInterval = 15
//        
//        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//            guard let self = self else { return }
//            
//            DispatchQueue.main.async {
//                self.activityIndicator.stopAnimating()
//            }
//            
//            if let error = error {
//                print("❌ Ошибка сети: \(error.localizedDescription)")
//                self.showErrorData()
//                return
//            }
//            
//            guard let data = data,
//                  let html = String(data: data, encoding: .windowsCP1251) else {
//                print("❌ Не удалось декодировать HTML")
//                self.showErrorData()
//                return
//            }
//            
//            print("✅ Загружено HTML: \(html.count) символов")
//            self.parsePovarenokRecipes(html)
//        }
//        task.resume()
//    }
    //MARK: New
    private func parsePovarenokRecipes(_ html: String) {
        do {
            let document = try SwiftSoup.parse(html)
            var parsedRecipes: [Recipe] = []
            var seenTitles = Set<String>()
            
            print("🔍 Начинаем улучшенный парсинг списка рецептов...")
            
            // Используем правильную ссылку для получения свежих рецептов
            let recipeElements = try document.select("article.item-bl")
            print("📊 Найдено элементов article.item-bl: \(recipeElements.count)")
            
            for element in recipeElements.prefix(15) { // Увеличим до 15
                do {
                    // Заголовок и ссылка
                    let titleLink = try element.select("h2 a").first()
                    let title = try titleLink?.text() ?? ""
                    let href = try titleLink?.attr("href") ?? ""
                    
                    guard !title.isEmpty, !href.isEmpty,
                          !seenTitles.contains(title) else { continue }
                    
                    seenTitles.insert(title)
                    
                    // Основное изображение
                    let imageElement = try element.select(".m-img img").first()
                    let imageSrc = try imageElement?.attr("src") ?? ""
                    let imageUrl = imageSrc.hasPrefix("http") ? imageSrc : "https:\(imageSrc)"
                    
                    // ОПИСАНИЕ - исправленный парсинг
                    let description = try extractCorrectDescription(from: element)
                    
                    // КАТЕГОРИИ
                    let categories = try extractCategories(from: element)
                    
                    // ТЕГИ
                    let tags = try extractTagsFromList(from: element)
                    
                    // ВРЕМЯ и ПОРЦИИ (попробуем найти в списке)
                    let (cookingTime, servings) = try extractTimeAndServings(from: element)
                    
                    let recipe = Recipe(
                        title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                        source: "Povarenok.ru",
                        url: href.hasPrefix("http") ? href : "https://www.povarenok.ru\(href)",
                        imageUrl: imageUrl.isEmpty ? nil : imageUrl,
                        description: description,
                        categories: categories,
                        tags: tags,
                        cookingTime: cookingTime,
                        servings: servings
                    )
                    
                    parsedRecipes.append(recipe)
                    print("✅ Добавлен рецепт: \(title)")
                    
                } catch {
                    print("❌ Ошибка парсинга элемента: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                if parsedRecipes.isEmpty {
                    self.showErrorData()
                } else {
                    self.recipes = parsedRecipes
                    self.tableView.reloadData()
                    print("✅ Успешно загружено \(parsedRecipes.count) рецептов")
                    
                    // Статистика
                    let withImages = parsedRecipes.filter { $0.imageUrl != nil }.count
                    let withDescriptions = parsedRecipes.filter { $0.description?.isEmpty == false }.count
                    print("📊 Статистика: \(withImages) с изображениями, \(withDescriptions) с описаниями")
                }
            }
            
        } catch {
            print("❌ Ошибка парсинга: \(error)")
            showErrorData()
        }
    }
    
    private func extractCorrectDescription(from element: Element) throws -> String? {
        // Пробуем разные стратегии для нахождения правильного описания
        
        // Стратегия 1: Ищем параграф после article-breadcrumbs
        if let breadcrumbs = try? element.select(".article-breadcrumbs").first(),
           let nextParagraph = try? breadcrumbs.nextElementSibling(),
           nextParagraph.tagName() == "p" {
            let description = try nextParagraph.text()
            if !description.isEmpty && description.count > 20 {
                return description.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Стратегия 2: Ищем любой параграф в элементе, но исключаем теги и категории
        let paragraphs = try element.select("p")
        for paragraph in paragraphs {
            let text = try paragraph.text().trimmingCharacters(in: .whitespacesAndNewlines)
            // Исключаем текст, который содержит слова связанные с категориями, тегами и т.д.
            if !text.isEmpty &&
               text.count > 20 &&
               text.count < 300 &&
               !text.lowercased().contains("категория:") &&
               !text.lowercased().contains("ингредиенты:") &&
               !text.lowercased().contains("теги:") &&
               !text.lowercased().contains("назначение:") {
                return text
            }
        }
        
        return nil
    }
    
    // Метод для извлечения категорий
    private func extractCategories(from element: Element) throws -> [String] {
        let categoryLinks = try element.select(".article-breadcrumbs a")
        var categories: [String] = []
        
        for link in categoryLinks {
            let category = try link.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if !category.isEmpty {
                categories.append(category)
            }
        }
        
        return categories
    }

    // Метод для извлечения тегов из списка
    private func extractTagsFromList(from element: Element) throws -> [String] {
        let tagElements = try element.select(".article-tags .tab-content a")
        var tags: [String] = []
        
        for tagElement in tagElements {
            let tag = try tagElement.text().trimmingCharacters(in: .whitespacesAndNewlines)
            if !tag.isEmpty {
                tags.append(tag)
            }
        }
        
        return tags
    }

    // Метод для извлечения времени и порций
//    private func extractTimeAndServings(from element: Element) throws -> (String?, String?) {
//        var cookingTime: String?
//        var servings: String?
//        
//        // Пробуем найти в быстром просмотре ингредиентов
//        let ingredientText = try element.select(".ingr_fast").text()
//        let timePattern = "\\d+\\s*мин"
//        let servingsPattern = "\\d+\\s*порц"
//        
//        if let timeRange = ingredientText.range(of: timePattern, options: .regularExpression) {
//            cookingTime = String(ingredientText[timeRange])
//        }
//        
//        if let servingsRange = ingredientText.range(of: servingsPattern, options: .regularExpression) {
//            servings = String(ingredientText[servingsRange])
//        }
//        
//        return (cookingTime, servings)
//    }
    private func extractTimeAndServings(from element: Element) throws -> (String?, String?) {
        var cookingTime: String?
        var servings: String?
        
        // Стратегия 1: Ищем в тексте элемента
        let elementText = try element.text()
        
        // Время приготовления (ищем паттерны: "40 минут", "1 час", "30 мин" и т.д.)
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
        
        // Количество порций (ищем паттерны: "4 порции", "2 порции", "6 порций" и т.д.)
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
        cookingTime = cookingTime?.replacingOccurrences(of: "PT", with: "")
            .replacingOccurrences(of: "M", with: " мин")
            .replacingOccurrences(of: "H", with: " час")
        
        return (cookingTime, servings)
    }
    


    // ОБНОВЛЕННЫЙ метод поиска изображений
    private func extractImageUrl(from link: Element, document: Document) -> String? {
        do {
            // Стратегия 1: Ищем изображение рядом со ссылкой в DOM
            if let parent = link.parent() {
                // Ищем изображение в том же контейнере
                if let img = try? parent.select("img").first() {
                    let src = try img.attr("src")
                    if isValidImageUrl(src) {
                        return src.hasPrefix("http") ? src : "https:\(src)"
                    }
                }
                
                // Ищем в соседних элементах
                if let nextSibling = try? parent.nextElementSibling() {
                    if let img = try? nextSibling.select("img").first() {
                        let src = try img.attr("src")
                        if isValidImageUrl(src) {
                            return src.hasPrefix("http") ? src : "https:\(src)"
                        }
                    }
                }
            }
            
            // Стратегия 2: Ищем по структуре данных (data-cache)
            let images = try document.select("img[src*='/data/cache/']")
            for img in images {
                let src = try img.attr("src")
                let alt = try img.attr("alt")
                // Если alt содержит название рецепта - это наше изображение
                if alt.contains(try link.text()) && isValidImageUrl(src) {
                    return src.hasPrefix("http") ? src : "https:\(src)"
                }
            }
            
            // Стратегия 3: Ищем изображения с определенными размерами (превью рецептов)
            let recipeImages = try document.select("img[src*='-300x0.jpg'], img[src*='-250x0.jpg'], img[src*='-200x0.jpg']")
            for img in recipeImages {
                let src = try img.attr("src")
                if isValidImageUrl(src) {
                    // Проверяем, находится ли изображение рядом с нашей ссылкой
                    if let parent = img.parent(),
                       try parent.html().contains(try link.attr("href")) {
                        return src.hasPrefix("http") ? src : "https:\(src)"
                    }
                }
            }
            
        } catch {
            print("Ошибка при извлечении изображения: \(error)")
        }
        
        return nil
    }

    // Проверка валидности URL изображения
    private func isValidImageUrl(_ url: String) -> Bool {
        return !url.isEmpty &&
               !url.contains("icon") &&
               !url.contains("logo") &&
               (url.hasSuffix(".jpg") || url.hasSuffix(".jpeg") || url.hasSuffix(".png"))
    }

    
//    private func extractDescription(from link: Element) -> String {
//        do {
//            // Пробуем найти описание в родительских элементах
//            var currentElement: Element? = link.parent()
//            var attempts = 0
//            
//            while let element = currentElement, attempts < 3 {
//                let elementText = try element.text()
//                let linkText = try link.text()
//                
//                // Ищем текст после названия рецепта
//                if let range = elementText.range(of: linkText) {
//                    let afterTitle = String(elementText[range.upperBound...])
//                    let sentences = afterTitle.components(separatedBy: ".")
//                    if let firstSentence = sentences.first?
//                        .trimmingCharacters(in: .whitespacesAndNewlines),
//                       firstSentence.count > 10 {
//                        
//                        let cleanDescription = firstSentence
//                            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
//                        
//                        if cleanDescription.count > 15 && cleanDescription.count < 150 {
//                            return String(cleanDescription.prefix(120)) + "..."
//                        }
//                    }
//                }
//                
//                currentElement = element.parent()
//                attempts += 1
//            }
//        } catch {
//            print("Ошибка при извлечении описания: \(error)")
//        }
//        
//        return "Вкусный рецепт с подробным описанием приготовления"
//    }
    
    private func showErrorData() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Ошибка загрузки",
                message: "Не удалось загрузить рецепты. Проверьте подключение к интернету.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            
            self.recipes = self.getMockRecipes()
            self.tableView.reloadData()
        }
    }
    
    private func getMockRecipes() -> [Recipe] {
        return [
            Recipe(
                title: "Курица в сливочном соусе по-тоскански",
                source: "Povarenok.ru",
                url: "https://www.povarenok.ru/recipes/show/12345/",
                imageUrl: nil,
                description: "Нежная курица в сливочном соусе с итальянскими травами"
            ),
            Recipe(
                title: "Фрикадельки в тыквенном соусе",
                source: "Povarenok.ru",
                url: "https://www.povarenok.ru/recipes/show/12346/",
                imageUrl: nil,
                description: "Ароматные мясные фрикадельки в нежном тыквенном соусе"
            ),
            Recipe(
                title: "Дрожжевые ванильные булочки",
                source: "Povarenok.ru",
                url: "https://www.povarenok.ru/recipes/show/12347/",
                imageUrl: nil,
                description: "Пышные домашние булочки с ванильным ароматом"
            )
        ]
    }
    
    // MARK: - TableView Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath) as! RecipeTableViewCell
        cell.configure(with: recipes[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let recipe = recipes[indexPath.row]
        
        // Создаем и показываем детальный экран
        let detailVC = RecipeDetailViewController(recipe: recipe)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func loadDetailedRecipe(from url: String, completion: @escaping (Recipe?) -> Void) {
        guard let recipeUrl = URL(string: url) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: recipeUrl)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let html = String(data: data, encoding: .windowsCP1251) else {
                completion(nil)
                return
            }
            
            let detailedRecipe = RecipeDetailParser.parseDetailedRecipe(from: html, url: url)
            completion(detailedRecipe)
        }
        task.resume()
    }
}

// Вспомогательное свойство для проверки типа рецепта
extension Recipe {
    var isDetailed: Bool {
        return id != nil && ingredients != nil
    }
}
