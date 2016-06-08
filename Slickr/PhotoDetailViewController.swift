//
//  PhotoDetailViewController.swift
//  Slickr
//
//  Created by Bas Pellis on 07/06/16.
//  Copyright © 2016 WebComrades. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController {

    var image: UIImage?
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoImageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoImageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoImageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoImageTrailingConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoImageView.image = image
    }
    @IBAction func dismissViewController(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
