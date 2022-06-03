//
//  ThumbnailsViewController.swift
//  ImageViewer
//
//  Created by Zeno Foltin on 07/07/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import UIKit

class ThumbnailsViewController: UIViewController, UICollectionViewDelegateFlowLayout, UINavigationBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    fileprivate let reuseIdentifier = "ThumbnailCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate var isAnimating = false
    fileprivate let rotationAnimationDuration = 0.2

    var onItemSelected: ((Int) -> Void)?
   var collView: UICollectionView?
    let layout = UICollectionViewFlowLayout()
    weak var itemsDataSource: GalleryItemsDataSource!
    var closeButton: UIButton?
    var closeLayout: ButtonLayout?

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func rotate() {
        guard UIApplication.isPortraitOnly else { return }

        guard UIDevice.current.orientation.isFlat == false &&
            isAnimating == false else { return }

        isAnimating = true

        UIView.animate(withDuration: rotationAnimationDuration, delay: 0, options: UIView.AnimationOptions.curveLinear, animations: { [weak self] () -> Void in
            self?.view.transform = windowRotationTransform()
            self?.view.bounds = rotationAdjustedBounds()
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()

            })
        { [weak self] finished  in
            self?.isAnimating = false
        }
    }

   override func viewDidLoad() {
      super.viewDidLoad()
          let topSafeArea: CGFloat
          let bottomSafeArea: CGFloat
          if #available(iOS 11.0, *) {
              topSafeArea = view.safeAreaInsets.top
              bottomSafeArea = view.safeAreaInsets.bottom
          } else {
              topSafeArea = topLayoutGuide.length
              bottomSafeArea = bottomLayoutGuide.length
          }
      let screenWidth = self.view.frame.width
      let screenHeight = self.view.frame.height - (topSafeArea + bottomSafeArea)

      layout.sectionInset = UIEdgeInsets(top: 50, left: 8, bottom: 8, right: 8)
      layout.itemSize = CGSize(width: screenWidth/3 - 8, height: screenWidth/3 - 8)
      layout.minimumInteritemSpacing = 4
      layout.minimumLineSpacing = 4
   
      let viewCollBg = UIView(frame: CGRect(x: 0, y: topSafeArea + 20, width: screenWidth, height: self.view.frame.height - topSafeArea))
      collView = UICollectionView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight - 20), collectionViewLayout: layout)
      collView?.delegate = self
      collView?.dataSource = self
      let path = UIBezierPath(roundedRect: viewCollBg.frame, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 40, height: 40))
             let mask = CAShapeLayer()
             mask.path = path.cgPath
      viewCollBg.layer.mask = mask
      collView?.register(ThumbnailCell.self, forCellWithReuseIdentifier: reuseIdentifier)
      collView?.scrollIndicatorInsets = UIEdgeInsets(top: 80,left: 0,bottom: 20,right: 0)
      self.view.backgroundColor = #colorLiteral(red: 0.09411764706, green: 0.1058823529, blue: 0.1411764706, alpha: 0.95)//.clear
      self.view.clipsToBounds = false
      let aBtnHeader = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 75))
      aBtnHeader.setTitle("", for: .normal)
      aBtnHeader.addTarget(self, action: #selector(close), for: .touchUpInside)
      viewCollBg.addSubviews(collView!)
      self.view.addSubview(viewCollBg)
      self.view.addSubview(aBtnHeader)
      addCloseButton()
//      NotificationCenter.default.addObserver(self, selector: #selector(rotate), name: UIDevice.orientationDidChangeNotification, object: nil)
      
      /* View load(From bottom to identity) animation */
      viewCollBg.transform = CGAffineTransform(translationX: 0, y: screenHeight).scaledBy(x: 0, y: 0)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
         UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6, options: .curveEaseInOut, animations: {
            viewCollBg.transform = .identity
         }, completion: nil)
      }
      
   }
   
   func setupCollectionViewDataSource(itemsDataSource: GalleryItemsDataSource) {
      self.itemsDataSource = itemsDataSource
      collView?.collectionViewLayout = layout
      collView?.reloadData()
   }

    fileprivate func addCloseButton() {
        guard let closeButton = closeButton, let closeLayout = closeLayout else { return }

        switch closeLayout {
        case .pinRight(let marginTop, let marginRight):
            closeButton.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
            closeButton.frame.origin.x = self.view.bounds.size.width - marginRight - closeButton.bounds.size.width
            closeButton.frame.origin.y = marginTop
        case .pinLeft(let marginTop, let marginLeft):
            closeButton.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
            closeButton.frame.origin.x = marginLeft
            closeButton.frame.origin.y = marginTop
        }

        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
       closeButton.transform = CGAffineTransform(scaleX: 0, y: 0)
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6, options: .curveEaseInOut, animations: {
             closeButton.transform = .identity
          }, completion: nil)
       }
        self.view.addSubview(closeButton)
    }

    @objc func close() {
        self.dismiss(animated: true, completion: nil)
    }

   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsDataSource.itemCount()
    }

   
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ThumbnailCell

        let item = itemsDataSource.provideGalleryItem((indexPath as NSIndexPath).row)

        switch item {

        case .image(let fetchImageBlock):

            fetchImageBlock() { image in

                if let image = image {

                    cell.imageView.image = image
                }
            }

        case .video(let fetchImageBlock, _):

            fetchImageBlock() { image in

                if let image = image {

                    cell.imageView.image = image
                }
            }

        case .custom(let fetchImageBlock, _):

            fetchImageBlock() { image in

                if let image = image {

                    cell.imageView.image = image
                }
            }
        }

        return cell
    }

   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onItemSelected?((indexPath as NSIndexPath).row)
        close()
    }
}
