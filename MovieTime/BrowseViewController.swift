//
//  ViewController.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 14/02/22.
//

import UIKit

class BrowseViewController: UIViewController, BrowseViewDelegate {
    
    @IBOutlet weak var contentSelectionButton: UIButton! // Button to switch content type at the top
    @IBOutlet var browseView: BrowseView!

    var currentContent = ContentType.Movie // Content type to display (Movies / TV Shows)
    
    let imdbConnector = IMDBConnect()
    
    // Items to display on the content type selector button
    var menuItems: [UIAction] {
        return [
            UIAction(title: "Movies", image: UIImage(systemName: "video"), handler: { (_) in
                self.currentContent = .Movie
                Task {
                    await self.getPopularItems(contentType: self.currentContent)
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
        
        // Load data from the API
        Task {
            await getPopularItems(contentType: currentContent)
            browseView.itemCollectionView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        // Delete stuff that we can fetch again later
        browseView.posterImagesForIMDBId.removeAll()
    }
    
    func getPopularItems(contentType: ContentType) async {
        do {
            browseView.IMDBItems = try await imdbConnector.getPopular(contentType: contentType)
        } catch {
            let alert = UIAlertController(title: "Error", message: "Unexpected error: \(error).", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in }))
            DispatchQueue.main.async{
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
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
