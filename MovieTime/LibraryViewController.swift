//
//  File.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 16/02/22.
//

import UIKit

class LibraryViewController: UIViewController, BrowseViewDelegate, UIAdaptivePresentationControllerDelegate, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    @IBOutlet weak var favoritesToggleButton: UIButton!
    @IBOutlet weak var browseView: BrowseView!
    
    let imdb = IMDBConnect.sharedInstance
    var items = [IMBDItem]()
    
    @IBOutlet weak var searchBar: UIView!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var isDisplayingFavs = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        browseView.delegate = self
        favoritesToggleButton.setTitle("Show favorites", for: .normal)
        
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.backgroundColor = UIColor.clear
        searchBar.addSubview(searchController.searchBar)
        searchController.searchBar.autoresizingMask = .flexibleWidth
        
        self.navigationItem.titleView = searchController.searchBar
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(BrowseViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isDisplayingFavs {
            items = imdb.favorites.sorted(by: {$0.imdbID > $1.imdbID})
            favoritesToggleButton.setTitle("Show library", for: .normal)
        }
        else {
            items = imdb.getItemLibrary().sorted(by: {$0.dateAdded > $1.dateAdded}).map({$0.item})
            favoritesToggleButton.setTitle("Show favorites", for: .normal)
        }
        browseView.IMDBItems = items
        browseView.itemCollectionView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        // Delete stuff that we can fetch again later
        browseView.posterImagesForIMDBId.removeAll()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.dismiss(animated: true, completion: nil)  // Search will stay in view if we don't dismiss it
    }
    
    @objc func dismissKeyboard()
    {
        UIApplication.shared.sendAction(#selector(self.resignFirstResponder), to:nil, from:nil, for:nil)
    }
    
    @IBAction func favotitesToggleButtonTapped(_ sender: UIButton) {
        if isDisplayingFavs {
            items = imdb.getItemLibrary().sorted(by: {$0.dateAdded > $1.dateAdded}).map({$0.item})
            favoritesToggleButton.setTitle("Show favorites", for: .normal)
        } else {
            items = imdb.favorites.sorted(by: {$0.imdbID > $1.imdbID})
            favoritesToggleButton.setTitle("Show library", for: .normal)
        }
        isDisplayingFavs.toggle()
        browseView.IMDBItems = items
        browseView.itemCollectionView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchTerm = searchController.searchBar.text ?? ""

        if searchTerm.isEmpty {
            browseView.IMDBItems = items
        } else {
            browseView.IMDBItems = items.filter({ item in return item.title.contains(searchTerm) })
        }
        browseView.itemCollectionView.reloadData()
    }
    
    func browseView(_ browseView: BrowseView, didSelectItemAt indexPath: IndexPath) {
        let senderCell = browseView.itemCollectionView.cellForItem(at: indexPath)
        performSegue(withIdentifier: "goToDetailFromLibrary", sender: senderCell)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetailFromLibrary" {
            if let destinationVC = segue.destination as? ItemDetailViewController,
               let cell = sender as? ImagePosterCollectionViewCell {
                destinationVC.presentationController?.delegate = self
                destinationVC.item = cell.item
            }
        }
    }
    
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController)
    {
        // Only called when the sheet is dismissed by DRAGGING.
        // You'll need something extra if you call .dismiss() on the child.
        // (I found that overriding dismiss in the child and calling
        // presentationController.delegate?.presentationControllerDidDismiss
        // works well).
        
        if isDisplayingFavs {
            items = imdb.favorites.sorted(by: {$0.imdbID > $1.imdbID})
        }
        else {
            items = imdb.getItemLibrary().sorted(by: {$0.dateAdded > $1.dateAdded}).map({$0.item})
        }
        browseView.IMDBItems = items
        browseView.itemCollectionView.reloadData()
        
    }
    
}
