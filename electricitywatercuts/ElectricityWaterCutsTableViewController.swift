//
//  ElectricityWaterCutsTableViewController.swift
//  electricitywatercuts
//
//  Created by nils on 24.04.2018.
//  Copyright © 2018 nils. All rights reserved.
//

import UIKit
import SideMenu
import UserNotifications

class ElectricityWaterCutsTableViewController: UITableViewController, UISearchResultsUpdating, UNUserNotificationCenterDelegate {
    
    // @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var slideMenuButton: UIBarButtonItem!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    private let cutsUpdateHelper = CutsUpdateService()
    private let cutsProvider = CutsProvider()

    var filteredCuts = [Cuts]()
   
    @IBAction func sideMenuOnClick(_ sender: UIBarButtonItem) {
        present(SideMenuManager.default.menuLeftNavigationController!, animated: true, completion: nil)
    }
    
    fileprivate func setUpSideMenu() {
        
        // Define the menus
        let menuLeftNavigationController = UISideMenuNavigationController(rootViewController: SideMenuTableViewController())
        // UISideMenuNavigationController is a subclass of UINavigationController, so do any additional configuration
        // of it here like setting its viewControllers. If you're using storyboards, you'll want to do something like:
        // let menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as! UISideMenuNavigationController
        SideMenuManager.default.menuLeftNavigationController = menuLeftNavigationController
        
        // Enable gestures. The left and/or right menus must be set up above for these to work.
        // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
        SideMenuManager.default.menuAddPanGestureToPresent(toView: self.navigationController!.navigationBar)
        SideMenuManager.default.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
                
        // Set up a cool background image for demo purposes
        // SideMenuManager.default.menuAnimationBackgroundColor = UIColor(patternImage: UIImage(named: "background")!)
        
        //SideMenuManager.default.menuBlurEffectStyle = UIBlurEffectStyle.extraLight
        SideMenuManager.default.menuShadowOpacity = 1
        
        SideMenuManager.default.menuPresentMode = SideMenuManager.MenuPresentMode.menuSlideIn
        
        SideMenuManager.default.menuFadeStatusBar = false
        SideMenuManager.default.menuWidth = view.frame.width * 0.75
        
        SideMenuManager.default.menuAnimationTransformScaleFactor = 0.95
        SideMenuManager.default.menuAnimationFadeStrength = 0.5
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "navigation_back")
        navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
    }
    
    fileprivate func setUpSearchBar() {
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        // self.definesPresentationContext = false
        
        // navigationItem.searchController = searchController
        
        // searchController.searchBar.sizeToFit()
        // tableView.tableHeaderView = searchController.searchBar
        
        navigationItem.titleView = searchController.searchBar
    }
    
    fileprivate func setUpRefreshControl() {
        self.refreshControl?.backgroundColor = UIColor.clear
        self.refreshControl?.tintColor = UIColor.black
        self.refreshControl?.attributedTitle = NSAttributedString(string: CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "pull_to_refresh"))
        
        self.refreshControl?.addTarget(self, action: #selector(ElectricityWaterCutsTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        refreshCuts()
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    fileprivate func refreshCuts() {
        cutsProvider.createTable()
        // cutsProvider.upgradeTable()
        cutsUpdateHelper.prepareCutListToShow()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshCuts()
        
        setUpSideMenu()
        setUpSearchBar()
        setUpRefreshControl()
        
        // filteredCuts = cutsUpdateHelper.cutsForNotification!
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // update according to changed user settings
        if CutsGlobalVariables.sharedManager.refreshAfterSettingChange == true {
            refreshCuts()
            self.tableView.reloadData()
            CutsGlobalVariables.sharedManager.refreshAfterSettingChange = false
        }
        
        // localization
        slideMenuButton.title = CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "action_settings")
        searchController.searchBar.placeholder = CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "action_search")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if isFiltering() {
            return filteredCuts.count
        }
        return cutsUpdateHelper.cutListToShow!.count
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "CutsTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CutsTableViewCell  else {
            fatalError("The dequeued cell is not an instance of CutsTableViewCell.")
        }
        
        let cut : Cuts
        if isFiltering() {
            cut = filteredCuts[indexPath.row]
        } else {
            cut = cutsUpdateHelper.cutListToShow![indexPath.row]
        }
        cell.operatorInfo?.text = cut.operatorName
        cell.durationInfo?.text = (cut.startDate ?? "") + " - " + (cut.endDate ?? "")
        cell.detailedInfo?.text = (cut.reason ?? "") + "\n" + (cut.location ?? "")
        // cell.detailedInfo?.borderStyle = .none
        let imageName = CutsConstants.CUT_TYPE_ELECTRICITY == cut.type ? CutsConstants.CUT_TYPE_ELECTRICITY_IMAGE : CutsConstants.CUT_TYPE_WATER_IMAGE
        cell.cutImage?.image = UIImage(named: imageName)
                
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let shareAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "share") , handler: { (action:UITableViewRowAction, indexPath:IndexPath) -> Void in
            
            let cut = self.cutsUpdateHelper.cutListToShow![indexPath.row]
            let shareContent = cut.getPlainText()
            let activityViewController = UIActivityViewController(activityItems: [shareContent as NSString], applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: {})
            
            /*
            let shareController = UIAlertController(title: nil, message: "Share", preferredStyle: .alert)
            let shareMenu = UIAlertController(title: nil, message: "Share Cut", preferredStyle: .actionSheet)
            
            let appRateAction = UIAlertAction(title: "Share", style: UIAlertActionStyle.default, handler: nil)
            //let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            
            shareMenu.addAction(appRateAction)
            //rateMenu.addAction(cancelAction)
            
            self.present(shareMenu, animated: true, completion: nil)
             */
        })
        return [shareAction]
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredCuts = self.cutsUpdateHelper.cutListToShow!.filter({( cut : Cuts) -> Bool in
            // return (cut.detail?.lowercased().contains(searchText.lowercased()))!
            return CutsHelper.compareCutsStr(str1: cut.getSearchString(), str2: searchText)
        })
        tableView.reloadData()
    }
}
