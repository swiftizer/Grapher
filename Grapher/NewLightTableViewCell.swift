//
//  NewLightTableViewCell.swift
//  Grapher
//
//  Created by Сергей Николаев on 09.12.2022.
//

import UIKit

final class NewLightTableViewCell: UITableViewCell {
    // MARK: - Public Properties
    let xTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(
            string: "x:",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.4)]
        )
        return textField
    }()

    let yTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(
            string: "y: ",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.4)]
        )
        return textField
    }()

    let zTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(
            string: "z: ",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.4)]
        )
        return textField
    }()

    let containerView = UIView()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            self.setupContainer()
        }
//        setupContainer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle

    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayout()
    }

    func appear(vc: SceneViewController) {
        [xTextField, yTextField, zTextField].forEach { $0.delegate = vc }
        UIView.animate(withDuration: 0.3, delay: 0) {
            self.xTextField.alpha = 1
            self.yTextField.alpha = 1
            self.zTextField.alpha = 1
        }
    }

    func disappear() {
        self.xTextField.alpha = 0
        self.yTextField.alpha = 0
        self.zTextField.alpha = 0
    }

    // MARK: - Private Methods

    private func setupContainer() {
        selectionStyle = .none
        backgroundColor = .clear

        addSubview(xTextField)
        addSubview(yTextField)
        addSubview(zTextField)
        [xTextField, yTextField, zTextField].forEach {
            $0.font = UIFont.boldSystemFont(ofSize: 16)
            $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 50))
            $0.layer.cornerRadius = 15
            $0.autocorrectionType = .no
            $0.leftViewMode = .always
            $0.keyboardType = .numbersAndPunctuation
            $0.returnKeyType = .done
            $0.clearButtonMode = .whileEditing
            $0.backgroundColor = .systemGray6
            $0.textColor = .label
            $0.tintColor = .label
            $0.returnKeyType = .done
            $0.alpha = 0
        }
    }

    private func setupLayout() {
        xTextField.pin
            .top(5)
            .bottom(5)
            .left(5)
            .width((contentView.frame.width - 20)/3)

        yTextField.pin
            .centerLeft(to: xTextField.anchor.centerRight)
            .height(of: xTextField)
            .marginLeft(5)
            .width((contentView.frame.width - 20)/3)

        zTextField.pin
            .centerLeft(to: yTextField.anchor.centerRight)
            .height(of: xTextField)
            .marginLeft(5)
            .width((contentView.frame.width - 20)/3)
    }
}
