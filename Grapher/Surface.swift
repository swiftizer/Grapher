//
//  Surface.swift
//  Grapher
//
//  Created by Сергей Николаев on 24.11.2022.
//

import Foundation
import SceneKit

protocol SurfaceDiscription {
    func showSurface(feedback: Bool)
    func removeSurface()
    func showProgress()
    func hideProgress()
}

final class Surface: SurfaceDiscription {
    private var node = SCNNode()
    private var nodeInv = SCNNode()
    private var rangeX: CoordinatesRange!
    private var rangeY: CoordinatesRange!
    private var nodesInAxises: NNodes!
    private var color: UIColor!
    private var expression: String!
    private weak var vc:SceneViewController?
    private let nThreads: Int
    var stopFlag = false

    init(node: SCNNode = SCNNode(), nodeInv: SCNNode = SCNNode(), rangeX: CoordinatesRange, rangeY: CoordinatesRange, nodesInAxises: NNodes, expression: String, vc: SceneViewController?, nThreads: Int, color: UIColor) {
        self.rangeX = rangeX
        self.rangeY = rangeY
        self.nodesInAxises = nodesInAxises
        self.expression = expression
        self.vc = vc
        self.nThreads = nThreads
        self.color = color
    }

    private func generateSurface(feedback: Bool = true, completion: @escaping (Bool) -> Void) {
        guard let vc = vc,
              let nodesInAxises = nodesInAxises,
              let rangeX = rangeX,
              let rangeY = rangeY,
              let expression = expression
        else { return }

        var vertices = [SCNVector3](repeating: SCNVector3(), count: (nodesInAxises.x + 1) * (nodesInAxises.y + 1))
        let stepX = (rangeX.to - rangeX.from) / Double(nodesInAxises.x)
        let stepY = (rangeY.to - rangeY.from) / Double(nodesInAxises.y)


        var progress: Float = 0.0 {
            didSet {
                if progress <= 1.01 {
                    vc.progressView.progress = progress
                    vc.progressLabel.text = "\(Int(progress * 100)) %"
                }
            }
        }

        var _x = [Double](repeating: 0.0, count: nThreads)
        var _y = [Double](repeating: 0.0, count: nThreads)
        var _z = [Double](repeating: 0.0, count: nThreads)

        var xRanges = [[Int]]()

        for i in 0..<nThreads {
            xRanges.append(Array(stride(from: Int(round(Float(i)/Float(nThreads)*Float(nodesInAxises.x))), to: Int(round(Float(i+1)/Float(nThreads)*Float(nodesInAxises.x))) + 1, by: 1)))
        }

        let group = DispatchGroup()

        for i in 0..<nThreads {
            group.enter()
            Thread.detachNewThread { [range = xRanges[i], rangeX, rangeY, i] in
                for i_x in range {
                    _x[i] = Double(Double(i_x) * stepX + Double(rangeX.from))
                    for i_y in 0...nodesInAxises.y {
                        if self.stopFlag {
                            DispatchQueue.main.async {
                                completion(false)
                            }
                            return
                        }
                        _y[i] = Double(Double(i_y) * stepY + Double(rangeY.from))
                        do {
                            _z[i] = try expression.evaluate(["x": _x[i], "y": _y[i]])
                        } catch {
                            DispatchQueue.main.async {
                                AlertManager.shared.showAlert(presentTo: vc, title: "Ошибка", message: error.localizedDescription)
                                completion(false)
                            }
                            //                            group.leave()
                            return
                        }
                        vertices[i_x*(nodesInAxises.y + 1) + i_y] = SCNVector3(_x[i], _y[i], _z[i])
                        if i == 0 {
                            DispatchQueue.main.async {
                                progress = Float(i_x * (nodesInAxises.y) + i_y) / Float(nodesInAxises.x + 1) / Float(nodesInAxises.y + 1) * Float(self.nThreads)
                            }
                        }
                    }
                }

                group.leave()
            }
        }

        group.notify(queue: .main) {

            var indices = [UInt32]()
            var firstDot: UInt32
            var thirdDot: UInt32

            for i_x in 0..<(nodesInAxises.x) {
                for i_y in 0..<(nodesInAxises.y) {
                    firstDot = UInt32(i_y + i_x * (nodesInAxises.y + 1))
                    thirdDot = UInt32((i_x + 1) * (nodesInAxises.y + 1) + i_y)
                    indices += [firstDot, firstDot + 1, thirdDot]
                    indices += [thirdDot, firstDot + 1, thirdDot + 1]
                }
            }

            let source = SCNGeometrySource(vertices: vertices)

            let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)

            let geometry = SCNGeometry(sources: [source], elements: [element])
            geometry.firstMaterial?.diffuse.contents = self.color

            let node = SCNNode(geometry: geometry)


            indices = []

            for i_x in 0..<(nodesInAxises.x) {
                for i_y in 0..<(nodesInAxises.y) {
                    firstDot = UInt32(i_y + i_x * (nodesInAxises.y + 1))
                    thirdDot = UInt32((i_x + 1) * (nodesInAxises.y + 1) + i_y)
                    indices += [thirdDot, firstDot + 1, firstDot]
                    indices += [thirdDot, thirdDot + 1, firstDot + 1]
                }
            }

            let element2 = SCNGeometryElement(indices: indices, primitiveType: .triangles)

            let geometry2 = SCNGeometry(sources: [source], elements: [element2])
            geometry2.firstMaterial?.diffuse.contents = self.color

            let node2 = SCNNode(geometry: geometry2)

            if feedback {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                vc.expressionTextField.repaintBorder(borderWidth: 0)
            }
            self.node = node
            self.nodeInv = node2
            completion(true)
        }
    }

    func showSurface(feedback: Bool = true) {
        guard let vc = vc else { return }
        showProgress()

        vc.expressionTextField.isUserInteractionEnabled = false
        let start = CACurrentMediaTime()
        generateSurface { res in
            if res {
                self.hideProgress()
                vc.expressionTextField.isUserInteractionEnabled = true
                vc.scene.rootNode.addChildNode(self.node)
                vc.scene.rootNode.addChildNode(self.nodeInv)
            } else {
                vc.expressionTextField.isUserInteractionEnabled = true
                vc.expressionTextField.invalidAnimation()
                vc.expressionTextField.repaintBorder()
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            print("-------------------------------\ntime[\(self.nThreads)] = \(CACurrentMediaTime() - start)\n-------------------------------")
            self.hideProgress()
        }
    }

    func removeSurface() {
        node.removeFromParentNode()
        nodeInv.removeFromParentNode()
    }

    func showProgress() {
        guard let vc = vc else { return }
        UIView.animate(withDuration: 0.3) {
            [vc.progressView, vc.activityIndicator].forEach {
                $0.alpha = 1
            }
        }
    }

    func hideProgress() {
        guard let vc = vc else { return }
        UIView.animate(withDuration: 0.3) {
            [vc.progressView, vc.activityIndicator].forEach {
                $0.alpha = 0
            }
        }
    }

    deinit {
        print("GRAPH DEINITED")
    }
}
