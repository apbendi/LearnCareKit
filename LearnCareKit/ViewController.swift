import UIKit
import CareKit
import ResearchKit

class ViewController: UIViewController {

    private static var storeDirectory: NSURL {
        let searchPaths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
        let applicationSupportPath = searchPaths[0]
        let persistenceDirectoryURL = NSURL(fileURLWithPath: applicationSupportPath)

        if !NSFileManager.defaultManager().fileExistsAtPath(persistenceDirectoryURL.absoluteString, isDirectory: nil) {
            try! NSFileManager.defaultManager().createDirectoryAtURL(persistenceDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        return persistenceDirectoryURL
    }

    private let store: OCKCarePlanStore = OCKCarePlanStore(persistenceDirectoryURL: storeDirectory)
    private var trackViewController: OCKSymptomTrackerViewController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

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
                print("Error adding intervention activity: \(error.localizedDescription)")
            } else {
                print("Did not at intervention activity")
            }
        }

        let firstActivity = OCKCarePlanActivity.assessmentWithIdentifier("FirstAssessmentActivity",
                                                                      groupIdentifier: nil,
                                                                      title: "First Assessment",
                                                                      text: nil,
                                                                      tintColor: nil,
                                                                      resultResettable: true,
                                                                      schedule: schedule,
                                                                      userInfo: nil)

        let secondActivity = OCKCarePlanActivity.assessmentWithIdentifier("SecondAssessmentActivity",
                                                                      groupIdentifier: nil,
                                                                      title: "Second Assessment",
                                                                      text: nil,
                                                                      tintColor: nil,
                                                                      resultResettable: true,
                                                                      schedule: schedule,
                                                                      userInfo: nil)

        [firstActivity, secondActivity].forEach { asActivity in
            store.addActivity(asActivity) { (didAdd, error) in
                if didAdd {
                    print("Added assessment \(asActivity)")
                } else if let error = error {
                    print("Error adding assessment activity: \(error.localizedDescription)")
                } else {
                    print("Did not at assessment activity")
                }
            }
        }
    }
}

// MARK: Target-Action

private extension ViewController {
    @IBAction func didPressCare(sender: UIButton) {
        let careVC = OCKCareCardViewController(carePlanStore: store)
        showViewController(careVC, sender: self)
    }

    @IBAction func didPressTrack(sender: UIButton) {
        guard let trackViewController = trackViewController else {
            self.trackViewController = OCKSymptomTrackerViewController(carePlanStore: store)
            self.trackViewController?.delegate = self
            didPressTrack(sender)
            return
        }

        showViewController(trackViewController, sender: self)
    }
}

// MARK: OCKSymptomTrackerViewControllerDelegate

extension ViewController: OCKSymptomTrackerViewControllerDelegate {
    func symptomTrackerViewController(viewController: OCKSymptomTrackerViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {
        print("Selected: \(assessmentEvent)")

        guard assessmentEvent.isAvailable, let task = taskFor(assessmentEvent: assessmentEvent) else {
            return
        }

        let taskVC = ORKTaskViewController(task: task, taskRunUUID: nil)
        taskVC.delegate = self
        presentViewController(taskVC, animated: true, completion: nil)
    }
}

// MARK: Task Generators

private extension ViewController {
    func taskFor(assessmentEvent event: OCKCarePlanEvent) -> ORKTask? {
        switch event.activity.identifier {
        case "FirstAssessmentActivity":
            let answer = ORKNumericAnswerFormat(style: .Decimal, unit: "lbs", minimum: 60, maximum: 500)
            let question = ORKQuestionStep(identifier: "FistAssessmentWeightQuestion", title: "What is your weight today?", answer: answer)
            return ORKOrderedTask(identifier: "FirstAssessmentTask", steps: [question])
        default:
            return nil
        }
    }
}

// MARK: ORKTaskViewControllerDelegate

extension ViewController: ORKTaskViewControllerDelegate {

    func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        defer {
            dismissViewControllerAnimated(true, completion: nil)
        }

        guard nil == error, case .Completed = reason,
            let event = trackViewController?.lastSelectedAssessmentEvent else {
            return
        }

        print("Returned from \(event.activity.identifier)")
    }

}

extension OCKCarePlanEvent {
    var isAvailable: Bool {
        return state == .Initial ||
                state == .NotCompleted ||
                (state == .Completed && activity.resultResettable)
    }
}

