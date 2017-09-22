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
    var selectDoneBlock: AlbumNavItemBlock? {
        didSet {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: self.rightCountNavButton)
        }
    }
    
    @objc fileprivate func rightNavAction(_ button: UIButton) {
        self.selectDoneBlock?(self, self.viewModel.selectedFiles)
    }
    
    // MARK: - 数据源,viewModel
    fileprivate var viewModel = AlbumListViewModel()
    
    fileprivate func refreshData() {
        self.viewModel.refreshData { [weak self] in
            self?.setupAlbumChangeNotifiy()
            self?.setupCollectionView()
            DispatchQueue.main.async {
                self?.collectionView?.reloadData()
            }
        }
    }
    
    fileprivate func setupAlbumChangeNotifiy() -> Void {
        for collection in self.viewModel.albumList {
            collection.registerFetchResultChange(self)
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
        button.setTitleColor(.white, for: .normal)
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
//        PHPhotoLibrary.shared().register(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.refreshSelectedCount(false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - 刷新选中个数
    func refreshSelectedCount(_ animation: Bool) -> Void {
        var title = "完成"
        var countPanText = "请选择文件"
        if self.viewModel.selectedItems.count > 0 {
            title = title.appending("(\(self.viewModel.selectedItems.count))")
            countPanText = "已选 (\(self.viewModel.selectedItems.count)/\(self.viewModel.maxSelectCount))"
        }
        self.rightCountNavButton.setTitle(title, for: .normal)
        self.countPanView.doneButton.isEnabled = !(self.viewModel.selectedItems.count == 0)
        self.countPanView.countLabel.text = countPanText
        
    }

    fileprivate func setupCollectionView() -> Void {
        let cellNib: UINib = UINib.init(nibName: reuseIdentifier, bundle: Bundle.main)
        self.collectionView!.register(cellNib, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView!.showsVerticalScrollIndicator = true
        self.collectionView!.backgroundColor = UIColor.white
    }
    
    fileprivate lazy var defaultAlbumImage = {
        return UIImage.imageWith(color: .cellLine, size: CGSize.init(width: 120, height: 120))
    }()
    
    // MARK: - 相册详情页面
    fileprivate  lazy var detailController: AlbumDetailController = {
        var controller = AlbumDetailController.init(collectionViewLayout: UICollectionViewFlowLayout())
        return controller
    }()

    fileprivate lazy var countPanView: AlbumSelectCountPanView = {
        let panView = AlbumSelectCountPanView.createFromXib()
        panView?.doneCallBack = { [weak self] () in
            if let weakSelf = self {
                weakSelf.selectDoneBlock?(weakSelf, weakSelf.viewModel.selectedFiles)
                weakSelf.navigationController?.popToRootViewController(animated: true)
            }
        }
        return panView ?? AlbumSelectCountPanView()
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
            self?.refreshSelectedCount(true)
            return hasSelected
        }
                
        detailController.needDisableSelectMore = { [weak self] () in
            return self?.viewModel.disableSelectedMore ?? false
        }
        
        detailController.footerView = self.countPanView
        
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
        cell.titleLabel.text = myCollection.name
        cell.countLabel.text = "\(myCollection.count ?? 0)"
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? AlbumHomeCell else {
            return
        }
        let myCollection = viewModel.albumList[indexPath.row]
        cell.albumImageView.image = myCollection.lastImage ?? defaultAlbumImage
        if myCollection.lastImage == nil {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: { 
                myCollection.getLastImage(size: CGSize.init(width: 300, height: 300)) { [weak myCollection, weak self, weak collectionView] (image) in
                    runInMain {
                        if let thisCell = collectionView?.cellForItem(at: indexPath) as? AlbumHomeCell {
                            thisCell.albumImageView.image = image ?? self?.defaultAlbumImage
                            thisCell.countLabel.text = "\(myCollection?.count ?? 0)"
                        }
                    }
                }
            })
        }
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

extension AlbumListController: FetchResultChangeDetailObserver {
    func didReceiveChange(_ detail: PHFetchResultChangeDetails<PHAsset>?, collection: AlbumCollection) {
        func updateWithChange(_ detail: PHFetchResultChangeDetails<PHAsset>, collection: AlbumCollection, index: Int) -> Void {
            func ifNeedUpdate<T>(_ withDetail: PHFetchResultChangeDetails<T>?) -> Bool {
                if let detail = withDetail {
                    if detail.hasIncrementalChanges == true {
                        return true
                    } else if detail.changedObjects.count > 0 ||
                        detail.removedObjects.count > 0 ||
                        detail.insertedObjects.count > 0{
                        return true
                    }
                }
                return false
            }
            
            if ifNeedUpdate(detail) {
                let indexPath = IndexPath.init(row: index, section: 0)
                collection.clearCache()
                collection.fetchAssets(block: { [weak self] (result) in
                    runInMain {
                        self?.collectionView?.reloadItems(at: [indexPath])
                    }
                })
            }
        }
        
        if let index = self.viewModel.albumList.index(of: collection), let detail = detail {
            updateWithChange(detail, collection: collection, index: index)
        }
    }
}


