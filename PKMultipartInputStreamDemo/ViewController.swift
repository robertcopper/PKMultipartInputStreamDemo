//
//  ViewController.swift
//  PKMultipartInputStreamDemo
//
//  Created by Bob Wakefield on 5/2/18.
//  Copyright © 2018 Copper Mobile. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    fileprivate var stream: PKMultipartInputStream?
    fileprivate var session: URLSession?
    fileprivate var request: URLRequest?
    fileprivate var task: URLSessionTask?
    fileprivate var accumulated = Data()
    fileprivate var httpResponse: HTTPURLResponse?

    @IBOutlet weak var secure: UISwitch?
    @IBOutlet weak var urlText: UITextField?
    @IBOutlet weak var boundary: UILabel?
    @IBOutlet weak var action: UIButton?
    @IBOutlet weak var progress: UIProgressView?
    @IBOutlet weak var message: UILabel?
    @IBOutlet weak var errorMessage: UILabel?
    @IBOutlet weak var response: UILabel?

    @IBAction func upload(sender: UIButton) {

        progress?.setProgress(0, animated: false)
        self.accumulated = Data()

        let bodyStream = setupStream()
        boundary?.text = bodyStream.boundary
        guard let text = urlText?.text,
              let request = setupRequest(secure: secure?.isOn ?? false, urlText: text, bodyStream: bodyStream)
        else { return }
        self.request = request
        self.stream = bodyStream
        let task = self.session?.uploadTask(withStreamedRequest: request)

        task?.resume()

        secure?.isEnabled = false
        action?.isEnabled = false
        urlText?.isEnabled = false
        message?.text = "Starting data POST"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        progress?.setProgress(0, animated: false)

        let session = setupSession()
        self.session = session
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController {

    func setupStream() -> PKMultipartInputStream {

        let bodyStream = PKMultipartInputStream()

        bodyStream.addPart(withName: "string1", string: "string1 value")

//        if let data1 = loadResourceData(name: "Icon", type: "png") {
//
//            bodyStream.addPart(withName: "data1", data: data1)
//        }

        bodyStream.addPart(withName: "string2", string: "string2 value")

//        if let data2 = loadResourceData(name: "Info", type: "plist") {
//
//            bodyStream.addPart(withName: "data2", data: data2)
//        }

        if let path2 = Bundle.main.path(forResource: "file2", ofType: "jpg") {

            bodyStream.addPart(withName: "file2", path: path2)
        }

        bodyStream.addPart(withName: "string3", string: "string3 value")

//        if let url3 = Bundle.main.executableURL, let data3 = try? Data(contentsOf: url3) {
//
//            bodyStream.addPart(withName: "data3", data: data3)
//        }
//
//        if let path3 = Bundle.main.path(forResource: "file3", ofType: "mp3") {
//
//            bodyStream.addPart(withName: "file3", path: path3)
//        }

        return bodyStream
    }

    private func loadResourceData(name: String, type: String) -> Data? {

        var data: Data?
        if let path = Bundle.main.path(forResource: "Icon", ofType: "png") {

            let url = URL(fileURLWithPath: path)
            data = try? Data(contentsOf: url)
        }

        return data
    }

    func setupSession() -> URLSession {

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)

        return session
    }

    func setupRequest(secure: Bool, urlText: String, bodyStream: PKMultipartInputStream) -> URLRequest? {

        guard !urlText.isEmpty else { return nil }

        let prefix = secure ? "https://" : "http://"
        guard let url = URL(string: prefix + urlText) else { return nil }

        let length = bodyStream.length
        let boundary = bodyStream.boundary

        var request = URLRequest(url: url)
        let contentType = "multipart/form-data; boundary=" + boundary
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(String(length), forHTTPHeaderField: "Content-Length")
        request.httpMethod = "POST"

        return request
    }
}

extension ViewController: URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {

        let bodyStream = self.stream

        completionHandler(bodyStream)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        self.accumulated.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        DispatchQueue.main.async {

            self.message?.text = "Data post complete"

            if let error = error {

                self.errorMessage?.text = error.localizedDescription
            }

            var responseString = ""
            if let response = self.httpResponse {

                let headers = response.allHeaderFields
                for (key,value) in headers {

                    let keyString = key as? String ?? "unknown key type"
                    let valueString = value as? String ?? "unknown value type"

                    responseString += keyString + ": " + valueString + "\r\n"
                }

                responseString += String(response.statusCode) + ": "
                responseString += HTTPURLResponse.localizedString(forStatusCode: response.statusCode)

            } else {

                responseString = String(data: self.accumulated, encoding: .utf8) ?? "no response accumulated"
            }

            self.response?.text = responseString
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {

        let progress = Float(totalBytesSent)/Float(totalBytesExpectedToSend)

        DispatchQueue.main.async {

            self.progress?.setProgress(progress, animated: true)
        }
    }

}

extension ViewController: URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {

        self.httpResponse = response as? HTTPURLResponse

        completionHandler(.allow)
    }
}
