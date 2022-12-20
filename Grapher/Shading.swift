//
//  Shading.swift
//  Grapher
//
//  Created by Сергей Николаев on 09.12.2022.
//

import UIKit

struct light_source_t {
    let vertex: [Double]
}

func linear_shading(triangle: inout triangle_t, light_sources: [light_source_t]) {

    if (light_sources.isEmpty) {
        triangle.processed_color = triangle.initial_color
        return
    }

    var sum_k = 0.0
    var count = 0

    var px = triangle.perpendicular[0]
    var py = triangle.perpendicular[1]
    var pz = triangle.perpendicular[2]
    var plength = sqrt(px * px + py * py + pz * pz)
    if (plength > 1e-8) {
        px /= plength
        py /= plength
        pz /= plength
    }

    var x: Double, y: Double, z: Double, length: Double, k: Double

    for ls_ind in 0..<light_sources.count {
        x = light_sources[ls_ind].vertex[0] - triangle.center[0]
        y = light_sources[ls_ind].vertex[1] - triangle.center[1]
        z = light_sources[ls_ind].vertex[2] - triangle.center[2]

        length = sqrt(x * x + y * y + z * z)

        if (length > 1e-8) {
            x /= length
            y /= length
            z /= length
        }

        k = px * x + py * y + pz * z

        if (k > 0) {
            sum_k += px * x + py * y + pz * z
        }
        count += 1
    }

    if (count > 0) {
        sum_k /= Double(count)
    }

    var r = Int(triangle.initial_color.ciColor.red * sum_k)
    var g = Int(triangle.initial_color.ciColor.green * sum_k)
    var b = Int(triangle.initial_color.ciColor.blue * sum_k)

    r = r < 0 ? 0 : r > 255 ? 255 : r
    g = g < 0 ? 0 : g > 255 ? 255 : g
    b = b < 0 ? 0 : b > 255 ? 255 : b

    triangle.processed_color = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
}
