import UIKit

class MessagesViewController: UIViewController {
    private var messages: [String] = []
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupTableView()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewMessage), name: Notification.Name("newMessageReceived"), object: nil)
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    @objc private func handleNewMessage(_ notification: Notification) {
        if let message = notification.object as? String {
            messages.insert(message, at: 0) // Insert at the top
            tableView.reloadData()
        }
    }
}

extension MessagesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        cell.textLabel?.text = messages[indexPath.row]
        cell.textLabel?.numberOfLines = 0 // Allow multiline messages
        return cell
    }
}
