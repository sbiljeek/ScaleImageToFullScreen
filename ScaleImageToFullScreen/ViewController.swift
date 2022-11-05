//
//  ViewController.swift
//  ScaleImageToFullScreen
//
//  Created by Salman Biljeek on 11/5/22.
//

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    var startingFrame: CGRect?
    var fullScreenViewController: FullScreenImageViewController!
    var selectedImageView: UIView?
    
    var topConstraint: NSLayoutConstraint?
    var leadingConstraint: NSLayoutConstraint?
    var widthConstraint: NSLayoutConstraint?
    var heightConstraint: NSLayoutConstraint?
    
    let blurVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemYellow
        
        self.view.addSubview(blurVisualEffectView)
        blurVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        blurVisualEffectView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        blurVisualEffectView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        blurVisualEffectView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        blurVisualEffectView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        blurVisualEffectView.alpha = 0
        
        let imageView: UIImageView = {
            let imageView = UIImageView()
            imageView.backgroundColor = .tertiarySystemFill
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 16
            return imageView
        }()
        
        let image = UIImage(named: "image1") ?? UIImage()
        
        imageView.image = image
        
        let ratio = image.size.height / image.size.width
        
        let leftRightPadding: CGFloat = 40
        
        self.view.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: leftRightPadding).isActive = true
        imageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -leftRightPadding).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: ratio).isActive = true
        imageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
        let imageViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleImageTapped))
        imageView.addGestureRecognizer(imageViewTapGesture)
        imageView.isUserInteractionEnabled = true
    }
    
    @objc fileprivate func handleImageTapped(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView else { return }
        guard let image = imageView.image else { return }
        
        // #1 setup the FullScreenViewController
        self.setupFullScreenViewController(image: image)
        
        // #2 Setup FullScreenViewController in its starting position
        self.setupFullScreenViewControllerStartingPosition(imageView, self)
        
        // #3 Set selectedImageView
        self.selectedImageView = imageView
        
        // #4 Begin the fullscreen animation
        self.beginAnimationOfFullScreenViewController(self)
    }
    
    fileprivate func setupFullScreenViewController(image: UIImage) {
        let fullScreenViewController = FullScreenImageViewController(image: image)
        fullScreenViewController.dismissHandler = {
            self.handleRemoveFullScreenViewController()
        }
        fullScreenViewController.view.clipsToBounds = true
        fullScreenViewController.view.layer.cornerRadius = 16
        self.fullScreenViewController = fullScreenViewController
        
        // #1 setup the dismiss pan gesture
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.handleDrag))
        gesture.delegate = self
        self.fullScreenViewController.view.addGestureRecognizer(gesture)
    }
    
    fileprivate func setupFullScreenViewControllerStartingPosition(_ imageView: UIImageView, _ viewController: UIViewController) {
        let fullScreenView = self.fullScreenViewController.view!
        viewController.view.addSubview(fullScreenView)
        
        viewController.addChild(self.fullScreenViewController)
        
        self.setupPostViewControllerStartingCellFrame(imageView)
        guard let startingFrame = self.startingFrame else { return }
        
        fullScreenView.translatesAutoresizingMaskIntoConstraints = false
        self.topConstraint = fullScreenView.topAnchor.constraint(equalTo: viewController.view.topAnchor, constant: startingFrame.origin.y)
        self.leadingConstraint = fullScreenView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: startingFrame.origin.x)
        self.widthConstraint = fullScreenView.widthAnchor.constraint(equalToConstant: startingFrame.width)
        self.heightConstraint = fullScreenView.heightAnchor.constraint(equalToConstant: startingFrame.height)
        
        [topConstraint, leadingConstraint, widthConstraint, heightConstraint].forEach({$0?.isActive = true})
        viewController.view.layoutIfNeeded()
    }
    
    fileprivate func setupPostViewControllerStartingCellFrame(_ imageView: UIImageView) {
        let imageViewWidth: CGFloat = imageView.frame.width
        let imageViewHeight: CGFloat = imageView.frame.height
        let imageViewY = imageView.frame.minY
        let imageViewX = imageView.frame.minX
        let startingFrame = CGRect(x: imageViewX, y: imageViewY, width: imageViewWidth, height: imageViewHeight)
        
        self.startingFrame = startingFrame
    }
    
    fileprivate func beginAnimationOfFullScreenViewController(_ navigationController: UIViewController) {
        self.selectedImageView?.alpha = 0
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.7, options: .curveEaseOut) {
            self.blurVisualEffectView.alpha = 1
            
            self.topConstraint?.constant = 0
            self.leadingConstraint?.constant = 0
            self.widthConstraint?.constant = navigationController.view.frame.width
            self.heightConstraint?.constant = navigationController.view.frame.height
            navigationController.view.layoutIfNeeded()
        } completion: { _ in
            //.
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc fileprivate func handleDrag(gesture: UIPanGestureRecognizer) {
        let translationY = gesture.translation(in: self.fullScreenViewController.view).y
        
        if gesture.state == .changed {
            if translationY > 0 {
                var scale = 1 - translationY / 1000
                scale = min(1, scale)
                scale = max(0.7, scale)
                let transform: CGAffineTransform = .init(scaleX: scale, y: scale)
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut) {
                    self.fullScreenViewController.view.transform = transform
                }
            } else {
                if self.fullScreenViewController.view.transform != .identity {
                    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut) {
                        self.fullScreenViewController.view.transform = .identity
                    }
                }
            }
        } else if gesture.state == .ended {
            if translationY > 50 {
                self.handleRemoveFullScreenViewController()
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut) {
                    self.fullScreenViewController.view.transform = .identity
                }
            }
        }
    }
    
    @objc fileprivate func handleRemoveFullScreenViewController() {
        let viewController = self
        guard let startingFrame =  self.startingFrame else { return }
        self.fullScreenViewController.view.clipsToBounds = true
        self.fullScreenViewController.closeButton.alpha = 0
        UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.7, options: .curveEaseOut) {
            self.topConstraint?.constant = startingFrame.origin.y
            self.leadingConstraint?.constant = startingFrame.origin.x
            self.widthConstraint?.constant = startingFrame.width
            self.heightConstraint?.constant = startingFrame.height
            
            self.fullScreenViewController.view.transform = .identity
            self.blurVisualEffectView.alpha = 0
            viewController.view.layoutIfNeeded()
        } completion: { _ in
            self.fullScreenViewController.view.removeFromSuperview()
            self.fullScreenViewController.removeFromParent()
            self.selectedImageView?.alpha = 1
        }
    }
}

