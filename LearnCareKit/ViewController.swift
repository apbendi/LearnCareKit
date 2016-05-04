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

    private var store: OCKCarePlanStore? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        store = OCKCarePlanStore(persistenceDirectoryURL: storeDirectory)

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
        store?.addActivity(intActivity) { (didAdd, error) in
            if didAdd {
                print("Added intervention activity")
            } else if let error = error {
                print("Error adding intervention activity: \(error.localizedDescription)")
            } else {
                print("Did not at intervention activity")
            }
        }

        let asActivity = OCKCarePlanActivity.assessmentWithIdentifier("AssessmentActivity",
                                                                      groupIdentifier: nil,
                                                                      title: "First Assessment",
                                                                      text: nil,
                                                                      tintColor: nil,
                                                                      resultResettable: true,
                                                                      schedule: schedule,
                                                                      userInfo: nil)
        store?.addActivity(asActivity) { (didAdd, error) in
            if didAdd {
                print("Added assessment activity")
            } else if let error = error {
                print("Error adding assessment activity: \(error.localizedDescription)")
            } else {
                print("Did not at assessment activity")
            }
        }
    }

    // MARK: Target-Action

    @IBAction func didPressCare(sender: UIButton) {
        guard let store = store else {
            return
        }

        let careVC = OCKCareCardViewController(carePlanStore: store)
        showViewController(careVC, sender: self)
    }

    @IBAction func didPressTrack(sender: UIButton) {
        guard let store = store else {
            return
        }

        let trackVC = OCKSymptomTrackerViewController(carePlanStore: store)
        showViewController(trackVC, sender: self)
    }
}

