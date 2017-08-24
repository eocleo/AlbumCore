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
            self.reloadData()
        }
    }
    // MARK: - 回调block
    var willDisppear:(() -> Void)?
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
    

    fileprivate func reloadData() -> Void {
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
                self?.scrollToBottom()
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        let _ = asset.requestImage(size: CGSize.init(width: 90.0, height: 90.0)) { (dic) in
            let image: UIImage? = dic[AlbumConstant.ImageKey] as? UIImage
            runInMain {
                if cell.localIdentify?.compare(asset.localIdentifier) == .orderedSame {
                    cell.imageView.image = image
                    if image == nil && asset.mediaType == .video {
                        cell.imageView.image = UIImage.init(named: "影片（无格式）")
                    }
                } else {
                    AlbumDebug("\(indexPath.section),\(indexPath.row)")
                }
            }
        }
        cell.localIdentify = asset.localIdentifier
        
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
