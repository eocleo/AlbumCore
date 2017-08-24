//
//  ViewController.swift
//  AlbumDemo
//
//  Created by leo on 2017/8/22.
//  Copyright © 2017年 leo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    fileprivate lazy var tableView: UITableView = {
        let table: UITableView = UITableView.init(frame: self.view.bounds)
        table.backgroundColor = .white
        table.rowHeight = 50.0
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    var sourceArray: [String] = Array()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = "相册选择示例"
        self.setupTableView()
        let array = ["系统相册样式"]
        sourceArray.append(contentsOf: array)
        self.tableView.reloadData()
        
        let navBgImage: UIImage? = {
            let image = UIImage.imageWith(color: UIColor.brown, size: CGSize.init(width: 10, height: 10))
            return image?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 10/2.0, left: 10/2.0, bottom: 10/2.0, right: 10/2.0))
        }()
        self.navigationController?.navigationBar.setBackgroundImage(navBgImage, for: .default)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTableView() -> Void {
        self.view.addSubview(tableView)
        tableView.frame = self.view.bounds
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sourceArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self))
        
        cell?.textLabel?.text = sourceArray[indexPath.row]
        return cell!
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NSLog("didSelectRowAt:\(indexPath.row),\(indexPath.section)")
        let albumListController = AlbumListController.init(collectionViewLayout: UICollectionViewFlowLayout.init())
        albumListController.rightCancelBlock = { [weak albumListController] in
            albumListController?.navigationController?.popViewController(animated: true)
        }
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(albumListController, animated: true)
        }
    }
}

