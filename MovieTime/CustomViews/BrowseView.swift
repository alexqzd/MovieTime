//
//  BrowseView.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 16/02/22.
//

import UIKit

class BrowseView: UIView, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {

    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var itemCollectionView: UICollectionView!
    
    private let cellReuseIdentifier = "MovieCell"
    
    private let itemsPerRow: CGFloat = 3
    
    @IBOutlet weak var statusLabel: UILabel!
    
    var IMDBItems = [IMDBItem]()
    var posterImagesForIMDBId: [String: UIImage] = [:]
    
    var delegate: BrowseViewDelegate?
    
    // Collection padding
    private let sectionInsets = UIEdgeInsets(
        top: 0.0,
        left: 20.0,
        bottom: 0.0,
        right: 20.0)

    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init? (coder aDecoder: NSCoder) { // for using CustomView in IB
        super.init(coder:aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        // Configure the collection view
        
        Bundle.main.loadNibNamed("BrowseView",owner:self,options:nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        itemCollectionView.prefetchDataSource = self
        itemCollectionView.dataSource = self
        itemCollectionView.delegate = self
        let nibCell = UINib(nibName: "ImagePosterCollectionViewCell", bundle: nil)
        itemCollectionView.register(nibCell, forCellWithReuseIdentifier: cellReuseIdentifier)
        
        statusLabel.isHidden = false
        statusLabel.text = "Loading..."
    }
    
    // MARK: - Collection view data source and delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,numberOfItemsInSection section: Int) -> Int {
        if IMDBItems.count > 0 {
            statusLabel.isHidden = true
        } else {
            statusLabel.isHidden = false
            statusLabel.text = "Nothing here..."
        }
        return IMDBItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView,cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell( withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! ImagePosterCollectionViewCell // Get the cell
        let movie = IMDBItems[indexPath.item] // Get the movie at the current index
        cell.item = movie
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
        let movieCell = cell as! ImagePosterCollectionViewCell
        
        // Check if the poster is actually being displayed,
        // otherwise a race condidion may cause the image to be saved but not displayed
        if movieCell.moviePosterImageView.image != nil { return }
        Task {
            if let posterImage = try? await movie.thumbnailPoster.fetch() {
                posterImagesForIMDBId[movie.imdbID] = posterImage
                collectionView.reloadItems(at: [indexPath])
            }
        }
    }
    
    // Prefetch the poster image that iOS thinks will be displayed
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let movie = IMDBItems[indexPath.item]
            if posterImagesForIMDBId[movie.imdbID] != nil { return }
            Task {
                if let posterImage = try? await movie.thumbnailPoster.fetch() {
                    posterImagesForIMDBId[movie.imdbID] = posterImage
                }
            }
        }
    }
    
    // MARK: - Collection View Flow Layout Delegate
    
    // Set the size of the cells based on the items per row
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = self.frame.width - paddingSpace
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.browseView(self, didSelectItemAt: indexPath)
    }
    

}


protocol BrowseViewDelegate {
    
    func browseView(_ browseView: BrowseView, didSelectItemAt indexPath: IndexPath)
    
}
