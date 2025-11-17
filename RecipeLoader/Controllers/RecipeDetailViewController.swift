//
//  RecipeDetailViewController.swift
//  RecipeLoader
//
//  Created by user on 13.11.2025.
//

import UIKit
import SwiftSoup

class RecipeDetailViewController: UIViewController {
    
    private var recipe: Recipe
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var activityIndicator: UIActivityIndicatorView!
    
    // UI элементы
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    private let descriptionLabel = UILabel()
    private let categoriesLabel = UILabel()
    private let ingredientsTitleLabel = UILabel()
    private let ingredientsStackView = UIStackView()
    private let instructionsTitleLabel = UILabel()
    private let instructionsStackView = UIStackView()
    private let nutritionTitleLabel = UILabel()
    private let nutritionStackView = UIStackView()
    private let tagsLabel = UILabel()
    private let infoLabel = UILabel()
    
    init(recipe: Recipe) {
        self.recipe = recipe
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        displayRecipe()
        loadDetailedRecipeIfNeeded()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Рецепт"
        
        // Настройка ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Индикатор загрузки
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        // Заголовок
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Изображение
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        // Описание
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.textColor = .systemOrange
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(infoLabel)
        
        // Категории
        categoriesLabel.font = UIFont.systemFont(ofSize: 14)
        categoriesLabel.numberOfLines = 0
        categoriesLabel.textColor = .systemBlue
        categoriesLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(categoriesLabel)
        
        // Ингредиенты
        setupSectionTitle(ingredientsTitleLabel, text: "🥕 Ингредиенты")
        contentView.addSubview(ingredientsTitleLabel)
        
        ingredientsStackView.axis = .vertical
        ingredientsStackView.spacing = 8
        ingredientsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ingredientsStackView)
        
        // Инструкции
        setupSectionTitle(instructionsTitleLabel, text: "👨‍🍳 Приготовление")
        contentView.addSubview(instructionsTitleLabel)
        
        instructionsStackView.axis = .vertical
        instructionsStackView.spacing = 16
        instructionsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(instructionsStackView)
        
        // Пищевая ценность
        setupSectionTitle(nutritionTitleLabel, text: "📊 Пищевая ценность")
        contentView.addSubview(nutritionTitleLabel)
        
        nutritionStackView.axis = .vertical
        nutritionStackView.spacing = 8
        nutritionStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nutritionStackView)
        
        // Теги
        tagsLabel.font = UIFont.systemFont(ofSize: 14)
        tagsLabel.numberOfLines = 0
        tagsLabel.textColor = .systemGray
        tagsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tagsLabel)
        
        // Изначально скрываем секции, которые появятся после загрузки
        ingredientsTitleLabel.isHidden = true
        instructionsTitleLabel.isHidden = true
        nutritionTitleLabel.isHidden = true
    }
    
    private func setupSectionTitle(_ label: UILabel, text: String) {
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.numberOfLines = 1
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Image
            imageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            infoLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Categories
            categoriesLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 12),
            categoriesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoriesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Ingredients
            ingredientsTitleLabel.topAnchor.constraint(equalTo: categoriesLabel.bottomAnchor, constant: 24),
            ingredientsTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            ingredientsTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            ingredientsStackView.topAnchor.constraint(equalTo: ingredientsTitleLabel.bottomAnchor, constant: 12),
            ingredientsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            ingredientsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Instructions
            instructionsTitleLabel.topAnchor.constraint(equalTo: ingredientsStackView.bottomAnchor, constant: 24),
            instructionsTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            instructionsTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            instructionsStackView.topAnchor.constraint(equalTo: instructionsTitleLabel.bottomAnchor, constant: 12),
            instructionsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            instructionsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Nutrition
            nutritionTitleLabel.topAnchor.constraint(equalTo: instructionsStackView.bottomAnchor, constant: 24),
            nutritionTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nutritionTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            nutritionStackView.topAnchor.constraint(equalTo: nutritionTitleLabel.bottomAnchor, constant: 12),
            nutritionStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nutritionStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Tags
            tagsLabel.topAnchor.constraint(equalTo: nutritionStackView.bottomAnchor, constant: 24),
            tagsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tagsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tagsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func displayRecipe() {
        titleLabel.text = recipe.title
        
        // Загрузка основного изображения
        if let imageUrl = recipe.imageUrl {
            loadImage(from: imageUrl)
        } else {
            imageView.image = UIImage(systemName: "fork.knife.circle")?
                .withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        }
        
        // Описание
        descriptionLabel.text = recipe.description ?? "Описание отсутствует"
        
        updateAdditionalInfo()

        
        // Категории
        if let categories = recipe.categories, !categories.isEmpty {
            categoriesLabel.text = "📁 " + categories.joined(separator: " • ")
        } else {
            categoriesLabel.isHidden = true
        }
        
        // Теги
        if let tags = recipe.tags, !tags.isEmpty {
            tagsLabel.text = "🏷️ " + tags.joined(separator: " • ")
        } else {
            tagsLabel.isHidden = true
        }
        
        // Если у нас уже есть детальная информация, отображаем ее
        if recipe.isDetailed {
            displayDetailedInfo()
        }
    }
    
    private func updateAdditionalInfo() {
        var additionalInfo: [String] = []
        
        if let cookingTime = recipe.cookingTime {
            additionalInfo.append("⏱ \(cookingTime)")
        }
        
        if let servings = recipe.servings {
            additionalInfo.append("🍽 \(servings)")
        }
        
        if let cuisine = recipe.cuisine {
            additionalInfo.append("🏺 \(cuisine)")
        }
        
        if !additionalInfo.isEmpty {
            infoLabel.text = additionalInfo.joined(separator: " • ")
            infoLabel.isHidden = false
        } else {
            infoLabel.isHidden = true
        }
    }
    
    private func displayDetailedInfo() {
        // Показываем секции, которые были скрыты
        ingredientsTitleLabel.isHidden = false
        instructionsTitleLabel.isHidden = false
        nutritionTitleLabel.isHidden = false
        
        // Ингредиенты
        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
            displayIngredients(ingredients)
        } else {
            ingredientsTitleLabel.isHidden = true
        }
        
        // Инструкции
        if let instructions = recipe.instructions, !instructions.isEmpty {
            displayInstructions(instructions)
        } else {
            instructionsTitleLabel.isHidden = true
        }
        
        // Пищевая ценность
        if let nutrition = recipe.nutrition {
            displayNutrition(nutrition)
        } else {
            nutritionTitleLabel.isHidden = true
        }
    }
  
    private func loadDetailedRecipeIfNeeded() {
        // Если у нас уже есть детальная информация, не загружаем повторно
        guard !recipe.isDetailed else { return }
        
        activityIndicator.startAnimating()
        
        guard let url = URL(string: recipe.url) else {
            activityIndicator.stopAnimating()
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            
            guard let data = data,
                  let html = String(data: data, encoding: .windowsCP1251) else {
                print("❌ Не удалось загрузить детальную страницу")
                return
            }
            
            if let detailedRecipe = RecipeDetailParser.parseDetailedRecipe(from: html, url: self.recipe.url) {
                DispatchQueue.main.async {
                    self.recipe = detailedRecipe
                    // ОБНОВЛЯЕМ ВСЮ ИНФОРМАЦИЮ
                    self.updateAdditionalInfo()
                    self.displayDetailedInfo()
                    print("✅ Обновлен интерфейс с детальной информацией для: \(detailedRecipe.title)")
                }
            }
        }
        task.resume()
    }

    private func displayIngredients(_ ingredients: [Ingredient]) {
        ingredientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for ingredient in ingredients {
            let ingredientView = createIngredientView(ingredient)
            ingredientsStackView.addArrangedSubview(ingredientView)
        }
    }
    
    private func createIngredientView(_ ingredient: Ingredient) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.textColor = .label
        nameLabel.text = ingredient.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let amountLabel = UILabel()
        amountLabel.font = UIFont.boldSystemFont(ofSize: 16)
        amountLabel.textColor = .systemGreen
        amountLabel.text = ingredient.amount
        amountLabel.textAlignment = .right
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(nameLabel)
        container.addSubview(amountLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            
            amountLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            amountLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            amountLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 100),
            
            container.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return container
    }
    
    private func displayInstructions(_ instructions: [InstructionStep]) {
        instructionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, instruction) in instructions.enumerated() {
            let instructionView = createInstructionView(instruction, stepNumber: index + 1)
            instructionsStackView.addArrangedSubview(instructionView)
        }
    }
    
    private func createInstructionView(_ instruction: InstructionStep, stepNumber: Int) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .top
        
        // Номер шага
        let numberLabel = UILabel()
        numberLabel.font = UIFont.boldSystemFont(ofSize: 16)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .center
        numberLabel.backgroundColor = .systemBlue
        numberLabel.layer.cornerRadius = 12
        numberLabel.clipsToBounds = true
        numberLabel.text = "\(stepNumber)"
        numberLabel.widthAnchor.constraint(equalToConstant: 24).isActive = true
        numberLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        // Текст инструкции
        let textLabel = UILabel()
        textLabel.font = UIFont.systemFont(ofSize: 16)
        textLabel.textColor = .label
        textLabel.numberOfLines = 0
        textLabel.text = instruction.text
        
        container.addArrangedSubview(numberLabel)
        container.addArrangedSubview(textLabel)
        
        // Если есть изображение шага
        if let stepImageUrl = instruction.imageUrl {
            let stepImageView = UIImageView()
            stepImageView.contentMode = .scaleAspectFill
            stepImageView.clipsToBounds = true
            stepImageView.layer.cornerRadius = 8
            stepImageView.backgroundColor = .systemGray6
            stepImageView.translatesAutoresizingMaskIntoConstraints = false
            stepImageView.heightAnchor.constraint(equalToConstant: 120).isActive = true
            
            loadImage(from: stepImageUrl, into: stepImageView)
            
            let imageContainer = UIStackView()
            imageContainer.axis = .vertical
            imageContainer.spacing = 8
            imageContainer.addArrangedSubview(container)
            imageContainer.addArrangedSubview(stepImageView)
            
            return imageContainer
        }
        
        return container
    }
    
    private func displayNutrition(_ nutrition: NutritionInfo) {
        nutritionStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let nutritionItems = [
            ("🔥 Калории", nutrition.calories),
            ("💪 Белки", nutrition.protein),
            ("🥑 Жиры", nutrition.fat),
            ("🌾 Углеводы", nutrition.carbohydrates)
        ]
        
        for (title, value) in nutritionItems {
            let nutritionView = createNutritionView(title: title, value: value)
            nutritionStackView.addArrangedSubview(nutritionView)
        }
        
        // Добавим значения на 100г, если есть
        if !nutrition.caloriesPer100g.isEmpty {
            let per100gLabel = UILabel()
            per100gLabel.font = UIFont.systemFont(ofSize: 14)
            per100gLabel.textColor = .systemGray
            per100gLabel.text = "На 100г: \(nutrition.caloriesPer100g) ккал"
            nutritionStackView.addArrangedSubview(per100gLabel)
        }
    }
    
    private func createNutritionView(title: String, value: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = .label
        titleLabel.text = title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.font = UIFont.boldSystemFont(ofSize: 16)
        valueLabel.textColor = .systemGreen
        valueLabel.text = value
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return container
    }
    
    private func loadImage(from urlString: String, into imageView: UIImageView? = nil) {
        guard let url = URL(string: urlString) else { return }
        
        let targetImageView = imageView ?? self.imageView
        
        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try Data(contentsOf: url)
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        UIView.transition(with: targetImageView,
                                        duration: 0.3,
                                        options: .transitionCrossDissolve,
                                        animations: {
                                            targetImageView.image = image
                                        },
                                        completion: nil)
                    }
                }
            } catch {
                print("❌ Ошибка загрузки изображения: \(error)")
            }
        }
    }
}
