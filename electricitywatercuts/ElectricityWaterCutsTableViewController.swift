//
//  ElectricityWaterCutsTableViewController.swift
//  electricitywatercuts
//
//  Created by nils on 24.04.2018.
//  Copyright © 2018 nils. All rights reserved.
//

import UIKit

class ElectricityWaterCutsTableViewController: UITableViewController {
    
    private let cutsUpdateHelper = CutsUpdateService()
    private let cutsProvider = CutsProvider()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cutsUpdateHelper.delegate = self
        // cutsProvider.createTable()
        cutsUpdateHelper.refreshCuts(notificationFlag: false)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        return cutsUpdateHelper.cutsForNotification!.count
    }

  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "CutsTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? CutsTableViewCell  else {
            fatalError("The dequeued cell is not an instance of CutsTableViewCell.")
        }
        
        let cut = cutsUpdateHelper.cutsForNotification![indexPath.row]
        cell.operatorInfo?.text = cut.operatorName
        cell.durationInfo?.text = (cut.startDate ?? "") + " - " + (cut.endDate ?? "")
        cell.detailedInfo?.text = cut.location
        // cell.detailedInfo?.borderStyle = .none
        let imageName = CutsConstants.CUT_TYPE_ELECTRICITY == cut.type ? CutsConstants.CUT_TYPE_ELECTRICITY_IMAGE : CutsConstants.CUT_TYPE_WATER_IMAGE
        cell.cutImage?.image = UIImage(named: imageName)
                
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let shareAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Share" , handler: { (action:UITableViewRowAction, indexPath:IndexPath) -> Void in
            
            let cut = self.cutsUpdateHelper.cutsForNotification![indexPath.row]
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}