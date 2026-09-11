import AppKit
import SwiftUI
import UniformTypeIdentifiers
import WebKit

enum Seat {
    static let local = URL(string: "rizal://seat/mac.html")!
}

struct SeatView: View {
    var body: some View {
        SeatWebView()
            .background(Color.black)
            .navigationTitle("PROJECT Я")
    }
}

final class SeatHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        var path = url.path
        if path.isEmpty || path == "/" { path = "/mac.html" }
        if path.hasPrefix("/") { path.removeFirst() }
        guard
            let root = Bundle.main.resourceURL?.appendingPathComponent("www", isDirectory: true)
        else {
            fail(task, url: url, status: 500)
            return
        }
        let file = root.appendingPathComponent(path)
        let allowed = root.standardizedFileURL.path
        guard file.standardizedFileURL.path.hasPrefix(allowed), FileManager.default.fileExists(atPath: file.path) else {
            fail(task, url: url, status: 404)
            return
        }
        do {
            let data = try Data(contentsOf: file)
            let ext = file.pathExtension.lowercased()
            let mime: String
            switch ext {
            case "html": mime = "text/html"
            case "js": mime = "text/javascript"
            case "css": mime = "text/css"
            case "png": mime = "image/png"
            case "jpg", "jpeg": mime = "image/jpeg"
            case "svg": mime = "image/svg+xml"
            default:
                mime = UTType(filenameExtension: ext)?.preferredMIMEType ?? "application/octet-stream"
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Type": mime,
                    "Content-Length": String(data.count),
                    "Cache-Control": "no-cache",
                    "Access-Control-Allow-Origin": "*",
                ]
            )!
            task.didReceive(response)
            task.didReceive(data)
            task.didFinish()
        } catch {
            fail(task, url: url, status: 500)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private func fail(_ task: WKURLSchemeTask, url: URL, status: Int) {
        let body = Data("seat dark".utf8)
        let response = HTTPURLResponse(
            url: url,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/plain"]
        )!
        task.didReceive(response)
        task.didReceive(body)
        task.didFinish()
    }
}

struct SeatWebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.isElementFullscreenEnabled = true
        config.setURLSchemeHandler(context.coordinator.handler, forURLScheme: "rizal")
        let view = WKWebView(frame: .zero, configuration: config)
        view.setValue(false, forKey: "drawsBackground")
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.load(URLRequest(url: Seat.local))
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let handler = SeatHandler()

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            if url.scheme == "rizal" {
                decisionHandler(.allow)
                return
            }
            if url.scheme == "http" || url.scheme == "https" {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
            }
            return nil
        }
    }
}
