//
//  VC+LifeCycle.swift
//  Grapher
//
//  Created by Сергей Николаев on 24.11.2022.
//

import UIKit

extension SceneViewController {
    func addLifeCycleObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didFinishLaunchingWithOptionsHandler),
                                               name: UIApplication.didFinishLaunchingNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillResignActiveHandler),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActiveHandler),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackgroundHandler),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForegroundHandler),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillTerminateHandler),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)


    }

    // запуск прила
    @objc
    private func didFinishLaunchingWithOptionsHandler() {
        print("----APP LOADED----")
    }

    //свернул прил (но ожидается что скоро открою - происходит
    //вечно, если смахнул вверх и смотрю панель с запущенными прил.)
    @objc
    private func applicationWillResignActiveHandler() {
        print("----APP INACTIVE----")
    }

    //прил начал обычную работу - после FOREGROUND
    @objc
    private func applicationDidBecomeActiveHandler() {
        print("----APP ACTIVE----")
    }

    //свернул прил и прошло небольшое время - приложение засыпает
    @objc
    private func applicationDidEnterBackgroundHandler() {
        viewDidLayoutSubviews()
        print("----APP ENTERS BACKGROUND----")
    }

    //заново открыл / запустил прил
    @objc
    private func applicationWillEnterForegroundHandler() {
        print("----APP ENTERS FOREGROUND----")
    }

    //выгрузил из памяти
    @objc
    private func applicationWillTerminateHandler() {
        print("----APP TERMINATED----")
    }
}
