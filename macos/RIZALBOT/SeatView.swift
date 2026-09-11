import AppKit
import SwiftUI
import UniformTypeIdentifiers
import WebKit

enum Seat {
    static let coordinator = "https://grok.com/project/6ca3b685-f773-4747-b54c-d9c47fdc15e4"
    static let local = URL(string: "rizal://seat/mac.html")!
}

struct SeatView: View {
    @State private var onlineNerve = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("RIZALBOT Mac")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(onlineNerve ? "Seat" : "Coordinator") {
                    onlineNerve.toggle()
                    let url = onlineNerve ? URL(string: Seat.coordinator)! : Seat.local
                    NotificationCenter.default.post(name: .seatReload, object: url)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            Divider()
            SeatWebView()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("RIZALBOT Mac")
    }
}

extension Notification.Name {
    static let seatReload = Notification.Name("rizalbot.seat.reload")
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
            case "json", "webmanifest": mime = "application/json"
            case "woff2": mime = "font/woff2"
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
        view.navigationDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.setValue(false, forKey: "drawsBackground")
        view.load(URLRequest(url: Seat.local))
        context.coordinator.observe(view)
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let handler = SeatHandler()
        private var token: NSObjectProtocol?

        func observe(_ view: WKWebView) {
            token = NotificationCenter.default.addObserver(forName: .seatReload, object: nil, queue: .main) { note in
                if let url = note.object as? URL { view.load(URLRequest(url: url)) }
            }
        }
    }
}
