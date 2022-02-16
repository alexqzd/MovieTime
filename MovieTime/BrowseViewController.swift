//
//  ViewController.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 14/02/22.
//

import UIKit

class BrowseViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
    
    @IBOutlet weak var contentSelectionButton: UIButton! // Button to switch content type at the top
    @IBOutlet var browseCollectionView: UICollectionView!
    private let cellReuseIdentifier = "MovieCell"
    var currentContent = ContentType.Movie // Content type to display (Movies / TV Shows)
    private let itemsPerRow: CGFloat = 3
    
    var IMDBItems = [IMBDItem]()
    var posterImagesForIMDBId: [String: UIImage] = [:]
    
    let imdbConnector = IMDBConnect()
    
    // Collection padding
    private let sectionInsets = UIEdgeInsets(
        top: 0.0,
        left: 20.0,
        bottom: 0.0,
        right: 20.0)
    
    
    // Items to display on the content type selector button
    var menuItems: [UIAction] {
        return [
            UIAction(title: "Movies", image: UIImage(systemName: "video"), handler: { (_) in
                self.currentContent = .Movie
                Task {
                    self.IMDBItems = try! await self.imdbConnector.getPopular(contentType: self.currentContent)
                    self.browseCollectionView.performBatchUpdates( // This will reload the collection view with teh default animation
                        {
                            self.browseCollectionView.reloadSections(IndexSet(integer: 0))
                        }, completion: { (finished:Bool) -> Void in
                        })
                }
            }),
            UIAction(title: "TV Shows", image: UIImage(systemName: "tv"), handler: { [self] (_) in
                self.currentContent = .TVShow
                Task {
                    self.IMDBItems = try! await self.imdbConnector.getPopular(contentType: self.currentContent)
                    self.browseCollectionView.performBatchUpdates( // This will reload the collection view with teh default animation
                        {
                            self.browseCollectionView.reloadSections(IndexSet(integer: 0))
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
        
        // Configure the collection view
        browseCollectionView.prefetchDataSource = self
        browseCollectionView.dataSource = self
        browseCollectionView.delegate = self

        // Load data from the API
        Task {
            IMDBItems = try! await imdbConnector.getPopular(contentType: currentContent)
            browseCollectionView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        // Delete stuff that we can fetch again later
        posterImagesForIMDBId.removeAll()
    }
    
    // MARK: - Collection view data source and delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,numberOfItemsInSection section: Int) -> Int {
        return IMDBItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView,cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell( withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! MoviePosterCell // Get the cell
        let movie = IMDBItems[indexPath.item] // Get the movie at the current index
        cell.movieTitleLabel.text = movie.title

        // If we have the poster image, set it
        if let posterImage = posterImagesForIMDBId[movie.imdbID] {
            cell.movieTitleLabel.isHidden = true
            cell.moviePosterImageView.image = posterImage
            cell.backgroundColor = UIColor.clear
        } else { // Else, show the title as placeholder. We will fetch the poster at collectionView(_:willDisplay:forItemAt:)
            cell.movieTitleLabel.isHidden = false
            cell.backgroundColor = UIColor.lightGray
            cell.moviePosterImageView.image = nil
        }
        return cell
    }
    
    // Fetch the poster image for the cell about to be displayed, don't fetch it if we already have it
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let movie = IMDBItems[indexPath.item]
        let movieCell = cell as! MoviePosterCell
        
        // Check if the poster is actually being displayed,
        // otherwise a race condidion may cause the image to be saved but not displayed
        if movieCell.moviePosterImageView.image != nil { return }
        Task {
            let posterImage = try! await movie.fetchPoster()
                posterImagesForIMDBId[movie.imdbID] = posterImage
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    // Prefetch the poster image that iOS thinks will be displayed
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let movie = IMDBItems[indexPath.item]
            if posterImagesForIMDBId[movie.imdbID] != nil { return }
            Task {
                let posterImage = try! await movie.fetchPoster()
                    posterImagesForIMDBId[movie.imdbID] = posterImage
            }}
    }
    
    // MARK: - Collection View Flow Layout Delegate

    // Set the size of the cells based on the items per row
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem*1.4889815366) // 1.4889815366 is the aspect ratio of the poster images
    }
    
    // Set the inset for the section
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // Set the line spacing for the section
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
}

enum ContentType {
    case Movie
    case TVShow
}
