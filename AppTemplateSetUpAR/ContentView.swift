//
//  ContentView.swift
//  AppTemplateSetUpAR
//
//  Created by Zaid Neurothrone on 2022-10-16.
//

import ARKit
import FocusEntity
import RealityKit
import SwiftUI

struct RealityKitView: UIViewRepresentable {
  
  func makeUIView(context: Context) -> ARView {
    let view = ARView()
    
    let session = view.session
    let config = ARWorldTrackingConfiguration()
    config.planeDetection = [.horizontal]
    session.run(config)
    
    let coachingOverlay = ARCoachingOverlayView()
    coachingOverlay.goal = .horizontalPlane
    coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    coachingOverlay.session = session
    view.addSubview(coachingOverlay)
    
#if DEBUG
    view.debugOptions = [.showFeaturePoints, .showAnchorOrigins, .showAnchorGeometry]
#endif
    
    context.coordinator.view = view
    session.delegate = context.coordinator
    
    view.addGestureRecognizer(UITapGestureRecognizer(
      target: context.coordinator,
      action: #selector(Coordinator.handleTap))
    )
    
    return view
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator()
  }
  
  class Coordinator: NSObject, ARSessionDelegate {
    weak var view: ARView?
    var focusEntity: FocusEntity?
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
      guard let view = view else { return }
      
      focusEntity = FocusEntity(on: view, style: .classic(color: .orange))
    }
    
    @objc func handleTap() {
      guard let view = view,
            let focusEntity = focusEntity else { return }
      
      let anchor = AnchorEntity()
      view.scene.addAnchor(anchor)
      
      let cube = MeshResource.generateBox(size: 0.3, cornerRadius: 0.03)
      let material = SimpleMaterial(color: .orange, isMetallic: true)
      let cubeEntity = ModelEntity(mesh: cube, materials: [material])
      cubeEntity.position = focusEntity.position
      anchor.addChild(cubeEntity)
      
      let cubeBounds = cubeEntity.visualBounds(relativeTo: cubeEntity).extents.y
      let cubeShape = ShapeResource.generateBox(size: [cubeBounds, cubeBounds, cubeBounds])
      cubeEntity.collision = CollisionComponent(shapes: [cubeShape])
      cubeEntity.physicsBody = PhysicsBodyComponent(massProperties: .init(shape: cubeShape, mass: 30), material: nil, mode: .dynamic)
      
      let planeMesh = MeshResource.generatePlane(width: 2, depth: 2)
      let planeMaterial = SimpleMaterial(color: .init(.purple.opacity(0.5)), isMetallic: false)
      let planeEntity = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
      planeEntity.position = focusEntity.position
      planeEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: nil, mode: .static)
      planeEntity.collision = CollisionComponent(shapes: [.generateBox(width: 2, height: 0.002, depth: 2)])
      planeEntity.position = focusEntity.position // Reset position
      anchor.addChild(planeEntity)
      
      cubeEntity.addForce(.init(0, 1, 0), relativeTo: nil)
      cubeEntity.addTorque(
        .init(Float.random(in: 0...0.3),
              Float.random(in: 0...0.3),
              Float.random(in: 0...0.3)),
        relativeTo: nil
      )
    }
  }
  
  func updateUIView(_ uiView: ARView, context: Context) {}
}

struct ContentView: View {
  var body: some View {
    RealityKitView()
      .ignoresSafeArea()
    
//    NavigationStack {
//      VStack {
//        NavigationLink {
//          RealityKitView()
//            .ignoresSafeArea()
//        } label: {
//          Label("Augmented Reality", systemImage: "brain.head.profile")
//        }
//      }
//      .navigationTitle("App Template Set Up AR")
//    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
