//
//  ImageVC.swift
//  TweeterTags
//
//  Created by benjamin Kelly on 09/03/2018.
//  Copyright © 2018 COMP47390-41550. All rights reserved.
//

import UIKit

class ImageVC: UIViewController, UIScrollViewDelegate {
    
    private var imageView = UIImageView()
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.contentSize = imageView.frame.size
            scrollView.delegate = self
        }
    }
    
    open var  imageURL: URL? {
        didSet {
            image = nil
            if view.window != nil {
                getImage()
            }
        }
    }
    
    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView?.maximumZoomScale = 1
        scrollView?.minimumZoomScale = min(0.1, scrollView.bounds.size.width / scrollView.contentSize.width)
        scrollView?.zoomScale = scrollView.maximumZoomScale
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            getImage()
        }
    }
    
    private func getImage() {
        if let url = imageURL {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                let imageData = try? Data(contentsOf: url)
                DispatchQueue.main.async {
                    if  url == self.imageURL {
                        if imageData != nil {
                            self.image = UIImage(data: imageData!)
                        } else {
                            self.image = nil
                        }
                    }
                }
            }
        }
    }
    
    @objc func doubleTapped() {
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: imageView.bounds.origin), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = scrollView.convert(center, from: imageView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.addSubview(imageView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
