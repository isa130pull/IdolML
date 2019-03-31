import UIKit
import AVKit
import Vision

class MLViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var oneItem: UILabel!
    @IBOutlet weak var twoItem: UILabel!
    @IBOutlet weak var threeItem: UILabel!
    @IBOutlet weak var oneRate: UILabel!
    @IBOutlet weak var twoRate: UILabel!
    @IBOutlet weak var threeRate: UILabel!
    @IBOutlet weak var bottomView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(bottomView)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: prgt().model) else { return }
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            DispatchQueue.main.async {
                // メインスレッドで実行 UIの処理など
                self.oneItem.text = results[0].identifier
                self.twoItem.text = results[1].identifier
                self.threeItem.text = results[2].identifier
                let oneRate = round(results[0].confidence * 100)
                let twoRate = round(results[1].confidence * 100)
                let threeRate = round(results[2].confidence * 100)
                self.oneRate.text = String(oneRate) + "%"
                self.twoRate.text = String(twoRate) + "%"
                self.threeRate.text = String(threeRate) + "%"
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
