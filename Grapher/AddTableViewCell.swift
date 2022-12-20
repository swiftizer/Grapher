//
//  AddTableViewCell.swift
//  Grapher
//
//  Created by Сергей Николаев on 09.12.2022.
//

import UIKit

final class AddTableViewCell: UITableViewCell {

    // MARK: - Public Properties

    private let containerView = UIView()

    // MARK: - Private Properties

    private let plusImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "plus.circle")?.withTintColor(UIColor.label, renderingMode: .alwaysOriginal))
        imageView.contentMode = .scaleToFill
        imageView.tintColor = .white
        return imageView
    }()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupContainer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle

    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayout()
    }

    // MARK: - Private Methods

    private func setupContainer() {
        selectionStyle = .none
        backgroundColor = .clear

        addSubview(containerView)
        containerView.addSubview(plusImageView)
    }

    private func setupLayout() {
        containerView.pin.all()

        plusImageView.pin.center()
    }
}
