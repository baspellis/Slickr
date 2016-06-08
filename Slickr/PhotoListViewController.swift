//
//  PhotoListViewController.swift
//  Slickr
//
//  Created by Bas Pellis on 07/06/16.
//  Copyright © 2016 WebComrades. All rights reserved.
//

import UIKit
import Alamofire

extension PhotoListViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if searchController.searchBar.text != "" {
            searchTimer?.invalidate()
            searchTimer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: #selector(updateSearch), userInfo: nil, repeats: false)
            
        }
        else {
            scrollToTop()
            tableView.reloadData()
        }
    }
}

struct PhotoList {
    var photos: [[[String: AnyObject]]] = []
    var page = 1
    var pages = 0
    
    func hasMore() -> Bool {
        return page < pages
    }
}

class PhotoListViewController: UITableViewController, UIViewControllerTransitioningDelegate {

    var recent = PhotoList()
    var search = PhotoList()
    
    let searchController = UISearchController(searchResultsController: nil)
    let transitioningController = PhotoTransitionController()
    var searchTimer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl?.addTarget(self, action: #selector(refresh), forControlEvents: .ValueChanged)

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchBar.tintColor = UIColor.whiteColor()
        tableView.tableHeaderView = searchController.searchBar

        scrollToTop()

        loadData(page: 1)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - TableView DataSource Methods

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return max(refreshControl!.refreshing ? 0 : 1, activePhotoList().photos.count)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if activePhotoList().photos.count == 0 {
            return 1
        }
        return max(1, activePhotoList().photos[section].count)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if activePhotoList().photos.count == 0 || activePhotoList().photos[indexPath.section].count == 0 {
            return tableView.dequeueReusableCellWithIdentifier("NoResults", forIndexPath: indexPath)
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Photo", forIndexPath: indexPath)

        if let photoCell = cell as? PhotoCell {
            let photo = activePhotoList().photos[indexPath.section][indexPath.row]
            photoCell.url = photoURL(photo)
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let photoList = activePhotoList()

        if !photoList.hasMore() {
            return
        }
        
        let lastSection = tableView.numberOfSections - 1
        let lastRow = tableView.numberOfRowsInSection(lastSection) - 1
        if indexPath.section == lastSection && indexPath.row == lastRow {
            if searchActive() {
                searchPhotos(searchController.searchBar.text!, page: photoList.page + 1)
            }
            else {
                loadData(page: photoList.page + 1)
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        dispatch_async(dispatch_get_main_queue(), {
            if let photoDetailViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoDetail") as? PhotoDetailViewController, photoCell = tableView.cellForRowAtIndexPath(indexPath) as? PhotoCell {
                photoDetailViewController.image = photoCell.photoImageView.image
                photoDetailViewController.transitioningDelegate = self
                self.transitioningController.sourceView = photoCell.photoImageView
                if self.searchController.active {
                    self.searchController.presentViewController(photoDetailViewController, animated: true, completion: nil)
                }
                else {
                    self.presentViewController(photoDetailViewController, animated: true, completion: nil)
                }
            }
        })
    }
    
    // MARK: - Transitioning Delegate Methods
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitioningController.isPresenting = true
        return transitioningController
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitioningController.isPresenting = false
        return transitioningController
    }
    
    // MARK: - Private Methods
    
    func refresh() {
        if searchActive() {
            searchPhotos(searchController.searchBar.text!, page: 1)
        }
        else {
            loadData(page: 1)
        }
    }

    func loadData(page page: Int) {
        performFetch(parameters: ["method": FlickrMethodPhotos, "page": String(page), "per_page": "10"], page: page)
    }
    
    func performFetch(parameters parameters: [String: String]?, page: Int) {
        refreshControl?.beginRefreshing()
        
        let allParameters : [String: String]
        if parameters != nil {
            allParameters = FlickrDefaultParameters.combinedWith(parameters!)
        }
        else {
            allParameters = FlickrDefaultParameters
        }
        Alamofire.request(.GET, FlickrAPIEndpoint, parameters: allParameters)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .Success:
                    self.parseFlickrResponse(response.result.value)
                case .Failure(let error):
                    self.alert(error.localizedDescription)
                }
                self.refreshControl?.endRefreshing()
        }
        
    }
    
    func parseFlickrResponse(value: AnyObject?) {
        if let response = value as? [String: AnyObject] {
            if let stat = response["stat"] where stat.isEqualToString("ok") {
                if let page = response["photos"]?["page"] as? Int, pages = response["photos"]?["pages"] as? Int, photos = response["photos"]?["photo"] as? [[String: AnyObject]] {
                    if searchActive() {
                        search.page = page
                        search.pages = pages
                        let index = page - 1
                        search.photos = search.photos[0..<index] + [photos]
                    }
                    else {
                        recent.page = page
                        recent.pages = pages
                        let index = page - 1
                        recent.photos = recent.photos[0..<index] + [photos]
                    }
                    reloadPage(page)
                }

            }
            else if let message = response["message"] as? String {
                alert(message)
            }
            else {
                alert("Unknown error")
            }
        }
        else {
            alert("Invalid data returned")
        }
    }
    
    func scrollToTop() {
        let top: Int
        if searchController.active {
            top = 0
        }
        else {
            top = 44
        }
        tableView.setContentOffset(CGPoint(x: 0, y: top), animated: false)
    }
    
    func reloadPage(page: Int) {
        if tableView.numberOfSections >= page {
            tableView.beginUpdates()
            tableView.deleteSections(NSIndexSet(indexesInRange: NSRange(location: page, length: tableView.numberOfSections - page)), withRowAnimation: .Fade)
            tableView.reloadSections(NSIndexSet(index: page - 1), withRowAnimation: .Fade)
            tableView.endUpdates()
        }
        else {
            tableView.insertSections(NSIndexSet(indexesInRange: NSRange(location: tableView.numberOfSections, length: page - tableView.numberOfSections)), withRowAnimation: .Fade)
        }
    }
    
    func photoURL(photo: [String: AnyObject]) -> String? {
        if let farm = photo["farm"] as? Int, server = photo["server"] as? String, id = photo["id"] as? String, secret = photo["secret"] as? String {
            return String.init(format: "https://farm%i.staticflickr.com/%@/%@_%@_z.jpg", farm, server, id, secret)
        }
        return nil
    }
    
    func searchActive() -> Bool {
        return searchController.active && searchController.searchBar.text != ""
    }
    
    func activePhotoList() -> PhotoList {
        if searchActive() {
            return search
        }
        else {
            return recent
        }
    }
    
    func updateSearch() {
        searchPhotos(searchController.searchBar.text!, page: 1)
    }

    func searchPhotos(text: String, page: Int) {
        performFetch(parameters: ["method": FlickrMethodSearch, "text": text, "sort": "interestingness-desc", "page": String(page), "per_page": "10"], page: page)
    }
        
    func alert(message: String) {
        alert(title: "", message: message)
    }
    
    func alert(title title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(okAction)
        
        if searchActive() {
            searchController.presentViewController(alertController, animated: true, completion: nil)
        }
        else {
            presentViewController(alertController, animated: true, completion: nil)
        }
    }

}
