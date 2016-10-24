
import UIKit
import SafariServices

class SettingsViewController: UITableViewController {
    
    @IBOutlet var switchOfflineMode: UISwitch!
    @IBOutlet var switchShowDownloadDialog: UISwitch!
    @IBOutlet var switchFastcharge: UISwitch!
    @IBOutlet var segmentControlMapType: UISegmentedControl!
    @IBOutlet var cellSchuko: UITableViewCell!
    @IBOutlet var cellChademo: UITableViewCell!
    @IBOutlet var cellCCS: UITableViewCell!
    @IBOutlet var cellType2: UITableViewCell!
    @IBOutlet var cellTesla: UITableViewCell!
    @IBOutlet var textFieldAmps: UITextField!
    @IBOutlet var labelCacheSize: UILabel!
    @IBOutlet var buttonDeleteCache: UIButton!
    @IBOutlet var buttonAppVersion: UIButton!
    
    let CONNECTION_ID_SCHUKO = 28
    let CONNECTION_ID_CHADEMO = 2
    let CONNECTION_ID_TYPE2 = 25
    let CONNECTION_ID_TESLA_SUPERCHARGER = 27
    let CONNECTION_ID_CCS = 33
    
    var connectionTypeIDs = [Int]()
    
    lazy var dataManager: DataManager = DataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Customize navigation bar appearance.
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 42/255, green: 61/255, blue: 77/255, alpha: 1.0)
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadUserSettingsToViews()
        getAndLoadCacheSize()
        displayAppVersionString()
    }
    
    @IBAction func cancelButtonClicked(){
        dismissSettingsViewController()
    }
    
    @IBAction func doneButtonClicked(){
        saveUserSettings()
        dismissSettingsViewController()
    }
    
    @IBAction func appVersionButtonClicked(){
        showWhatsNewView()
    }
    
    func showWhatsNewView(){
        // Show Welcome screen
        // Create a new "WelcomeStoryBoard" instance.
        let storyboard = UIStoryboard(name: "WelcomeStoryboard", bundle: nil)
        // Create an instance of the storyboard's initial view controller.
        let controller = storyboard.instantiateViewController(withIdentifier: "InitialController") as UIViewController
        // Display the new view controller.
        present(controller, animated: true, completion: nil)
    }
    
    func displayAppVersionString(){
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.buttonAppVersion.setTitle(version, for: UIControlState())
        }
    }
    
    func getAndLoadCacheSize(){
        let cacheSizeInMB = dataManager.getDataFilesSize() / 1000000
        labelCacheSize.text = String(format: "%d Mb", cacheSizeInMB)
    }
    
    func loadUserSettingsToViews(){
        let defaults = UserDefaults.standard
        switchOfflineMode.setOn(defaults.bool(forKey: "offlineMode"), animated: true)
        switchShowDownloadDialog.setOn(defaults.bool(forKey: "showDownloadDialog"), animated: true)
        switchFastcharge.setOn(defaults.bool(forKey: "fastchargeOnly"), animated: true)
        if let connectionTypeIDsFromSettings = UserDefaults.standard.array(forKey: "connectionFilterIds") {
            
            for id in connectionTypeIDsFromSettings {
                let idAsInt = id as! Int
                connectionTypeIDs.append(idAsInt)
                if (idAsInt == CONNECTION_ID_SCHUKO){
                   cellSchuko.accessoryType = .checkmark
                } else if (idAsInt == CONNECTION_ID_TYPE2) {
                    cellType2.accessoryType = .checkmark
                } else if (idAsInt == CONNECTION_ID_CHADEMO) {
                    cellChademo.accessoryType = .checkmark
                } else if (idAsInt == CONNECTION_ID_TESLA_SUPERCHARGER) {
                    cellTesla.accessoryType = .checkmark
                } else if (idAsInt == CONNECTION_ID_CCS) {
                    cellCCS.accessoryType = .checkmark
                }
            }
        }
        
        let ampsMinimumFromSettings = UserDefaults.standard.integer(forKey: "minAmps")
        if (ampsMinimumFromSettings > 0) {
            textFieldAmps.text = String(ampsMinimumFromSettings)
        }
    
        segmentControlMapType.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "mapType")

    }
    
    func saveUserSettings(){
        
        // Store user preferences
        let defaults = UserDefaults.standard
        // Offline Mode
        defaults.set(switchOfflineMode.isOn, forKey: "offlineMode")
        // Show Download Dialog
        defaults.set(switchShowDownloadDialog.isOn, forKey: "showDownloadDialog")
        // Fastcharging Only
        defaults.set(switchFastcharge.isOn, forKey: "fastchargeOnly")
        // Map Type
        defaults.set(segmentControlMapType.selectedSegmentIndex, forKey: "mapType")
        // Connection Type IDs
        defaults.set(connectionTypeIDs, forKey: "connectionFilterIds")
        // Min Amps
        let minAmps = Int(textFieldAmps.text!)
        if minAmps != nil {
            defaults.set(minAmps!, forKey: "minAmps")
        } else {
            defaults.set(0, forKey: "minAmps")
        }
        
        // Post Notification
        NotificationCenter.default.post(name: Notification.Name(rawValue: "SettingsUpdate"), object: nil, userInfo: nil)
        
    }
    
    func dismissSettingsViewController(){
        dismiss(animated: true) { () -> Void in
            
        }
        
    }
    
    func connectionTypeFilterToggle(_ connectionType: Int) -> Bool {
        if let _ = connectionTypeIDs.index(of: connectionType){
            deleteTypeFromConnectionFilterArray(connectionType)
            //connectionTypeIDs.removeAtIndex(foundAtIndex)
            return false
            
        } else {
            connectionTypeIDs.append(connectionType)
            return true
        }
    }

    func deleteTypeFromConnectionFilterArray(_ connectionType: Int){
        connectionTypeIDs = connectionTypeIDs.filter{$0 != connectionType}
    }
    
    func showSourceCodeOnGitHub(){
        // Send user to the GitHub repo page
        let safariViewController = SFSafariViewController(url: URL(string: "https://github.com/archpoint/sparkmap")!)
        self.present(safariViewController, animated: true, completion: nil)
    }
    
    func userWantsToRateApp(){
        UIApplication.shared.openURL(URL(string : "itms-apps://itunes.apple.com/app/id1081587641")!)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)
        let section = (indexPath as NSIndexPath).section
        let row = (indexPath as NSIndexPath).row
        
        if (section == 1){
            if (row == 0) {
                //CCS
                if (connectionTypeFilterToggle(CONNECTION_ID_CCS)){
                    cell?.accessoryType = .checkmark
                } else {
                    cell?.accessoryType = .none
                }
                }
            if (row == 1) {
                //Chuko
                if (connectionTypeFilterToggle(CONNECTION_ID_SCHUKO)){
                    cell?.accessoryType = .checkmark
                } else {
                    cell?.accessoryType = .none
                }
            } else if (row == 2) {
                //Chademo
                if (connectionTypeFilterToggle(CONNECTION_ID_CHADEMO)){
                    cell?.accessoryType = .checkmark
                } else {
                    cell?.accessoryType = .none
                }

            } else if (row == 3) {
                // Type 2
                if (connectionTypeFilterToggle(CONNECTION_ID_TYPE2)){
                    cell?.accessoryType = .checkmark
                } else {
                    cell?.accessoryType = .none
                }
            } else if (row == 4) {
                // Tesla Supercharger
                if (connectionTypeFilterToggle(CONNECTION_ID_TESLA_SUPERCHARGER)){
                    cell?.accessoryType = .checkmark
                } else {
                    cell?.accessoryType = .none
                }
            }
        } else if (section == 4) {
            if (row == 1) {
                showSourceCodeOnGitHub()
            } else if (row == 2) {
                userWantsToRateApp()
            }
        }
    }
}
