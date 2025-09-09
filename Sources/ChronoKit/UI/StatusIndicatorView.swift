import UIKit

public class StatusIndicatorView: UIView {

    @objc public enum Status: Int {
        case active = 0
        case inactive = 1
        case pending = 2
    }

    public var status: Status = .pending {
        didSet {
            updateColor()
        }
    }

    private let dotLayer = CALayer()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        dotLayer.bounds = CGRect(x: 0, y: 0, width: 20, height: 20)
        dotLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        dotLayer.cornerRadius = 10
        layer.addSublayer(dotLayer)
        updateColor()
    }

    private func updateColor() {
        switch status {
        case .active:
            dotLayer.backgroundColor = UIColor.green.cgColor
            startPulsing()
        case .inactive:
            dotLayer.backgroundColor = UIColor.red.cgColor
            stopPulsing()
        case .pending:
            dotLayer.backgroundColor = UIColor.yellow.cgColor
            stopPulsing()
        }
    }

    private func startPulsing() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.2
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        dotLayer.add(pulseAnimation, forKey: "pulse")
    }

    private func stopPulsing() {
        dotLayer.removeAnimation(forKey: "pulse")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        dotLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }
}