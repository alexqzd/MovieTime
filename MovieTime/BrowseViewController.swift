//
//  ViewController.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 14/02/22.
//

import UIKit

class BrowseViewController: UIViewController, BrowseViewDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    @IBOutlet weak var searchBar: UIView!
    
    @IBOutlet weak var contentSelectionButton: UIButton! // Button to switch content type at the top
    @IBOutlet var browseView: BrowseView!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var items = [IMBDItem]()
    
    var currentContent = ContentType.Movie // Content type to display (Movies / TV Shows)
    
    let imdbConnector = IMDBConnect.sharedInstance
    
    // MARK: - Header
    
    // Items to display on the content type selector button
    var menuItems: [UIAction] {
        return [
            UIAction(title: "Movies", image: UIImage(systemName: "video"), handler: { (_) in
                self.currentContent = .Movie
                Task {
                    await self.getPopularItems(contentType: self.currentContent)
                    self.browseView.IMDBItems = self.items
                    self.browseView.itemCollectionView.performBatchUpdates( // This will reload the collection view with teh default animation
                        {
                            self.browseView.itemCollectionView.reloadSections(IndexSet(integer: 0))
                        }, completion: { (finished:Bool) -> Void in
                        })
                }
            }),
            UIAction(title: "TV Shows", image: UIImage(systemName: "tv"), handler: { [self] (_) in
                self.currentContent = .TVShow
                Task {
                    await self.getPopularItems(contentType: self.currentContent)
                    self.browseView.IMDBItems = self.items
                    self.browseView.itemCollectionView.performBatchUpdates( // This will reload the collection view with teh default animation
                        {
                            self.browseView.itemCollectionView.reloadSections(IndexSet(integer: 0))
                        }, completion: { (finished:Bool) -> Void in
                        })
                }
            })
            
        ]
    }
    
    // Pop up menu for the content type selector button
    var contentMenu: UIMenu {
        return UIMenu(title: "What should we watch?", image: nil, identifier: nil, options: [], children: menuItems)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Configure the content type selector button (pop up menu)
        contentSelectionButton.menu = contentMenu
        contentSelectionButton.showsMenuAsPrimaryAction = true
        
        browseView.delegate = self
        
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.delegate = self
        //        searchController.searchBar.isTranslucent = true
        //        searchController.searchBar.alpha = 1
        //        searchController.searchBar.backgroundImage = UIImage()
        searchController.searchBar.backgroundColor = UIColor.clear
        searchBar.addSubview(searchController.searchBar)
        searchController.searchBar.autoresizingMask = .flexibleWidth
        
        self.navigationItem.titleView = searchController.searchBar
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(BrowseViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        // Load data from the API
        Task {
            await getPopularItems(contentType: currentContent)
            self.browseView.IMDBItems = self.items
            browseView.itemCollectionView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        // Delete stuff that we can fetch again later
        browseView.posterImagesForIMDBId.removeAll()
    }
    
    // Fetch the popular items from the API, handle any errors displaying them to the user
    func getPopularItems(contentType: ContentType) async {
        do {
            items = try await imdbConnector.getPopular(contentType: contentType)
        } catch {
            let alert = UIAlertController(title: "Error", message: "Unexpected error: \(error).", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in }))
            DispatchQueue.main.async{
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Item search
    func updateSearchResults(for searchController: UISearchController) {
        let searchTerm = searchController.searchBar.text ?? ""

        // We don't want to query the API until the user taps Search
        // because we have limited API calls (100 per day)

        if searchTerm.isEmpty {
            browseView.IMDBItems = items
        } else {
            browseView.IMDBItems = items.filter({ item in return item.title.contains(searchTerm) })
        }
        browseView.itemCollectionView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // Query the API
        Task {
            let results = try! await imdbConnector.search(query: searchBar.text ?? "")
            let items = results.map({$0.toPartialIMBDItem()})
            browseView.IMDBItems = items
            browseView.itemCollectionView.reloadData()
        }
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        //        mainPulleyVC.setDrawerPosition(position: .open, animated: true)
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        browseView.IMDBItems = items
        browseView.itemCollectionView.reloadData()
    }
    
    @objc func dismissKeyboard()
    {
        UIApplication.shared.sendAction(#selector(self.resignFirstResponder), to:nil, from:nil, for:nil)
    }
    
    // MARK: - Navigation
    
    func browseView(_ browseView: BrowseView, didSelectItemAt indexPath: IndexPath) {
        let senderCell = browseView.itemCollectionView.cellForItem(at: indexPath)
        performSegue(withIdentifier: "goToDetail", sender: senderCell)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetail" {
            if let destinationVC = segue.destination as? ItemDetailViewController,
               let cell = sender as? ImagePosterCollectionViewCell{
                destinationVC.item = cell.item
            }
        }
    }
    
}
