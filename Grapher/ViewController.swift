//
//  ViewController.swift
//  Grapher
//
//  Created by Сергей Николаев on 17.11.2022.
//

import UIKit
import SceneKit
import MathParser
import PinLayout

struct CoordinatesRange {
    var from: Double
    var to: Double
}

struct NNodes {
    var x: Int
    var y: Int
}


class SceneViewController: UIViewController {
    let expressionTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(
            string: "f(x, y) = ",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.4)]
        )
        return textField
    }()
    
    private let xAxisFromTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(
            string: "x (от) ",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.4)]
        )
        return textField
    }()
    
    private let xAxisToTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(
            string: "x (до) ",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.4)]
        )
        return textField
    }()
    
    private let xAxisStepTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(
            string: "x (узлы) ",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.4)]
        )
        return textField
    }()
    
    private let yAxisFromTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(
            string: "y (от) ",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.4)]
        )
        return textField
    }()
    
    private let yAxisToTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(
            string: "y (до) ",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.4)]
        )
        return textField
    }()
    
    private let yAxisStepTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(
            string: "y (узлы) ",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.4)]
        )
        return textField
    }()

    private lazy var generateSurfaceButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 12
        button.tintColor = .white
        button.setImage(UIImage(systemName: "move.3d"), for: .normal)
        button.addTarget(self, action: #selector(newSurfaceNeedsToBuild), for: .touchUpInside)
        return button

    }()

    private lazy var historyButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .systemGray2
        button.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        button.addTarget(self, action: #selector(showHistory), for: .touchUpInside)
        return button
    }()

    private lazy var stopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(stopComputing), for: .touchUpInside)
        return button
    }()

    private lazy var bgColorButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGray4
        button.layer.cornerRadius = 15
        button.setTitle(" фон", for: .normal)
        button.tintColor = bgColor
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setImage(UIImage(systemName: "paintpalette.fill"), for: .normal)
        if #available(iOS 14.0, *) {
            button.menu = createColorPickerMenu(for: .bg)
            button.showsMenuAsPrimaryAction = true
        }
        button.alpha = 0
        button.isHidden = true
        return button
    }()

    private lazy var surfaceColorButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGray4
        button.layer.cornerRadius = 15
        button.setTitle(" поверхность", for: .normal)
        button.tintColor = surfaceColor
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setImage(UIImage(systemName: "paintpalette.fill"), for: .normal)
        if #available(iOS 14.0, *) {
            button.menu = createColorPickerMenu(for: .surface)
            button.showsMenuAsPrimaryAction = true
        }
        button.alpha = 0
        button.isHidden = true
        return button
    }()

    private lazy var lightsButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGray4
        button.layer.cornerRadius = 15
        button.tintColor = .yellow
        button.setImage(UIImage(systemName: "flashlight.on.fill"), for: .normal)
        button.addTarget(self, action: #selector(showLights), for: .touchUpInside)
        button.alpha = 0
        button.isHidden = true
        return button
    }()

    private var tableViewContainer = UIView()
    private var tableViewBG = UIView()

    private let fromLabel = UILabel()
    private let toLabel = UILabel()
    private let stepLabel = UILabel()
    private let oXLabel = UILabel()
    private let oYLabel = UILabel()
    private var newLightCell: NewLightTableViewCell?

    var expressions = [String]()

    private var bgColor: UIColor = UserDefaults.standard.bgColor ?? UIColor.black {
        didSet {
            changeBGcolor()
        }
    }

    private var surfaceColor: UIColor = UserDefaults.standard.surfaceColor ?? UIColor.green {
        didSet {
            changeSurfaceColor()
        }
    }

    struct Light {
        var isActive: Bool
        var node: SCNNode
    }

    enum colorPickerType {
        case bg
        case surface
    }
    
    let activityIndicator = UIActivityIndicatorView()
    let progressView = UIProgressView()
    let progressLabel = UILabel()
    
    private let nNodes = 100
    private lazy var scnView = SCNView()
    private let intarfaceView = UIView()

    private var add = 0
    private var activeSurface: Surface?
    private var activeNet: CoordinatesNet?
    private let lightsTableView = UITableView()
    private var lights = [Light]() {
        didSet {
            for light in oldValue {
                if light.isActive {
                    light.node.removeFromParentNode()
                }
            }
            for light in lights {
                if light.isActive {
                    scene.rootNode.addChildNode(light.node)
                }
            }
        }
    }

    var scene = SCNScene()
    var tapGesture: UITapGestureRecognizer!
    
    override func loadView() {
        super.loadView()
        print("1) "+#function)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("2) "+#function)
        
        setupScene()
        
        setupUI()

        expressions = UserDefaults.standard.object(forKey: "surfaces") as? [String] ?? []
        expressionTextField.text = expressions.count != 0 ? expressions.last : "abs(sin(x)y + sin(y)x)"
        xAxisFromTextField.text = "-10"
        xAxisToTextField.text = "10"
        xAxisStepTextField.text = "100"
        yAxisFromTextField.text = "-10"
        yAxisToTextField.text = "10"
        yAxisStepTextField.text = "100"
        
        newSurfaceNeedsToBuild()
        
        addLifeCycleObservers()
    }
    
    private func setupScene() {
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.eulerAngles.z = -Float.pi / 4
        cameraNode.eulerAngles.x = Float.pi / 3
        scene.rootNode.addChildNode(cameraNode)

        // place the camera
        cameraNode.position = SCNVector3(x: -15, y: -15, z: 15)

        addLight(to: scene, x: 5, y: 5, z: -100)
        addLight(to: scene, x: -5, y: -5, z: 100)
        addLight(to: scene, x: -15, y: -15, z: -100)
        addLight(to: scene, x: -10, y: 0, z: 10)
        lights[lights.count-1].isActive = false
    }
    
    private func setupUI() {
//        scnView = view as! SCNView
        view.addSubview(scnView)
        view.addSubview(tableViewContainer)
        
        [expressionTextField, xAxisFromTextField, xAxisToTextField, xAxisStepTextField, yAxisFromTextField, yAxisToTextField, yAxisStepTextField].forEach {
            $0.font = UIFont.boldSystemFont(ofSize: 16)
            $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 50))
            $0.layer.cornerRadius = 15
            $0.autocorrectionType = .no
            $0.leftViewMode = .always
            $0.keyboardType = $0 == expressionTextField ? .default : .numbersAndPunctuation
            $0.returnKeyType = .done
            $0.clearButtonMode = .whileEditing
            $0.backgroundColor = .systemGray6
            $0.textColor = .label
            $0.tintColor = .label
            $0.returnKeyType = .done
            $0.delegate = self
            $0.isHidden = $0 == expressionTextField ? false : true
            $0.alpha = $0 == expressionTextField ? 1 : 0
        }

        [fromLabel, toLabel, stepLabel, oXLabel, oYLabel].forEach {
            $0.font = UIFont.boldSystemFont(ofSize: 16)
            $0.layer.cornerRadius = 7
            $0.backgroundColor = .systemGray3
            $0.textColor = .label
            $0.tintColor = .label
            $0.layer.masksToBounds = true
            $0.isHidden = $0 == expressionTextField ? false : true
            $0.alpha = $0 == expressionTextField ? 1 : 0
        }

        fromLabel.text = " От: "
        toLabel.text = " До: "
        stepLabel.text = " Узлы: "
        oXLabel.text = " Ox: "
        oYLabel.text = " Oy: "

        oXLabel.backgroundColor = .red
        oYLabel.backgroundColor = .blue

        lightsTableView.delegate = self
        lightsTableView.dataSource = self
        lightsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        lightsTableView.register(AddTableViewCell.self, forCellReuseIdentifier: "add")
        lightsTableView.register(NewLightTableViewCell.self, forCellReuseIdentifier: "new")
        lightsTableView.allowsMultipleSelectionDuringEditing = false
        
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        let tapToCloseTVGesture = UITapGestureRecognizer(target: self, action: #selector(dismissTV))
        
        activityIndicator.backgroundColor = .systemGray6
        activityIndicator.layer.cornerRadius = 10

        generateSurfaceButton.becomeFirstResponder()
        generateSurfaceButton.alpha = 0
        generateSurfaceButton.isHidden = true
        
        progressLabel.textAlignment = .center

        [expressionTextField, activityIndicator, xAxisFromTextField, xAxisToTextField, xAxisStepTextField, yAxisFromTextField, yAxisToTextField, yAxisStepTextField, generateSurfaceButton, historyButton, fromLabel, toLabel, stepLabel, oXLabel, oYLabel, bgColorButton, surfaceColorButton, lightsButton].forEach { scnView.addSubview($0) }

        activityIndicator.addSubview(progressView)
        activityIndicator.addSubview(progressLabel)
        activityIndicator.addSubview(stopButton)

        tableViewBG.backgroundColor = .systemBackground
        tableViewBG.alpha = 0
        tableViewContainer.addSubview(tableViewBG)
        tableViewContainer.addSubview(lightsTableView)
        tableViewBG.addGestureRecognizer(tapToCloseTVGesture)
        tableViewContainer.isHidden = true
        lightsTableView.alpha = 0
        lightsTableView.becomeFirstResponder()
//        lightsTableView.backgroundColor = .systemGray3

        lightsTableView.layer.cornerRadius = 15
        
        activityIndicator.alpha = 0
        progressView.alpha = 0
        
        scnView.addGestureRecognizer(tapGesture)
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.backgroundColor = bgColor
    }

    private func changeBGcolor() {
        scnView.backgroundColor = bgColor
        bgColorButton.tintColor = bgColor
        UserDefaults.standard.bgColor = bgColor
    }

    private func changeSurfaceColor() {
        newSurfaceNeedsToBuild()
        surfaceColorButton.tintColor = surfaceColor
        UserDefaults.standard.surfaceColor = surfaceColor
    }

    public func createColorPickerMenu(for type: colorPickerType) -> UIMenu {
        var menuActions = [UIAction]()
        let colorsRU = ["белый", "черный", "синий", "красный", "зеленый", "голубой", "желтый", "серый", "оранжевый"]
        for (i, color) in [UIColor.white, UIColor.black, UIColor.blue, UIColor.red, UIColor.green, UIColor.cyan, UIColor.yellow, UIColor.systemGray2, UIColor.orange].enumerated() {
            let action = UIAction(
                title: colorsRU[i],
                image: UIImage(systemName: "circle.inset.filled")?.withTintColor(color, renderingMode: .alwaysOriginal)
              ) { [unowned self] (_) in
                  switch type {
                  case .bg:
                      bgColor = color
                  case .surface:
                      surfaceColor = color
                  }
              }

            menuActions.append(action)
        }

        let addNewMenu = UIMenu(
            title: "",
            children: menuActions)

          return addNewMenu
    }


    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("3) "+#function)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("4) "+#function)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("5) "+#function)

        UIView.animate(withDuration: 0.5) {
            [self.xAxisFromTextField, self.xAxisToTextField, self.xAxisStepTextField, self.yAxisFromTextField, self.yAxisToTextField, self.yAxisStepTextField, self.generateSurfaceButton, self.fromLabel, self.toLabel, self.stepLabel, self.oXLabel, self.oYLabel, self.bgColorButton, self.surfaceColorButton, self.lightsButton].forEach {
                $0.alpha = 0
            }
            self.startViewsLayout()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            [self.xAxisFromTextField, self.xAxisToTextField, self.xAxisStepTextField, self.yAxisFromTextField, self.yAxisToTextField, self.yAxisStepTextField, self.generateSurfaceButton, self.fromLabel, self.toLabel, self.stepLabel, self.oXLabel, self.oYLabel, self.bgColorButton, self.surfaceColorButton, self.lightsButton].forEach {
                $0.isHidden = true
            }
        }
    }

    private func startViewsLayout() {
        scnView.frame = view.frame

        expressionTextField.pin
            .top(view.pin.safeArea.top)
            .left(view.pin.safeArea.left + 20)
            .right(view.pin.safeArea.right + 20)
            .height(50)

        generateSurfaceButton.pin
            .centerRight(to: expressionTextField.anchor.centerRight)
            .marginRight(4)
            .width(70)
            .height(42)

        historyButton.pin
            .centerRight(to: expressionTextField.anchor.centerRight)
            .marginRight(4)
            .width(42)
            .height(42)

        activityIndicator.pin
            .center()
            .width(200)
            .height(100)

        stopButton.pin
            .top(5)
            .right(5)
            .width(20)
            .height(20)

        progressView.pin
            .center()
            .marginTop(30)
            .width(170)
            .height(10)

        progressLabel.pin
            .center()
            .marginTop(-30)
            .height(25)
            .width(100)

        tableViewContainer.pin.all()

        tableViewBG.pin.all()

        lightsTableView.pin
            .hCenter()
            .top(view.pin.safeArea.top + 55)
            .width(250)
            .height(300)

        activityIndicator.startAnimating()

        xAxisFromTextField.pin
            .top(view.pin.safeArea.top)
            .left(view.pin.safeArea.left + 20)
            .width(expressionTextField.bounds.width / 3 - 15)
            .height(50)

        xAxisToTextField.pin
            .top(view.pin.safeArea.top)
            .topCenter(to: expressionTextField.anchor.topCenter)
            .width(expressionTextField.bounds.width / 3 - 15)
            .height(50)

        xAxisStepTextField.pin
            .top(view.pin.safeArea.top)
            .right(view.pin.safeArea.right + 20)
            .width(expressionTextField.bounds.width / 3 - 15)
            .height(50)

        yAxisFromTextField.pin
            .top(view.pin.safeArea.top)
            .left(view.pin.safeArea.left + 20)
            .width(of: xAxisFromTextField)
            .height(of: xAxisFromTextField)

        yAxisToTextField.pin
            .top(view.pin.safeArea.top)
            .topCenter(to: expressionTextField.anchor.topCenter)
            .width(of: xAxisToTextField)
            .height(of: xAxisToTextField)

        yAxisStepTextField.pin
            .top(view.pin.safeArea.top)
            .right(view.pin.safeArea.right + 20)
            .width(of: xAxisStepTextField)
            .height(of: xAxisStepTextField)

        lightsButton.pin
            .top(view.pin.safeArea.top)
            .right(view.pin.safeArea.right + 20)
            .width(50)
            .height(50)

        bgColorButton.pin
            .top(view.pin.safeArea.top)
            .left(view.pin.safeArea.left + 20)
            .width(90)
            .height(50)

        surfaceColorButton.pin
            .top(view.pin.safeArea.top)
            .left(view.pin.safeArea.left + 20)
            .width(160)
            .height(50)

        fromLabel.pin
            .top(view.pin.safeArea.top)
            .left(view.pin.safeArea.left + 20)
            .maxWidth(expressionTextField.frame.width*0.3)
            .maxHeight(20)
            .sizeToFit(.height)

        toLabel.pin
            .top(view.pin.safeArea.top)
            .topCenter(to: expressionTextField.anchor.topCenter)
            .maxWidth(expressionTextField.frame.width*0.3)
            .maxHeight(20)
            .sizeToFit(.height)

        stepLabel.pin
            .top(view.pin.safeArea.top)
            .right(view.pin.safeArea.right + 20)
            .maxWidth(expressionTextField.frame.width*0.3)
            .maxHeight(20)
            .sizeToFit(.height)

        oXLabel.pin
            .top(view.pin.safeArea.top)
            .left(view.pin.safeArea.left + 20)
            .maxWidth(expressionTextField.frame.width*0.3)
            .maxHeight(20)
            .sizeToFit(.height)

        oYLabel.pin
            .top(view.pin.safeArea.top)
            .left(view.pin.safeArea.left + 20)
            .maxWidth(expressionTextField.frame.width*0.3)
            .maxHeight(20)
            .sizeToFit(.height)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("6) "+#function)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("7) "+#function)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("8) "+#function)
    }
    
    deinit {
        print("9) "+"deinit")
    }
    
    private func addLight(to scene: SCNScene, x: Float, y: Float, z: Float) {
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: x, y: y, z: z)
//        lightNode.light?.color = .white
        lights.append(Light(isActive: true, node: lightNode))
//        scene.rootNode.addChildNode(lightNode)
    }

    func showLimitFields() {
        [xAxisFromTextField, xAxisToTextField, xAxisStepTextField, yAxisFromTextField, yAxisToTextField, yAxisStepTextField, generateSurfaceButton, fromLabel, toLabel, stepLabel, oXLabel, oYLabel, bgColorButton, surfaceColorButton, lightsButton].forEach {
            $0.isHidden = false
        }
        
        UIView.animate(withDuration: 0.5) { [expressionTextField, xAxisFromTextField, xAxisToTextField, xAxisStepTextField, yAxisFromTextField, yAxisToTextField, yAxisStepTextField, generateSurfaceButton, historyButton, fromLabel, toLabel, stepLabel, oXLabel, oYLabel, bgColorButton, surfaceColorButton, lightsButton] in
            
            [xAxisFromTextField, xAxisToTextField, xAxisStepTextField, yAxisFromTextField, yAxisToTextField, yAxisStepTextField, generateSurfaceButton, fromLabel, toLabel, stepLabel, oXLabel, oYLabel, bgColorButton, surfaceColorButton, lightsButton].forEach {
                $0.alpha = 1
            }

            historyButton.pin
                .centerRight(to: generateSurfaceButton.anchor.centerLeft)
                .marginRight(4)
                .width(42)
                .height(42)

            oXLabel.pin
                .topLeft(to: expressionTextField.anchor.bottomLeft)
                .marginTop(65)
                .marginLeft(-10)
                .maxWidth(expressionTextField.frame.width*0.3)
                .maxHeight(20)
                .sizeToFit(.height)

            oYLabel.pin
                .topLeft(to: oXLabel.anchor.bottomLeft)
                .marginTop(35)
                .maxWidth(expressionTextField.frame.width*0.3)
                .maxHeight(20)
                .sizeToFit(.height)

            
            xAxisFromTextField.pin
                .topLeft(to: expressionTextField.anchor.bottomLeft)
                .marginTop(50)
                .marginLeft(oXLabel.frame.width)
                .width(expressionTextField.bounds.width / 3 - 15)
                .height(50)
            
            xAxisToTextField.pin
                .topCenter(to: expressionTextField.anchor.bottomCenter)
                .marginTop(50)
                .marginLeft((oXLabel.frame.width)/2)
                .width(expressionTextField.bounds.width / 3 - 15)
                .height(50)
            
            xAxisStepTextField.pin
                .topRight(to: expressionTextField.anchor.bottomRight)
                .marginTop(50)
                .width(expressionTextField.bounds.width / 3 - 15)
                .height(50)
            
            yAxisFromTextField.pin
                .topLeft(to: xAxisFromTextField.anchor.bottomLeft)
                .marginTop(5)
                .width(of: xAxisFromTextField)
                .height(of: xAxisFromTextField)
            
            yAxisToTextField.pin
                .topCenter(to: xAxisToTextField.anchor.bottomCenter)
                .marginTop(5)
                .width(of: xAxisToTextField)
                .height(of: xAxisToTextField)
            
            yAxisStepTextField.pin
                .topRight(to: xAxisStepTextField.anchor.bottomRight)
                .marginTop(5)
                .width(of: xAxisStepTextField)
                .height(of: xAxisStepTextField)

            lightsButton.pin
                .topRight(to: yAxisStepTextField.anchor.bottomRight)
                .marginTop(10)
                .width(50)
                .height(50)

            surfaceColorButton.pin
                .topLeft(to: yAxisFromTextField.anchor.bottomLeft)
                .marginTop(10)
                .width(160)
                .height(of: xAxisStepTextField)

            bgColorButton.pin
                .topLeft(to: surfaceColorButton.anchor.bottomLeft)
                .marginTop(10)
                .width(90)
                .height(of: xAxisStepTextField)

            fromLabel.pin
                .bottomLeft(to: xAxisFromTextField.anchor.topLeft)
                .marginBottom(10)
                .maxWidth(expressionTextField.frame.width*0.3)
                .maxHeight(20)
                .sizeToFit(.height)

            toLabel.pin
                .bottomLeft(to: xAxisToTextField.anchor.topLeft)
                .marginBottom(10)
                .maxWidth(expressionTextField.frame.width*0.3)
                .maxHeight(20)
                .sizeToFit(.height)

            stepLabel.pin
                .bottomLeft(to: xAxisStepTextField.anchor.topLeft)
                .marginBottom(10)
                .maxWidth(expressionTextField.frame.width*0.3)
                .maxHeight(20)
                .sizeToFit(.height)
        }
    }
}

extension SceneViewController {
    @objc
    func newSurfaceNeedsToBuild() {
        if add == 1 {
            view.endEditing(true)
            guard var xStr = newLightCell?.xTextField.text,
                  var yStr = newLightCell?.yTextField.text,
                  var zStr = newLightCell?.zTextField.text
            else {
                AlertManager.shared.showAlert(presentTo: self, title: "Ошибка", message: "координаты введены некоректно!")
                return
            }

            xStr = xStr.replacingOccurrences(of: ",", with: ".")
            yStr = yStr.replacingOccurrences(of: ",", with: ".")
            zStr = zStr.replacingOccurrences(of: ",", with: ".")


            guard let x = Double(xStr),
                  let y = Double(yStr),
                  let z = Int(zStr)
            else {
                AlertManager.shared.showAlert(presentTo: self, title: "Ошибка", message: "координаты введены некоректно!")
                return
            }
            newLightCell?.xTextField.text = ""
            newLightCell?.yTextField.text = ""
            newLightCell?.zTextField.text = ""
            addLight(to: scene, x: Float(x), y: Float(y), z: Float(z))
            add = 0
            newLightCell?.disappear()
            lightsTableView.reloadData()
            return
        }
        dismissKeyboard(UITapGestureRecognizer())
        activeSurface?.removeSurface()
        var newExprComponents = expressionTextField.text!.components(separatedBy: "x")
        var newExpr = ""

        for comp in newExprComponents {
            newExpr += comp + (comp != newExprComponents.last! ? "$x" : "")
        }

        newExprComponents = newExpr.components(separatedBy: "y")
        newExpr = ""

        for comp in newExprComponents {
            newExpr += comp + (comp != newExprComponents.last! ? "$y" : "")
        }

        newExpr = newExpr.replacingOccurrences(of: "^", with: "**")

        var nThreads = 6

        if newExpr.contains(";") {
            newExprComponents = newExpr.components(separatedBy: ";")

            newExpr = newExprComponents[0]

            nThreads = Int(newExprComponents[1]) ?? 6
        }

        print(newExpr)


        guard var xFromStr = xAxisFromTextField.text,
              var xToStr = xAxisToTextField.text,
              var xStepStr = xAxisStepTextField.text,
              var yFromStr = yAxisFromTextField.text,
              var yToStr = yAxisToTextField.text,
              var yStepStr = yAxisStepTextField.text
        else {
            AlertManager.shared.showAlert(presentTo: self, title: "Ошибка", message: "Поля пределов или количества узлов заполнены некорректно!")
            return
        }

        xFromStr = xFromStr.replacingOccurrences(of: ",", with: ".")
        xToStr = xToStr.replacingOccurrences(of: ",", with: ".")
        xStepStr = xStepStr.replacingOccurrences(of: ",", with: ".")
        yFromStr = yFromStr.replacingOccurrences(of: ",", with: ".")
        yToStr = yToStr.replacingOccurrences(of: ",", with: ".")
        yStepStr = yStepStr.replacingOccurrences(of: ",", with: ".")


        guard let xFrom = Double(xFromStr),
              let xTo = Double(xToStr),
              let xStep = Int(xStepStr),
              let yFrom = Double(yFromStr),
              let yTo = Double(yToStr),
              let yStep = Int(yStepStr),
              xTo > xFrom,
              yTo > yFrom,
              xStep > 0,
              yStep > 0
        else {
            AlertManager.shared.showAlert(presentTo: self, title: "Ошибка", message: "Поля пределов или количества узлов заполнены некорректно!")
            return
        }


        viewDidLayoutSubviews()

        activeNet?.clean()
        activeNet = CoordinatesNet(xFrom: xFrom, xTo: xTo, yFrom: yFrom, yTo: yTo, scene: scene)
        activeNet?.draw()

        activeSurface = Surface(rangeX: CoordinatesRange(from: xFrom, to: xTo), rangeY: CoordinatesRange(from: yFrom, to: yTo), nodesInAxises: NNodes(x: xStep, y: yStep), expression: newExpr, vc: self, nThreads: 6, color: surfaceColor)

        activeSurface?.showSurface()

        do {
            _ = try newExpr.evaluate(["x": xFrom, "y": yFrom])

            if expressionTextField.layer.borderWidth > 0 { return }
            expressions = UserDefaults.standard.object(forKey: "surfaces") as? [String] ?? []
            if expressions.contains(expressionTextField.text!) {
                expressions.remove(at: expressions.firstIndex(of: expressionTextField.text!)!)
            }
            expressions.append(expressionTextField.text!)
            UserDefaults.standard.set(expressions, forKey: "surfaces")
        } catch {}

    }

    @objc
    private func stopComputing() {
        activeSurface?.stopFlag = true
    }

    @objc
    private func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        [expressionTextField, xAxisFromTextField, xAxisToTextField, xAxisStepTextField, yAxisFromTextField, yAxisToTextField, yAxisStepTextField].forEach {
            $0.resignFirstResponder()
        }

        viewDidLayoutSubviews()
    }

    @objc
    private func dismissTV() {
        view.endEditing(true)
        hideLights()
    }

    @objc
    private func showLights() {
        view.endEditing(true)
        tableViewContainer.isHidden = false

        UIView.animate(withDuration: 0.3, delay: 0.0) {
            self.tableViewBG.alpha = 0.5
            self.lightsTableView.alpha = 1
        }
    }

    @objc
    private func hideLights() {
        UIView.animate(withDuration: 0.3, delay: 0.0) {
            self.tableViewBG.alpha = 0
            self.lightsTableView.alpha = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.tableViewContainer.isHidden = true
        }
    }

    @objc
    private func showHistory() {
        let historyVC = HistoryVC(root: self)
        historyVC.title = "История"
        let navigationController = UINavigationController(rootViewController: historyVC)
        present(navigationController, animated: true, completion: nil)
    }
}

extension SceneViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lights.count + 1// + add
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if add == 1 && indexPath.row == lights.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "new", for: indexPath) as! NewLightTableViewCell
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                cell.appear(vc: self)
            }
            newLightCell = cell
            return cell
        }

        if indexPath.row < lights.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let light = lights[indexPath.row]

            var content = cell.defaultContentConfiguration()
            content.text = "(\(light.node.position.x); \(light.node.position.y); \(light.node.position.z))"
            if light.isActive {
                content.image = UIImage(systemName: "flashlight.on.fill")?.withTintColor(UIColor.yellow, renderingMode: .alwaysOriginal)
            } else {
                content.image = UIImage(systemName: "flashlight.on.fill")
            }
            cell.contentConfiguration = content
            cell.backgroundColor = .systemBackground
//            cell.backgroundColor = .systemGray3
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "add", for: indexPath) as! AddTableViewCell
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(#function)
        
        if indexPath.row == lights.count {
            add = 1
            tableView.reloadData()
            return
        }
        lights[indexPath.row].isActive = !lights[indexPath.row].isActive
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if indexPath.row == lights.count {
                add = 0

                newLightCell?.disappear()
                tableView.reloadData()
                return
            }

            // remove the item from the data model
            print("del")

            // delete the table view row
            lights.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)

        } else if editingStyle == .insert {
            // Not used in our example, but if you were adding a new row, this is where you would do it.
        }
    }
}

