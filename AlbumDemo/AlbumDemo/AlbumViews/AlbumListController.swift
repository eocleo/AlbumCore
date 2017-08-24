//
//  AlbumListController.swift
//  AlbumDemo
//
//  Created by leo on 2017/8/23.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit
import Photos

typealias AlbumNavItemBlock = (_ album: AlbumListController, _ selectedFiles: [AlbumFile]) -> Void

private let reuseIdentifier = "AlbumHomeCell"

//相册列表，包含智能相册，用户相册，可自定义显示哪些
class AlbumListController: UICollectionViewController {

    //右侧完成按钮
    var rightNavBlock: AlbumNavItemBlock? {
        didSet {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: self.rightCountNavButton)
        }
    }
    
    @objc fileprivate func rightNavAction(_ button: UIButton) {
        self.rightNavBlock?(self, self.viewModel.selectedFiles)
    }
    
    // MARK: - 数据源,viewModel
    fileprivate var viewModel = AlbumListViewModel()
    
    fileprivate func refreshData() {
        self.viewModel.refreshData { [weak self] in
            DispatchQueue.main.async {
                self?.collectionView?.reloadData()
            }
        }
    }

    // MARK: - 遮罩
    fileprivate var hasAuthorized: Bool = true {
        didSet {
            if hasAuthorized {
                self.overlayerRightsView?.dismiss()
                self.overlayerView = self.overlayerDataView
            } else {
                self.overlayerDataView?.dismiss()
                self.overlayerView = self.overlayerRightsView
            }
        }
    }
    
    fileprivate lazy var rightCountNavButton: UIButton = {
        let button = self.createNavButton(image: nil, title: "完成")
        button.contentHorizontalAlignment = .right
        button.setTitleColor(UIColor.blue, for: .normal)
        button.addTarget(self, action: #selector(rightNavAction(_:)), for: .touchUpInside)
        return button
    }()
    
    fileprivate var overlayerView: OverlayerView?
    
    fileprivate var overlayerRightsView: LimitRightsOverlayerView? = LimitRightsOverlayerView.createWith(image: UIImage.init(named: "相册权限"))
    fileprivate var overlayerDataView: NoDataOverlayerView? = NoDataOverlayerView.createWith(image: UIImage.init(named: "noPic"), message: "没有相册")
    
    fileprivate func showAccessDenied() {
        self.hasAuthorized = false
        self.refreshData()
    }
    
    // MARK: - 权限 与 数据 刷新
    fileprivate func checkAutorizationAndLoadData() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            self.refreshData()
        } else if status == .notDetermined {
            self.requestAuthorizationStatus()
        } else {
            self.showAccessDenied()
        }
    }
    
    fileprivate func requestAuthorizationStatus() {
        PHPhotoLibrary.requestAuthorization { (status) in
            if (status == .authorized) {
                self.refreshData()
            } else {
                self.showAccessDenied()
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "自定义相册"
        self.setupCollectionView()
        self.checkAutorizationAndLoadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func setupCollectionView() -> Void {
        let cellNib: UINib = UINib.init(nibName: reuseIdentifier, bundle: Bundle.main)
        self.collectionView!.register(cellNib, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView!.showsVerticalScrollIndicator = true
        self.collectionView!.backgroundColor = UIColor.white
    }
    
    fileprivate lazy var defaultAlbumFirstImage = {
        return UIImage.imageWith(color: .cellLine, size: CGSize.init(width: 120, height: 120))
    }()
    
    // MARK: - 相册详情页面
    fileprivate  lazy var detailController: AlbumDetailController = {
        var controller = AlbumDetailController.init(collectionViewLayout: UICollectionViewFlowLayout())
//        controller.footerViewFly = true
        return controller
    }()

    fileprivate func showDetailController(with myCollection: AlbumCollection) -> Void {
        collectionView?.isUserInteractionEnabled = false
        
        detailController.title = myCollection.name
        detailController.collection = myCollection
        detailController.hidesBottomBarWhenPushed = true
        
        detailController.hasSelectedAsset = { [weak self] (asset) -> Bool in
            guard (asset != nil), (asset?.localIdentifier != nil) else {
                return false
            }
            if (self?.viewModel.selectedItems[asset?.localIdentifier ?? ""] != nil) {
                return true
            }
            return false
        }
        
        detailController.didSelectBlock = { [weak self] (file) -> Bool in
            var hasSelected = false
            if  let file = self?.viewModel.selectedItems[file.fileIdentifier!] {
                if let identitier = file.fileIdentifier {
                    self?.viewModel.selectedItems.removeValue(forKey: identitier)
                    hasSelected =  false
                }else {
                    hasSelected =  false
                }
            } else {
                
                if self != nil && self!.viewModel.selectedItems.count >= 20 {
                    Toast(message: "最多只能选择20个文件")
                    hasSelected =  false
                } else if let identitier = file.fileIdentifier {
                    self?.viewModel.selectedItems.updateValue(file, forKey: identitier)
                    hasSelected =  true
                } else {
                    hasSelected =  false
                }
            }
            return hasSelected
        }
        
        detailController.willDisppear = { [weak self] in
            self?.viewModel.selectedItems.removeAll()
        }
        
        detailController.needDisableSelectMore = { [weak self] () in
            return self?.viewModel.disableSelectedMore ?? false
        }
        
        self.navigationController?.pushViewController(detailController, animated: true)
        collectionView?.isUserInteractionEnabled = true;
    }

    // MARK: - CollectionView Datasouce
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewModel.albumList.count == 0 {
            self.overlayerView?.showOn(view: collectionView)
        } else {
            self.overlayerView?.dismiss()
        }
        return viewModel.albumList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: AlbumHomeCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumHomeCell
        
        // Configure the cell
        
        let myCollection = viewModel.albumList[indexPath.row]
        
        cell.albumImageView.image = myCollection.firstImage
        if myCollection.firstImage == nil {
            myCollection.getFistImage(size: cell.albumImageView.bounds.size) { [weak cell, weak self] (image) in
                runInMain {
                    cell?.albumImageView.image = image ?? self?.defaultAlbumFirstImage
                }
            }
        }
        
        cell.titleLabel.text = myCollection.name
        
        if myCollection.count == nil {
            if myCollection.collection.estimatedAssetCount != NSNotFound {
                cell.countLabel.text = "\(myCollection.collection.estimatedAssetCount)"
            } else {
                cell.countLabel.text = "0"
            }
            myCollection.fetchAssets(block: { [weak myCollection, weak cell] (result) in
                runInMain {
                    cell?.countLabel.text = "\(myCollection?.count ?? 0)"
                }
            })
            
        } else {
            cell.countLabel.text = "\(myCollection.count ?? 0)"
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let myCollection: AlbumCollection = viewModel.albumList[indexPath.row]
        self.showDetailController(with: myCollection)
    }


}

extension AlbumListController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (self.view.frame.size.width - 60)/2.0
        return CGSize.init(width: width, height: width + 205 - 158)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsetsMake(20.0, 20.0, 0.0, 20.0)
        }else {
            return UIEdgeInsetsMake(0.0, 20.0, 0.0, 20.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20.0
    }
    
}
