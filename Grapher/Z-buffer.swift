//
//  Z-buffer.swift
//  Grapher
//
//  Created by Сергей Николаев on 09.12.2022.
//

import UIKit


struct triangle_t {
    var initial_vertexes: [[Double]]
    var processed_vertexes: [[Double]]
    var perpendicular: [Double]
    var center: [Double]
    var initial_color: UIColor
    var processed_color: UIColor
    var id: Int // unused
}

struct screen_t {
    var color: [[UIColor]]
    var change: [[Bool]]
    var width: Int
    var height: Int
    var default_color: UIColor
}

func ind_of_max_of_axis(_ triangle: triangle_t,_ axis: Int) -> Int {
    var ind = 0

    for i in 0..<3 {
        if (triangle.processed_vertexes[i][axis] > triangle.processed_vertexes[ind][axis]) {
            ind = i
        }
    }

    return ind
}

func ind_of_min_of_axis(_ triangle: triangle_t,_ axis: Int) -> Int {
    var ind = 0

    for i in 0..<3 {
        if (triangle.processed_vertexes[i][axis] < triangle.processed_vertexes[ind][axis]) {
            ind = i
        }
    }

    return ind
}

func ind_of_mid_of_axis(_ triangle: triangle_t,_ axis: Int) -> Int {
    var min = ind_of_min_of_axis(triangle, axis)
    var max = ind_of_max_of_axis(triangle, axis)
    var result = -1

    for i in 0..<3 {
        if (i != min && i != max) {
            result = i
        }
    }

    return result
}

//сколько раз повторятеся определенная координата внутри треугольника
func count_value_with_axis(_ triangle: triangle_t,_ axis: Int, _ value: Int) -> Int {
    var count = 0

    for i in 0..<3 {
        if (fabs(triangle.processed_vertexes[i][axis] - Double(value)) < 1e-6) {
            count += 1
        }
    }

    return count
}

func index_with_axis(_ triangle: triangle_t,_ axis: Int, _ value: Int) -> Int {
    for i in 0..<3 {
        if (fabs(triangle.processed_vertexes[i][axis] - Double(value)) < 1e-6) {
            return i
        }
    }
    return 0
}

func color_pixel(_ matrix: inout screen_t, _ color: UIColor, _ x: Int, _ y: Int) {
    if (x < 0 || x >= matrix.width || y < 0 || y >= matrix.height) {
        print("[DBG] [[ERROR]] OUT OF ARRAY")
    } else {
        matrix.color[x][y] = color
        matrix.color[x][y] = color
        matrix.color[x][y] = color

        matrix.change[x][y] = true
    }
}

//Функция работает не с изначальным светом, а с измененным
func process_level(_ triangle: triangle_t, _ screen: inout screen_t, _ y: Int, _ depth_arr: inout [Double]) {

    var max_x_ind = ind_of_max_of_axis(triangle, 0)
    var min_x_ind = ind_of_min_of_axis(triangle, 0)

    var max_y_ind = ind_of_max_of_axis(triangle, 1)
    var min_y_ind = ind_of_min_of_axis(triangle, 1)
    var mid_y_ind = ind_of_mid_of_axis(triangle, 1)

    var ymax = triangle.processed_vertexes[max_y_ind][1]
    var ymin = triangle.processed_vertexes[min_y_ind][1]
    var ymid = triangle.processed_vertexes[mid_y_ind][1]
    var xmax = triangle.processed_vertexes[max_y_ind][0]
    var xmin = triangle.processed_vertexes[min_y_ind][0]
    var xmid = triangle.processed_vertexes[mid_y_ind][0]
    var zmax = triangle.processed_vertexes[max_y_ind][2]
    var zmin = triangle.processed_vertexes[min_y_ind][2]
    var zmid = triangle.processed_vertexes[mid_y_ind][2]

//  Если треугольник целиком выше или ниже уровня
    if (y < Int(triangle.processed_vertexes[min_y_ind][1]) || y > Int(triangle.processed_vertexes[max_y_ind][1])) {
        return
    }

//   Если треугольник выраждается в точку или линию - пропускаем этот треугольник
    if (max_x_ind == min_x_ind || max_y_ind == min_y_ind) {
        return
    }

    if ((y == Int(triangle.processed_vertexes[max_y_ind][1]) || y == Int(triangle.processed_vertexes[min_y_ind][1])) && count_value_with_axis(triangle, 1, y) == 1) {
        var y_ind = index_with_axis(triangle, 1, y)
        var x = ceil(triangle.processed_vertexes[y_ind][0])
        var z = ceil(triangle.processed_vertexes[y_ind][2])

        if (x >= 0 && Int(x) < screen.width) {
            if (depth_arr[Int(x)] > z) {
                depth_arr[Int(x)] = z
                color_pixel(&screen, triangle.processed_color, Int(x), y)
            }
        }
        return
    }

    var start_x: Double
    var finish_x: Double
    var start_z: Double
    var finish_z: Double

//    if (y > ymid && fabs(ymin - ymid) > 1e-6 && fabs(ymin - ymax) > 1e-6) {
    if (Double(y) > ymid) {

//      Этот блок одинаков для каждой ветки
        var d_ya = ymax - ymin
        var d_xa = xmax - xmin
        var d_za = zmax - zmin
        start_x = xmin + d_xa * (Double(y) - ymin) / d_ya
        start_z = zmin + d_za * (Double(y) - ymin) / d_ya

        var d_yb = ymax - ymid
        var d_xb = xmax - xmid
        var d_zb = zmax - zmid
        finish_x = xmid + d_xb * (Double(y) - ymid) / d_yb
        finish_z = zmid + d_zb * (Double(y) - ymid) / d_yb

//    } else if (fabs(ymax - ymid) > 1e-6 && fabs(ymin - ymax) > 1e-6) {
    } else if (Double(y) < ymid) {


//      Этот блок одинаков для каждой ветки
        var d_ya = ymax - ymin
        var d_xa = xmax - xmin
        var d_za = zmax - zmin
        start_x = xmin + d_xa * (Double(y) - ymin) / d_ya
        start_z = zmin + d_za * (Double(y) - ymin) / d_ya

        var d_yb = ymid - ymin
        var d_xb = xmid - xmin
        var d_zb = zmid - zmin
        finish_x = xmin + d_xb * (Double(y) - ymin) / d_yb
        finish_z = zmin + d_zb * (Double(y) - ymin) / d_yb

    } else {

//      Этот блок одинаков для каждой ветки
        var d_ya = ymax - ymin
        var d_xa = xmax - xmin
        var d_za = zmax - zmin
        start_x = xmin + d_xa * (Double(y) - ymin) / d_ya
        start_z = zmin + d_za * (Double(y) - ymin) / d_ya

        finish_x = xmid
        finish_z = zmid
    }

    if (start_x > finish_x) {
        var tmp = start_x
        start_x = finish_x
        finish_x = tmp
        tmp = start_z
        start_z = finish_z
        finish_z = tmp
    }

    if (fabs(finish_x - start_x) < 1e-2) {
        return
    }

    var dz = (finish_z - start_z) / (finish_x - start_x)

    for x in Int(ceil(start_x - 1))..<Int(ceil(finish_x + 1)) {
        if (x >= 0 && x < screen.width) {
            var z = start_z + dz * (Double(x) - start_x)

            if (depth_arr[x] > z) {
                depth_arr[x] = z
                color_pixel(&screen, triangle.processed_color, x, y)
            }
        }
    }
}

func complete_process_level(_ screen: inout screen_t, _ triangles: [triangle_t], _ y: Int) {

    if (y < screen.height && y >= 0) {
        var depth_array = [Double](repeating: 0, count: screen.width)

        for i in 0..<screen.width {
            depth_array[i] = 1e33
        }

        for i in 0..<triangles.count {
            process_level(triangles[i], &screen, y, &depth_array)
        }

        for x in 0..<screen.width {
            if (!screen.change[x][y] && Int32(depth_array[x]) == INT_MAX) {
                color_pixel(&screen, screen.default_color, x, y)
            }
        }
    }
}

func z_buffer_render(screen: inout screen_t, triangles: [triangle_t])
{
    for y in screen.height - 1...0 {
        complete_process_level(&screen, triangles, y)
    }

}

func threaded_z_buffer_render(screen: inout screen_t, triangles: [triangle_t], completion: @escaping () -> ())
{
    let group = DispatchGroup()

    var n = 7

    var y: Int
    for i in 0..<Int(screen.height / n + 1) {

        for k in 0..<n {
            y = n * i + k
            if ( y < screen.height ) {
                group.enter()
                let _func = {complete_process_level(&screen, triangles, y)}
                Thread.detachNewThread {
//                    complete_process_level(&screen, triangles, y)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion()
        }
    }
}
