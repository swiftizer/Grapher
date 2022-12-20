//
//  VC+TextField.swift
//  Grapher
//
//  Created by Сергей Николаев on 24.11.2022.
//

import UIKit

// MARK: - UITextFieldDelegate
extension SceneViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        showLimitFields()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        newSurfaceNeedsToBuild()
        return true
    }
}
