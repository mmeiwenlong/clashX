//
//  ProxyGroupSpeedTestMenuItem.swift
//  ClashX
//
//  Created by yicheng on 2019/10/15.
//  Copyright © 2019 west2online. All rights reserved.
//

import Carbon
import Cocoa

class ProxyGroupSpeedTestMenuItem: NSMenuItem {
    let proxyGroup: ClashProxy
    let testType: TestType

    init(group: ClashProxy) {
        proxyGroup = group
        switch group.type {
        case .urltest, .fallback:
            testType = .reTest
        case .select:
            testType = .benchmark
        default:
            testType = .unknown
        }

        super.init(title: NSLocalizedString("Benchmark", comment: ""), action: nil, keyEquivalent: "")

        switch testType {
        case .benchmark:
            view = ProxyGroupSpeedTestMenuItemView(testType.title)
        case .reTest:
            title = testType.title
        case .unknown:
            assertionFailure()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class ProxyGroupSpeedTestMenuItemView: MenuItemBaseView {
    private let label: NSTextField

    init(_ title: String) {
        label = NSTextField(labelWithString: title)
        label.font = type(of: self).labelFont
        label.sizeToFit()
        let rect = NSRect(x: 0, y: 0, width: label.bounds.width + 40, height: 20)
        super.init(frame: rect, handleClick: true, autolayout: false)
        addSubview(label)
        label.frame = NSRect(x: 20, y: 0, width: label.bounds.width, height: 20)
        label.textColor = NSColor.labelColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var labels: [NSTextField] {
        return [label]
    }

    override func didClickView() {
        startBenchmark()
    }

    private func startBenchmark() {
        guard let group = (enclosingMenuItem as? ProxyGroupSpeedTestMenuItem)?.proxyGroup
        else { return }
        let testGroup = DispatchGroup()
        label.stringValue = NSLocalizedString("Testing", comment: "")
        enclosingMenuItem?.isEnabled = false
        setNeedsDisplay(bounds)
        for proxyName in group.speedtestAble {
            testGroup.enter()
            ApiRequest.getProxyDelay(proxyName: proxyName) { delay in
                let delayStr = delay == 0 ? "fail" : "\(delay) ms"
                NotificationCenter.default.post(name: kSpeedTestFinishForProxy,
                                                object: nil,
                                                userInfo: ["proxyName": proxyName, "delay": delayStr])
                testGroup.leave()
            }
        }

        testGroup.notify(queue: .main) {
            [weak self] in
            guard let self = self, let menu = self.enclosingMenuItem else { return }
            self.label.stringValue = menu.title
            menu.isEnabled = true
            self.setNeedsDisplay()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        label.textColor = (enclosingMenuItem?.isEnabled ?? true) ? NSColor.labelColor : NSColor.placeholderTextColor
        updateBackground(label)
    }
}

extension ProxyGroupSpeedTestMenuItem {
    enum TestType {
        case benchmark
        case reTest
        case unknown

        var title: String {
            switch self {
            case .benchmark: return NSLocalizedString("Benchmark", comment: "")
            case .reTest: return NSLocalizedString("ReTest", comment: "")
            case .unknown: return ""
            }
        }
    }
}
