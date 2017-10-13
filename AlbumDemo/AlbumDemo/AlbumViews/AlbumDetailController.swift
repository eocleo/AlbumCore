//
//  AlbumDetailController.swift
//  AlbumDemo
//
//  Created by leo on 2017/8/23.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "AlbumDetailCollectionViewCell"

//九宫格形式显示相册内容，图片/视频
class AlbumDetailController: UICollectionViewController {

    var collection: AlbumCollection? {
        didSet {
            self.collection?.registerFetchResultChange(self)
            self.reloadData { [weak self] in
                self?.scrollToBottom()
            }
        }
    }
    // MARK: - 回调block
    var needDisableSelectMore: (() -> Bool)?
    var didSelectBlock: ((_ albumFile: AlbumFile) -> Bool)?
    var hasSelectedAsset: ((_ asset: PHAsset?) -> Bool)?
    
    //由父页面传入，可以为空
    var footerViewFly = false
    
    var footerView: UIView? {
        didSet {
            if footerView != nil {
                self.view.addSubview(footerView!)
            }
        }
    }
    
    // MARK: - 刷新选中个数
    func refreshSelectedCount(_ animation: Bool) -> Void {
    }

    fileprivate var allAsset: PHFetchResult<PHAsset>? {
        get {
            return self.collection?.assetsResult
        }
    }
    
    fileprivate lazy var blankView: NoDataOverlayerView = {
        let view = NoDataOverlayerView.createWith(image: UIImage.init(named: "noPic"), message: "您的相册是空的")
        view?.isHidden = true
        view?.frame = self.collectionView!.bounds
        return view ?? NoDataOverlayerView.init()
    }()
    

    fileprivate func reloadData(_ complete: (() -> Void)?) -> Void {
        self.collection?.fetchAssets( block: { [weak self] (asset) in
            guard self != nil else {
                return
            }
            runInMain {
                var count = self?.allAsset?.count ?? 1 - 1
                if count < 0 {
                    count = 0
                }
                self?.title = self?.title
                self?.collectionView?.reloadData()
                complete?()
            }
        })
    }
    
    fileprivate func scrollToBottom() -> Void {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: 1), execute: {
            if let collectionView = self.collectionView {
                let lastRow: Int = self.allAsset?.count ?? 0
                if lastRow == 0 {
                    return
                }
                collectionView.scrollToItem(at: IndexPath.init(row: lastRow - 1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: false)
            }
        })
    }

    fileprivate func alertNeedLoadICloudSouce(_ complete:((_ needDownLoad: Bool) -> Void)?) -> Void {
        runInMain {
            // MARK: - todo
            let alertController = UIAlertController.init(title: nil, message: "当前文件来自icloud，加载可能需要较长时间", preferredStyle: .alert)
            alertController.addAction(UIAlertAction.init(title: "取消", style: .default, handler: { [weak alertController] (action) in
                alertController?.dismiss(animated: true, completion: nil)
                complete?(false)
            }))
            
            alertController.addAction(UIAlertAction.init(title: "确定", style: .default, handler: { [weak alertController] (action) in
                alertController?.dismiss(animated: true, completion: nil)
                complete?(true)
            }))

            runInMain {
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }

    fileprivate func trySelectIndexPath( index: IndexPath, complete: @escaping (_ isSelected: Bool) -> Void) -> Void {
        guard let asset: PHAsset = self.allAsset?.object(at: index.row) else {
            complete(false)
            return
        }
        if asset.isICloudImageAsset() {
            self.alertNeedLoadICloudSouce { [weak self] (needLoad) in
                if needLoad == false {
                    complete(false)
                } else {
                    self?._trySelectIndexPath(index: index, complete: complete)
                }
            }
        } else {
            self._trySelectIndexPath(index: index, complete: complete)
        }
    }
    
    
    fileprivate func _trySelectIndexPath( index: IndexPath, complete: @escaping (_ isSelected: Bool) -> Void) -> Void {
        guard let asset: PHAsset = self.allAsset?.object(at: index.row) else {
            complete(false)
            return
        }
        if asset.isICloudImageAsset() {
            ToastStartLoading()
        }
        asset.requestAllInfo(block: { [weak self] (filePath, size, identifier) in
            guard asset.localIdentifier.compare(identifier) == .orderedSame else {
                complete(false)
                return
            }
            if asset.isICloudImageAsset() {
                ToastStopLoading()
            }
            let file = AlbumFile.init(with: asset)
            file.filePath = filePath
            file.fileSize = size
            file.fileIdentifier = identifier
            
            let isSelected = self?.didSelectBlock?(file) ?? false
            if let cell = self?.collectionView?.cellForItem(at: index) as? AlbumDetailCollectionViewCell {
                runInMain {
                    cell.selectButton.isSelected = isSelected
                }
            }
            runInMain {
                self?.updateVisibleCellState()
                self?.refreshSelectedCount(true)
            }
            complete(isSelected)
        })
    }
    
    func updateVisibleCellState() -> Void {
        guard let visibleIndexPaths = self.collectionView?.indexPathsForVisibleItems else {
            return
        }
        for indexPath in visibleIndexPaths {
            if let cell = self.collectionView?.cellForItem(at: indexPath) as? AlbumDetailCollectionViewCell,
                let asset: PHAsset = self.allAsset?.object(at: indexPath.row) {
                let isSelected = self.hasSelectedAsset?(asset) ?? false
                if isSelected {
                    cell.selectButton.isSelected = isSelected
                    cell.disableView.isHidden = true
                } else {
                    let stopSelect = self.needDisableSelectMore?() ?? false
                    cell.disableView.isHidden = !stopSelect
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let cellNib: UINib = UINib.init(nibName: reuseIdentifier, bundle: Bundle.main)
        self.collectionView!.register(cellNib, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.backgroundColor = UIColor.white
        self.collectionView?.backgroundView = self.blankView
        self.view.backgroundColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupMainUI()
        self.refreshSelectedCount(false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupMainUI() -> Void {
        if self.footerView != nil {
            self.collectionView?.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height - 50.0)
            self.footerView?.frame = CGRect.init(x: 0, y: (self.view?.frame.size.height)! - 50.0, width: (self.collectionView?.frame.size.width)!, height: 50.0)
        } else {
            self.collectionView?.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        }
    }
    

    // MARK: - CollectionView datasouce
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.allAsset?.count ?? 0
        self.blankView.isHidden = (count != 0)
        return count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: AlbumDetailCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumDetailCollectionViewCell
        
        // Configure the cell
        let asset: PHAsset = (allAsset?.object(at: indexPath.row))!
        cell.localIdentify = asset.localIdentifier
        //此处设置图片，能提供更加流畅的效果，但部分系统如ios10.3由于cell复用会出现图片错乱，在willDisplay中修正
        self.setImageFor(cell: cell, for: indexPath)
        if let isSelected = self.hasSelectedAsset?(asset) {
            cell.selectButton.isSelected = isSelected
        }
        
        if self.needDisableSelectMore?() ?? false {
            cell.disableView.isHidden = cell.selectButton.isSelected
        } else {
            cell.disableView.isHidden = true
        }
        
        cell.onClick = { [weak self] (cell: AlbumDetailCollectionViewCell, button) in
            //选中一个按钮
            // indexPath
            guard let index: IndexPath = collectionView.indexPath(for: cell) as IndexPath?  else {
                return
            }
            self?.trySelectIndexPath(index: index, complete: { (isSelected) in
                runInMain {
                    button.isSelected = isSelected
                }
            })
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? AlbumDetailCollectionViewCell else {
            return
        }
        guard let asset = allAsset?.object(at: indexPath.row) else {
            return
        }
        //防止图片错乱或者不显示问题
        if cell.localIdentify != asset.localIdentifier || cell.imageView.image == nil {
            self.setImageFor(cell: cell, for: indexPath)
        }
    }
    
    fileprivate let defaultMovieImage = UIImage.init(named: "影片（无格式）")

    fileprivate func setImageFor(cell: AlbumDetailCollectionViewCell, for indexPath: IndexPath) -> Void {
        guard let asset = allAsset?.object(at: indexPath.row) else {
            return
        }
        let _ = asset.requestImage(size: CGSize.init(width: 90.0, height: 90.0)) { (dic) in
            let image: UIImage? = dic[AlbumConstant.ImageKey] as? UIImage
            runInMain {
                if cell.localIdentify == asset.localIdentifier {
                    cell.imageView.image = image
                    if image == nil && asset.mediaType == .video {
                        cell.imageView.image = self.defaultMovieImage
                    }
                } else {
                    AlbumDebug("\(indexPath.section),\(indexPath.row)")
                }
            }
        }
    }
}

extension AlbumDetailController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (SCREEN_WIDTH - (5*5))/4.0
        return CGSize.init(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsetsMake(5.0, 5.0, 0.0, 5.0)
        }else {
            return UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5.0
    }
    
}

extension AlbumDetailController: FetchResultChangeDetailObserver {
    private func photolibraryChange(withDetail: PHFetchResultChangeDetails<PHAsset>?) -> Void {
        guard let detail = withDetail else {
            return
        }
        AlbumDebug("\(detail)")
        self.collection?.fetchAssets(block: { [weak self] (results) in
            if detail.hasIncrementalChanges {
                
                func indexPathsFor(_ indexSet: IndexSet?) -> [IndexPath] {
                    var indexPaths: [IndexPath] = []
                    if let set = indexSet {
                        for index in set {
                            indexPaths.append(IndexPath.init(row: index, section: 0))
                        }
                    }
                    return indexPaths
                }
                runInMain {
                    self?.collectionView?.insertItems(at: indexPathsFor(detail.insertedIndexes))
                    self?.collectionView?.deleteItems(at: indexPathsFor(detail.removedIndexes))
                    self?.collectionView?.reloadItems(at: indexPathsFor(detail.changedIndexes))
                }
            } else {
                self?.collectionView?.reloadData()
            }
        })
    }

    func didReceiveChange(_ detail: PHFetchResultChangeDetails<PHAsset>?, collection: AlbumCollection) {
        if collection.isEqual(self.collection) {
            self.photolibraryChange(withDetail: detail)
        }
    }
}
