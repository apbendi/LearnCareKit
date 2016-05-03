import UIKit
import CareKit

class ViewController: UIViewController {

    private let storeDirectory: NSURL =  {
        let searchPaths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let applicationSupportPath = searchPaths[0]
        let persistenceDirectoryURL = NSURL(fileURLWithPath: applicationSupportPath)

        if !NSFileManager.defaultManager().fileExistsAtPath(persistenceDirectoryURL.absoluteString, isDirectory: nil) {
            try! NSFileManager.defaultManager().createDirectoryAtURL(persistenceDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        return persistenceDirectoryURL
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let store = OCKCarePlanStore(persistenceDirectoryURL: storeDirectory)

        let components = NSCalendar.currentCalendar().componentsInTimeZone(NSTimeZone.defaultTimeZone(), fromDate: NSDate())
        let schedule = OCKCareSchedule.dailyScheduleWithStartDate(components, occurrencesPerDay: 1)

        let intActivity = OCKCarePlanActivity.interventionWithIdentifier("InterventionActivity",
                                                                      groupIdentifier: nil,
                                                                      title: "First Intervention",
                                                                      text: nil,
                                                                      tintColor: nil,
                                                                      instructions: nil,
                                                                      imageURL: nil,
                                                                      schedule: schedule,
                                                                      userInfo: nil)
        store.addActivity(intActivity) { (didAdd, error) in
            if didAdd {
                print("Added intervention activity")
            } else if let error = error {
                print("Error adding activity: \(error.localizedDescription)")
            } else {
                print("Did not at intervention activity")
            }
        }


        let careVC = OCKCareCardViewController(carePlanStore: store)

        presentViewController(careVC, animated: true, completion: nil)
    }
}
