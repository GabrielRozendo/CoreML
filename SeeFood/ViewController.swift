//
//  ViewController.swift
//  SeeFood
//
//  Created by Gabriel Rozendo on 3/23/20.
//  Copyright © 2020 Gabriel Rozendo. All rights reserved.
//

import AVFoundation
import CoreML
import Photos
import UIKit
import Vision

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    let imagePicker = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
    }

    @IBAction func cameraTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Photo source", message: "Which one do you want to use?", preferredStyle: .actionSheet)

        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { action in self.library() }
        alert.addAction(galleryAction)

        let cameraAction = UIAlertAction(title: "Camera", style: .default) { action in self.camera() }
        alert.addAction(cameraAction)

        present(alert, animated: true, completion: nil)
    }

    func camera() {
        imagePicker.sourceType = .camera

        if AVCaptureDevice.authorizationStatus(for: .video) == AVAuthorizationStatus.authorized {
            showImagePicker()
        } else {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { granted in
                if granted {
                } else {
                    DispatchQueue.main.async {
                        self.showAlert("We need your permission to use your camera to check the picture and you've denied it 😢")
                    }
                }
            })
        }
    }

    func library() {
        imagePicker.sourceType = .photoLibrary
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            showImagePicker()
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    self.showImagePicker()
                } else {
                    DispatchQueue.main.async {
                        self.showAlert("We need your permission to use your Photo Library to check the picture and you've denied it 😢")
                    }
                }
            }
        }
    }

    func showImagePicker() {
        present(imagePicker, animated: true, completion: nil)
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "No permission",
                                      message: message,
                                      preferredStyle: .alert)
        let goToSettingsAction = UIAlertAction(title: "Settings", style: .cancel) { action in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                      options: [:],
                                      completionHandler: nil)
        }
        alert.addAction(goToSettingsAction)

        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)

        present(alert, animated: true, completion: nil)
    }

    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Loading CoreML model failed!")
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image")
            }

            if let firstResult = results.first {
                self.navigationItem.title = firstResult.identifier.contains("hotdog")
                    ? "Hotdog!"
                    : "Not hotdog..."
            }
        }

        let handler = VNImageRequestHandler(ciImage: image)

        do {
            try handler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let userPickedImage = info[.originalImage] as? UIImage {
            imageView.image = userPickedImage

            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert UIImage into CIImage")
            }

            detect(image: ciImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

extension ViewController: UINavigationControllerDelegate {}
