import UIKit

class MessagesViewController: UIViewController, UITableViewDataSource {
    private let tableView = UITableView()
    private var logs: [String] = ["Welcome! Logs will appear here."]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        tableView.dataSource = self
        tableView.frame = view.bounds
        view.addSubview(tableView)
    }

    func addLog(_ message: String) {
        logs.append(message)
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "LogCell")
        cell.textLabel?.text = logs[indexPath.row]
        cell.detailTextLabel?.text = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        return cell
    }
}
