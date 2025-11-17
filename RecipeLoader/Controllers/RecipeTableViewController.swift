//
//  ViewController.swift
//  RecipeLoader
//
//  Created by user on 12.11.2025.
//
//

import UIKit

class RecipeTableViewController: UITableViewController {
    
    // MARK: - Properties
    private var recipes: [Recipe] = []
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var isLoading = false
    private var currentPage = 1
    private var hasMoreRecipes = true
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadRecipes()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "🍳 Povarenok.ru Рецепты"
        setupTableView()
        setupActivityIndicator()
        setupNavigationBar()
    }
    
    private func setupTableView() {
        tableView.register(RecipeTableViewCell.self, forCellReuseIdentifier: "RecipeCell")
        tableView.rowHeight = 100
        tableView.separatorStyle = .singleLine
    }
    
    private func setupActivityIndicator() {
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshRecipes)
        )
    }
    
    // MARK: - Data Loading
    @objc private func refreshRecipes() {
        currentPage = 1
        hasMoreRecipes = true
        recipes.removeAll()
        tableView.reloadData()
        loadRecipes()
    }
    
    private func loadRecipes(page: Int = 1) {
        guard !isLoading && (page == 1 || hasMoreRecipes) else { return }
        
        isLoading = true
        activityIndicator.startAnimating()
        
        let urlString = page == 1 ?
            "https://www.povarenok.ru/recipes/" :
            "https://www.povarenok.ru/recipes/~\(page)/"
        
        NetworkManager.shared.fetchHTML(from: urlString) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.isLoading = false
            }
            
            switch result {
            case .success(let html):
                let newRecipes = RecipeParser.parseRecipes(from: html, baseURL: "https://www.povarenok.ru")
                self.handleNewRecipes(newRecipes, page: page)
                
            case .failure(let error):
                self.showError(message: error.localizedDescription)
            }
        }
    }
    
    private func handleNewRecipes(_ newRecipes: [Recipe], page: Int) {
        DispatchQueue.main.async {
            if page == 1 {
                self.recipes = newRecipes
                self.tableView.reloadData()
            } else {
                let existingTitles = Set(self.recipes.map { $0.title })
                let uniqueRecipes = newRecipes.filter { !existingTitles.contains($0.title) }
                
                if !uniqueRecipes.isEmpty {
                    let startIndex = self.recipes.count
                    self.recipes.append(contentsOf: uniqueRecipes)
                    
                    let indexPaths = (startIndex..<self.recipes.count).map {
                        IndexPath(row: $0, section: 0)
                    }
                    self.tableView.insertRows(at: indexPaths, with: .automatic)
                }
            }
            
            self.currentPage = page
            self.hasMoreRecipes = !newRecipes.isEmpty
        }
    }
    
    // MARK: - Error Handling
    private func showError(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Ошибка",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - TableView DataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath) as! RecipeTableViewCell
        cell.configure(with: recipes[indexPath.row])
        return cell
    }
    
    // MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let recipe = recipes[indexPath.row]
        let detailVC = RecipeDetailViewController(recipe: recipe)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - Pagination
extension RecipeTableViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isLoading && hasMoreRecipes else { return }
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.frame.size.height
        
        guard contentHeight > scrollViewHeight else { return }
        
        if offsetY > contentHeight - scrollViewHeight - 500 {
            loadRecipes(page: currentPage + 1)
        }
    }
}
