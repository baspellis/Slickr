//
//  PhotoTransitionController.swift
//  Slickr
//
//  Created by Bas Pellis on 08/06/16.
//  Copyright © 2016 WebComrades. All rights reserved.
//

import UIKit

class PhotoTransitionController: NSObject, UIViewControllerAnimatedTransitioning {
    var isPresenting = true
    var sourceView : UIView?
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        if let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey), toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey), photoImageView = sourceView as? UIImageView {
            
            let detailViewController : PhotoDetailViewController
            if isPresenting {
                detailViewController = toViewController as! PhotoDetailViewController
            }
            else {
                detailViewController = fromViewController as! PhotoDetailViewController
                
                toViewController.view.frame = transitionContext.finalFrameForViewController(toViewController)
                toViewController.view.layoutIfNeeded()
            }
            
            
            let containerView = transitionContext.containerView()
            
            if isPresenting {
                setupForPresenting(detailViewController, photoImageView: photoImageView)
                containerView?.addSubview(toViewController.view)
            }
            else {
                setupForPresented(detailViewController, photoImageView: photoImageView)
                containerView?.insertSubview(toViewController.view, atIndex: 0)
            }
            detailViewController.view.layoutIfNeeded()
            
            
            UIView.animateWithDuration(transitionDuration(transitionContext), animations: {
                if self.isPresenting {
                    self.setupForPresented(detailViewController, photoImageView: photoImageView)
                }
                else {
                    self.setupForPresenting(detailViewController, photoImageView: photoImageView)
                }
                detailViewController.view.layoutIfNeeded()
            }, completion: { finished in
                if self.isPresenting {
                    self.setupForCompleted(detailViewController)
                }
                else {
                    detailViewController.view.removeFromSuperview()
                }
                detailViewController.view.layoutIfNeeded()
                toViewController.view.layoutIfNeeded()
                transitionContext.completeTransition(finished)  
            })
        }
    }
    
    func setupForPresenting(detailViewController: PhotoDetailViewController, photoImageView: UIImageView) {
        let photoImageFrame = detailViewController.view.convertRect(photoImageView.frame, fromView: photoImageView.superview)
        
        detailViewController.photoImageTopConstraint.constant = CGRectGetMinY(photoImageFrame)
        detailViewController.photoImageBottomConstraint.constant = CGRectGetHeight(detailViewController.view.bounds) - CGRectGetMaxY(photoImageFrame)
        detailViewController.photoImageLeadingConstraint.constant = CGRectGetMinX(photoImageFrame)
        detailViewController.photoImageTrailingConstraint.constant = CGRectGetWidth(detailViewController.view.bounds) - CGRectGetMaxX(photoImageFrame)
        
        detailViewController.view.backgroundColor = UIColor(white: 0, alpha: 0)
        detailViewController.photoImageView.contentMode = .ScaleAspectFill
        detailViewController.photoImageView.clipsToBounds = true
    }
    
    func setupForPresented(detailViewController: PhotoDetailViewController, photoImageView: UIImageView) {
        
        let margin : CGSize
        if let image = photoImageView.image {
            if image.size.width / image.size.height < CGRectGetWidth(detailViewController.view.bounds) / CGRectGetHeight(detailViewController.view.bounds) {
                margin = CGSize(width: (CGRectGetWidth(detailViewController.view.bounds) - image.size.width * CGRectGetHeight(detailViewController.view.bounds) / image.size.height) / 2, height: 0)
            }
            else {
                margin = CGSize(width: 0, height: (CGRectGetHeight(detailViewController.view.bounds) - image.size.height * CGRectGetWidth(detailViewController.view.bounds) / image.size.width) / 2)
            }
        }
        else {
            margin = CGSizeZero
        }
        
        detailViewController.photoImageTopConstraint.constant = margin.height
        detailViewController.photoImageBottomConstraint.constant = margin.height
        detailViewController.photoImageLeadingConstraint.constant = margin.width
        detailViewController.photoImageTrailingConstraint.constant = margin.width

        detailViewController.view.backgroundColor = UIColor(white: 0, alpha: 1)
        detailViewController.photoImageView.contentMode = .ScaleAspectFill
        detailViewController.photoImageView.clipsToBounds = true
    }
    
    func setupForCompleted(detailViewController: PhotoDetailViewController) {
        detailViewController.photoImageTopConstraint.constant = 0
        detailViewController.photoImageBottomConstraint.constant = 0
        detailViewController.photoImageLeadingConstraint.constant = 0
        detailViewController.photoImageTrailingConstraint.constant = 0

        detailViewController.photoImageView.contentMode = .ScaleAspectFit
    }
}
