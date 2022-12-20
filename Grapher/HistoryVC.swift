//
//  File.swift
//  Grapher
//
//  Created by Сергей Николаев on 10.12.2022.
//

import UIKit
import PinLayout

final class HistoryVC: UIViewController {
    let tableView = UITableView()
    var expressions = [String]()
    weak var rootVC: SceneViewController?

    init(root: SceneViewController) {
        super.init(nibName: nil, bundle: nil)
        self.rootVC = root
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.pin.all()
    }

    private func setup() {
        view.addSubview(tableView)
        expressions = UserDefaults.standard.object(forKey: "surfaces") as? [String] ?? []
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.allowsMultipleSelectionDuringEditing = false
    }
}

extension HistoryVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        expressions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let expression = expressions.reversed()[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = "\(expression)"
        content.image = UIImage(systemName: "move.3d")//?.withTintColor(UIColor.yellow, renderingMode: .alwaysOriginal)

        cell.contentConfiguration = content
        cell.backgroundColor = .systemBackground
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        rootVC?.dismiss(animated: true)
        rootVC?.expressionTextField.text = expressions.reversed()[indexPath.row]
        rootVC?.newSurfaceNeedsToBuild()
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // remove the item from the data model
            print("del")
            
            // delete the table view row
            expressions.remove(at: expressions.count - indexPath.row - 1)
            UserDefaults.standard.set(expressions, forKey: "surfaces")
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            // Not used in our example, but if you were adding a new row, this is where you would do it.
        }
    }
}
