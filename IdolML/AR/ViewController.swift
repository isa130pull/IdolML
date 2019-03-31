//
//  ViewController.swift
//  IdolML
//
//  Created by 川口功 on 2019/03/07.
//  Copyright © 2019 Isao Kawaguchi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    private var isMute = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = .showFeaturePoints
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapView))
        sceneView.addGestureRecognizer(gesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal // 今回追加
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func createVideoNode(size: CGFloat, position: SCNVector3) -> SCNNode {
        // AVPlayerを生成する
        let videoUrl = Bundle.main.url(forResource: "video", withExtension: "mp4")!
        let avPlayer = AVPlayer(url: videoUrl)
        avPlayer.actionAtItemEnd = .none
        avPlayer.isMuted = isMute
        if !isMute {
            isMute = true
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.didPlayToEnd),
                                               name: NSNotification.Name("AVPlayerItemDidPlayToEndTimeNotification"),
                                               object: avPlayer.currentItem)
        
        // SKSceneを生成する
        let skScene = SKScene(size: CGSize(width: 1000, height: 1000)) // あまりサイズが小さいと、ビデオの解像度が落ちる
        
        // AVPlayerからSKVideoNodeの生成する
        let skNode = SKVideoNode(avPlayer: avPlayer)
        // シーンと同じサイズとし、中央に配置する
        skNode.position = CGPoint(x: skScene.size.width / 2.0, y: skScene.size.height / 2.0)
        skNode.size = skScene.size
        skNode.yScale = -1.0 // 座標系を上下逆にする
        skNode.play() // 再生開始
        
        // SKSceneに、SKVideoNodeを追加する
        skScene.addChild(skNode)
        
        // SCNBoxノードを生成して、マテリアルにSKSeceを適用する
        let node = SCNNode()
        node.geometry = SCNBox(width: size, height: size, length: size, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = skScene
        node.geometry?.materials = [material]
        node.scale = SCNVector3(1.7, 1, 1) // サイズは横長
        node.position = position

        return node
    }
    
    @objc func didPlayToEnd(notification: NSNotification) {
        let item: AVPlayerItem = notification.object as! AVPlayerItem
        item.seek(to: .zero, completionHandler: nil)
    }
    
    @objc func tapView(sender: UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        
        let hitTestResult = sceneView.hitTest(location, types: .existingPlane)
        if let result = hitTestResult.first {
//            let geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
//            let material = SCNMaterial()
//            material.diffuse.contents = UIColor.darkGray
//            geometry.materials = [material]
//
//            let node = SCNNode(geometry: geometry)
            let pos = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y + 1, result.worldTransform.columns.3.z)
            let node = createVideoNode(size: 1.0, position: pos)
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
    

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
