//
//  CutsUpdateService.swift
//  electricitywatercuts
//
//  Created by nils on 25.04.2018.
//  Copyright © 2018 nils. All rights reserved.
//

import Foundation
import SwiftSoup

class CutsUpdateService {
    
    // weak var delegate: CutsDelegate?
    private let cutsProvider = CutsProvider()
    
    var cutListToShow: [Cuts]?
    
    init() {
        self.cutListToShow = [Cuts]()
    }
    
    func updateCutsAsPrevious() {
        // update as "previous"
        let value = String(describing: CutsProvider.CutsRecord.is_current) + "='F' "
        cutsProvider.update(condition: .EQUALS, value: value, conditionColumn: .is_current, conditionArg: "'T'")
    }
    
    func prepareCutListToShow() {
        refreshCuts()
        
        var conditionColumn: CutsProvider.CutsRecord? = nil
        var conditionArg: String? = nil
        
        let range = CutsHelper.getSelectedRangeChoice()
        if ("0" == range) {
            conditionColumn = CutsProvider.CutsRecord.is_current
            conditionArg = "'T'"
        }
        
        let orderCriteriaOption = CutsHelper.getSelectedOrderCriteriaChoice()
        let orderOption = CutsHelper.getSelectedOrderChoice()
            
        var sortOrderBy = CutsProvider.CutsRecord.end_date
        if("start" == orderCriteriaOption) {
            sortOrderBy = CutsProvider.CutsRecord.start_date
        }
        var sortOrder = " DESC"
        if("asc" == orderOption) {
            sortOrder = " ASC"
        }
        
        cutListToShow = cutsProvider.query(condition: .EQUALS, conditionColumn: conditionColumn, conditionArg: conditionArg, sortOrderBy: sortOrderBy, sortOrder: sortOrder)

    }
    
    func refreshCuts() -> [Cuts] {
        let urls: [String] = CutsConstants.CUTS_LINK_LIST
        
        updateCutsAsPrevious();
        
        var cutsList = [Cuts]()
        for i in 0..<urls.count {
            var temp = [Cuts]()
            if (urls[i].range(of: "bedas") != nil) {
                temp = getEuropeElectricityData(link: urls[i])
            } else if (urls[i].range(of: "ayedas") != nil) {
                temp = getAnatoliaElectricityData(link: urls[i]);
            } else if (urls[i].range(of: "iski") != nil) {
                temp = getWaterData(link: urls[i]);
            }
            
            for j in 0..<temp.count {
                cutsList.append(temp[j])
            }
        }
    
        return cutsProvider.insert(cutsList: cutsList);
    }

    func getEuropeElectricityData(link: String) -> [Cuts] {
        var electricalCuts = [Cuts]()
        
        let locale: Locale = Locale(identifier: "tr-TR")
        let formatter: DateFormatter = DateFormatter()
        let paramDateFormat = DateFormatter.dateFormat(fromTemplate: CutsConstants.yyyyMMdd, options: 0, locale: nil)
        formatter.locale = locale
        
        let cutDateFormat = DateFormatter.dateFormat(fromTemplate: CutsConstants.ddMMyyyy, options: 0, locale: Locale(identifier: "tr-TR"))
        
        var types = [String]() 
        types.append(CutsConstants.BEDAS_CUT_TYPE_PLANNED)
        types.append(CutsConstants.BEDAS_CUT_TYPE_INSTANTANEOUS)
        
        var date = Date()
        // look up for 5 days
        for _ in 0..<5 {
            for type in types {
                formatter.dateFormat = paramDateFormat
                let formattedDate = formatter.string(from: date)
                let formattedUrl : String = String(format: link, "0", type, formattedDate)
                let url = URL(string: formattedUrl)
                
                do {
                    let htmlContent = try String(contentsOf: url!, encoding: .utf8)
                    
                    //do{
                        let jsonData = htmlContent.data(using: .utf8)! as Data
                        do {
                            let dataJson = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
                            let resultArray = dataJson as? [[String:Any]]
                            for eCut in resultArray! {
                                let location = eCut["metin"] as? String
                                let startHour = eCut["saat1"] as? String
                                let endHour = eCut["saat2"] as? String
                                let reason = eCut["nedeni"] as? String
                                
                                let cut = Cuts()
                                cut.type = CutsConstants.CUT_TYPE_ELECTRICITY
                                cut.location = location
                                
                                formatter.dateFormat = cutDateFormat
                                let formattedDate = formatter.string(from: date)
                                
                                let cutStartDate: String = formattedDate + " " + (startHour ?? "")
                                cut.startDate = cutStartDate
                                
                                let cutEndDate: String = formattedDate + " " + (endHour ?? "")
                                cut.endDate = cutEndDate
                                
                                cut.reason = reason
                                cut.location = location
                                
                                var operatorName = String()
                                if let range = location?.range(of: "\\((.*?)İlçesi\\)", options: .regularExpression) {
                                    operatorName = String(location![range])
                                    if let index = operatorName.range(of: " İlçesi") {
                                        operatorName = String(operatorName[..<index.lowerBound])
                                        if let index = operatorName.range(of: "(") {
                                            operatorName = String(operatorName[index.upperBound...])
                                        }
                                    }
                                } else {
                                    if let index = location?.range(of: "İlçesi") {
                                        operatorName = String(location![..<index.lowerBound])
                                    }
                                }
                                cut.operatorName = operatorName
                                
                                cut.detail = (cut.operatorName ?? "") + " "
                                cut.detail?.append((cut.startDate ?? "") + "-")
                                cut.detail?.append((cut.endDate ?? "") + " ")
                                cut.detail?.append((cut.location ?? "") + " ")
                                cut.detail?.append((cut.reason ?? ""))
                                
                                electricalCuts.append(cut)
                            }
                        } catch {
                            print("error getting xml string: \(error)")
                        }
                   /* } catch {
                        print("could not unwrap data object for html content")
                    } */


                } catch {
                    print("could not unwrap data object for html content")
                }
                
                date = NSCalendar.current.date(byAdding: .day, //Here you can add year, month, hour, etc.
                    value: 1,  //Here you can add number of units
                    to: date)!
            }
                
        }
        
        return electricalCuts
    }
    
    func getAnatoliaElectricityData(link: String) -> [Cuts] {
        var electricalCuts = [Cuts]()
        
        let url = URL(string: link)
        
        do {
            let htmlContent = try String(contentsOf: url!, encoding: .utf8)
            do {
                let doc: Document = try SwiftSoup.parse(htmlContent)
                let cutDateList: Elements = try doc.select("table.table-responsive tr")
                for cutDate in cutDateList {
                    let cut = Cuts()
                    cut.type = CutsConstants.CUT_TYPE_ELECTRICITY
                    cut.reason = "Planlı Kesinti"
                    
                    let operatorName: String = try cutDate.attr("data-ilce")
                    cut.operatorName = operatorName
                    
                    var startDate: String = try cutDate.attr("data-tarih")
                    let dateParsed = startDate.components(separatedBy: ".")
                    let day: String = ("00" + dateParsed[0])
                    let month: String = ("00" + dateParsed[1])
                    let year: String = dateParsed[2]
                    var index = day.index(day.endIndex, offsetBy: -2)
                    startDate = String(day.suffix(from: index))
                    index = month.index(month.endIndex, offsetBy: -2)
                    startDate.append("." + String(month.suffix(from: index)))
                    startDate.append("." + year)
                    let endDate = startDate;
                    
                    let cutLocationList: Elements = cutDate.children()
                    var cutListStr: String = try cutLocationList.get(0).text();
                    cutListStr = cutListStr.replacingOccurrences(of: "\\s", with: " ")
                    
                    if let index = cutListStr.lowercased(with: Locale(identifier: "tr-TR")).range(of: "saat") {
                        let hourStr = String(cutListStr[..<index.lowerBound])
                        let hourArr = hourStr.components(separatedBy: " - ")
                        let startHour = hourArr[0]
                        let endHour = hourArr[1]
                        
                        cut.startDate = startDate + " " + startHour
                        cut.endDate = endDate + " " + endHour
                    }
                    
                    let location = try cutLocationList.get(1).text()
                    cut.location = location
                    
                    cut.operatorName = operatorName
                    
                    cut.detail = (cut.operatorName ?? "") + " "
                    cut.detail?.append((cut.startDate ?? "") + "-")
                    cut.detail?.append((cut.endDate ?? "") + " ")
                    cut.detail?.append((cut.location ?? "") + " ")
                    cut.detail?.append((cut.reason ?? ""))
                    
                    electricalCuts.append(cut)
                }
            } catch Exception.Error(let type, let message){
                print(message)
            } catch{
                print("error")
            }
        } catch {
            print("could not unwrap data object for html content")
        }
        
        return electricalCuts
    }

    func getWaterData(link: String) -> [Cuts] {
        var waterCuts = [Cuts]()
        
        let url = URL(string: link)
        
        do {
            let htmlContent = try String(contentsOf: url!, encoding: .utf8)
            do {
                let doc: Document = try SwiftSoup.parse(htmlContent)
                let cutItemsList: Elements = try doc.select("table.table-bordered td")
                var i = 2
                while(i < cutItemsList.size()) {
                    let cut = Cuts()
                    cut.type = CutsConstants.CUT_TYPE_WATER
                    
                    let operatorName: String = try cutItemsList.get(i).text();
                    cut.operatorName = operatorName
                    
                    let location = try cutItemsList.get(i+3).text()
                    cut.location = location
                    
                    let reason = try cutItemsList.get(i+6).text()
                    cut.reason = reason
                    
                    var startDate: String = try cutItemsList.get(i+9).text()
                    let dateArr = startDate.components(separatedBy: " - ")
                    startDate = dateArr[0]
                    startDate = CutsHelper.formatDate(dateStr: startDate, inputFormat: CutsConstants.dMyyyy, outputFormat: CutsConstants.ddMMyyyy);
                    let startHour = dateArr[1];
                    cut.startDate = startDate + " " + startHour
                    
                    let endDateTime: String = try cutItemsList.get(i+12).text()
                    if let index = endDateTime.range(of: "olarak ") {
                        var endDate = String(endDateTime[index.upperBound...])
                        if let index = endDate.range(of: " ") {
                            endDate = String(endDate[..<index.lowerBound])
                        }
                        endDate = CutsHelper.formatDate(dateStr: endDate, inputFormat: CutsConstants.dMyyyy, outputFormat: CutsConstants.ddMMyyyy)
                        
                        if let index = endDateTime.range(of: "saat ") {
                            var endHour = String(endDateTime[index.upperBound...])
                            if let index = endHour.range(of: " ") {
                                endHour = String(endHour[..<index.lowerBound])
                            }
                            cut.endDate = endDate + " " + endHour
                        }
                    }
                                        
                    cut.detail = (cut.operatorName ?? "") + " "
                    cut.detail?.append((cut.startDate ?? "") + "-")
                    cut.detail?.append((cut.endDate ?? "") + " ")
                    cut.detail?.append((cut.location ?? "") + " ")
                    cut.detail?.append((cut.reason ?? ""))
                    
                    waterCuts.append(cut)
                    
                    i = i + 16
                }
            } catch Exception.Error(let type, let message){
                print(message)
            } catch{
                print("error")
            }
        } catch {
            print("could not unwrap data object for html content")
        }
        
        return waterCuts
    }
    
    func organizeCutsDB() {
        let oneMonthBefore = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        let locale: Locale = Locale(identifier: "en_US_POSIX")
        let formatter: DateFormatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = CutsConstants.yyyyMMddTHHmmssZ
        let oneMonthBeforeStr = formatter.string(from: oneMonthBefore!)
    
        cutsProvider.delete(condition: .SEARCH, conditionColumn: .order_end_date, conditionArg: "<'" + oneMonthBeforeStr + "'")
    }
    
    func prepareNotificationContent() -> String {
        var cutsListStr : String = "";

        if (CutsHelper.getSelectedFrequencyChoice() != "-1") {
            cutsProvider.createTable()
            // cutsProvider.upgradeTable()
            let cutsForNotification = refreshCuts()
            
            for cut in cutsForNotification {
                var cutTitle = CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "water_label");
                if (cut.type == CutsConstants.CUT_TYPE_ELECTRICITY) {
                    cutTitle = CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "electricity_label");
                }
                cutTitle = NSString(format: CutsHelper.localizedText(language: CutsHelper.getLocaleForApp(), key: "cuts_notify_header") as NSString, cutTitle) as String
                
                cutsListStr.append(cutTitle)
                
                var detailedText: String = (cut.location ?? "")
                detailedText.append(" " + (cut.startDate ?? ""))
                detailedText.append(" - " + (cut.endDate ?? ""))
                
                cutsListStr.append(detailedText)
                
                /* cutsNotificationBuilder.setContentTitle(cutTitle)
                 .setContentText(detailedText)
                 .setStyle(new NotificationCompat.BigTextStyle().bigText(detailedText)); */
                
            }
                /*  for (Cuts cut : cutsForNotification) {
                 
                 cutTitle = getString(R.string.water_label);
                 if ("e".equals(cut.getType()))
                 cutTitle = getString(R.string.electricity_label);
                 
                 detailedText += cutTitle + ": " + cut.getLocation() + " " +
                 cut.getStartDate() + " - " + cut.getEndDate() + System.getProperty("line.separator");
                 
                 cutsNotificationBuilder.setStyle(new NotificationCompat.BigTextStyle().bigText(detailedText))
                 .setNumber(++numOfMessages);
                 
                 }
                 */
            
            /*       if(bundle.getString(CutsConstants.INTENT_CUTS_FREQ)!=null) {
             String freqPreferenceStr = bundle.getString(CutsConstants.INTENT_CUTS_FREQ);
             freqPreference = Integer.parseInt(freqPreferenceStr);
             registerAlarm();
             } else if (bundle.getBoolean(CutsConstants.INTENT_CUTS_NOTIFICATION_FLAG, false)) {
             notificationFlag = true;
             }
             */
        }
        
        return cutsListStr
    }
    
}
