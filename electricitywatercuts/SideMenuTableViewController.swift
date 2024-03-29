//
//  SideMenuTableViewController.swift
//  electricitywatercuts
//
//  Created by nils on 8.05.2018.
//  Copyright © 2018 nils. All rights reserved.
//

//
//  SideMenuTableViewController.swift
//  SideMenu
//
//  Created by Jon Kent on 4/5/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import SideMenu

class SideMenuTableViewController: UITableViewController {
    
    @IBOutlet weak var iconLabel: UILabel!
    @IBOutlet weak var rangeLabel: UIButton!
    @IBOutlet weak var frequencyLabel: UIButton!
    @IBOutlet weak var orderLabel: UIButton!
    @IBOutlet weak var languageLabel: UIButton!
    
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        present(SideMenuManager.default.menuLeftNavigationController!, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        iconLabel.text = CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "app_name")
        rangeLabel.setTitle(CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "cuts_range"), for: .normal)
        frequencyLabel.setTitle(CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "cuts_refresh_freq"), for: .normal)
        orderLabel.setTitle(CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "cuts_order_option"), for: .normal)
        languageLabel.setTitle(CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "cuts_lang"), for: .normal)
        
        // refresh cell blur effect in case it changed
        tableView.reloadData()
        
        guard SideMenuManager.default.menuBlurEffectStyle == nil else {
            return
        }
        
        // Set up a cool background image for demo purposes
        /*
        let imageView = UIImageView(image: UIImage(named: "saturn"))
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        tableView.backgroundView = imageView
         */
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath) as! UITableViewVibrantCell
        
        cell.blurEffectStyle = SideMenuManager.default.menuBlurEffectStyle
        
        return cell
    }
}

