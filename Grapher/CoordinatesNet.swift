//
//  Net.swift
//  Grapher
//
//  Created by Сергей Николаев on 04.12.2022.
//

import Foundation
import SceneKit

final class CoordinatesNet {
    private var xFrom = 0.0
    private var xTo = 0.0
    private var yFrom = 0.0
    private var yTo = 0.0
    private var elements = [SCNNode]()
    private weak var scene: SCNScene?

    init(xFrom: Double, xTo: Double, yFrom: Double, yTo: Double, scene: SCNScene?) {
        self.xFrom = xFrom
        self.xTo = xTo
        self.yFrom = yFrom
        self.yTo = yTo
        self.scene = scene
    }

    func draw() {
        guard let scene = scene else { return }
        let Oxg = SCNCylinder(radius: 0.1, height: (xTo - xFrom + 10))
        Oxg.firstMaterial?.diffuse.contents = UIColor.red
        let Oyg = SCNCylinder(radius: 0.1, height: (yTo - yFrom + 10))
        Oyg.firstMaterial?.diffuse.contents = UIColor.blue
        let Ozg = SCNCylinder(radius: 0.1, height: 30)
        Ozg.firstMaterial?.diffuse.contents = UIColor.yellow
//        let Ox = SCNNode(geometry: SCNCylinder(radius: 0.1, height: 35)).
        let Ox = SCNNode(geometry: Oxg)
        let Oy = SCNNode(geometry: Oyg)
        let Oz = SCNNode(geometry: Ozg)
        let OxCone = SCNNode(geometry: SCNCone(topRadius: 0.0, bottomRadius: 0.25, height: 0.8))
        let OyCone = SCNNode(geometry: SCNCone(topRadius: 0.0, bottomRadius: 0.25, height: 0.8))
        let OzCone = SCNNode(geometry: SCNCone(topRadius: 0.0, bottomRadius: 0.25, height: 0.8))
        Ox.position = SCNVector3(x: Float(xTo + xFrom)/2, y: 0, z: 0)
        Oy.position = SCNVector3(x: 0, y: Float(yTo + yFrom)/2, z: 0)
        Oz.position = SCNVector3(x: 0, y: 0, z: 0)
        OxCone.position = SCNVector3(x: Float(xTo) + 5, y: 0, z: 0)
        OyCone.position = SCNVector3(x: 0, y: Float(yTo) + 5, z: 0)
        OzCone.position = SCNVector3(x: 0, y: 0, z: 15)
        Ox.eulerAngles.z = Float.pi / 2
        Oz.eulerAngles.x = Float.pi / 2
        OzCone.eulerAngles.x = Float.pi / 2
        OxCone.eulerAngles.z = -Float.pi / 2
        [Ox, Oy, Oz, OxCone, OyCone, OzCone].forEach { scene.rootNode.addChildNode($0); elements.append($0) }

        for i in Int(xFrom - 5)...Int(xTo + 5) {
            for j in Int(yFrom - 5)...Int(yTo + 5) {
                var radius = 0.04
                if i % 5 == 0 && j % 5 == 0 {
                    radius = 0.12
                }
                let dot = SCNNode(geometry: SCNSphere(radius: radius))
                dot.position = SCNVector3(x: Float(i), y: Float(j), z: 0)
                scene.rootNode.addChildNode(dot)
                elements.append(dot)
            }
        }
    }

    func clean() {
        elements.forEach { elem in
            elem.removeFromParentNode()
        }
    }
}
