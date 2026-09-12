import AppKit
import SwiftUI
import UniformTypeIdentifiers
import WebKit

enum Seat {
    static let local = URL(string: "rizal://seat/mac.html")!
    static let onlineMind = URL(string: "https://raw.githubusercontent.com/rizalward/Rbot/main/handoff/ONLINE-MIND.md")!
    static let onlineMindTwin = URL(string: "https://raw.githubusercontent.com/RIZALEON/PROJECTR/main/handoff/ONLINE-MIND.md")!
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
            case "mp4": mime = "video/mp4"
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
        config.userContentController.add(context.coordinator, name: "om")
        let intercept = WKUserScript(source: Self.interceptJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(intercept)
        config.setURLSchemeHandler(context.coordinator.handler, forURLScheme: "rizal")
        let view = WKWebView(frame: .zero, configuration: config)
        view.setValue(false, forKey: "drawsBackground")
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        context.coordinator.webView = view
        view.load(URLRequest(url: Seat.local))
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }

    static let interceptJS = """
    (function(){
      document.addEventListener('submit', function(e){
        var form = e.target;
        if (!form || !form.querySelector) return;
        var input = form.querySelector('input:not([type=file])');
        if (!input) return;
        var t = String(input.value || '').trim();
        if (!/^(read )?online[- ]?mind\\b/i.test(t) && !/ONLINE-MIND/i.test(t) && t.indexOf('1Thji06t2cjSCvzWgtI-GIHSRywNP7BmVEegaFsfgfXE') < 0) return;
        e.preventDefault();
        e.stopImmediatePropagation();
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.om) {
          window.webkit.messageHandlers.om.postMessage(t);
        }
      }, true);
      window.__rizalOm = function(text){
        var host = document.querySelector('.overflow-y-auto') || document.body;
        var d = document.createElement('div');
        d.setAttribute('data-om','1');
        d.style.cssText = 'max-width:92%;white-space:pre-wrap;font-size:15px;line-height:1.625;padding:8px 0;color:#e8e6dc';
        d.textContent = text;
        host.appendChild(d);
        d.scrollIntoView({block:'end'});
      };
    })();
    """

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let handler = SeatHandler()
        weak var webView: WKWebView?

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "om" else { return }
            Task { await self.fetchMind() }
        }

        private func fetchMind() async {
            let urls = [Seat.onlineMind, Seat.onlineMindTwin]
            var body = "Airplane or unreachable. Gut only. Function 0 still talks."
            for url in urls {
                do {
                    var req = URLRequest(url: url)
                    req.cachePolicy = .reloadIgnoringLocalCacheData
                    req.timeoutInterval = 12
                    let (data, resp) = try await URLSession.shared.data(for: req)
                    let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                    if (200 ..< 300).contains(code), let text = String(data: data, encoding: .utf8), text.count > 20 {
                        let clip = text.count > 4000 ? String(text.prefix(4000)) + "\n…" : text
                        body = "Online mind read (green). Chief lines kept.\n\n" + clip + "\n\nNo EVOLVE this fetch. Talk only."
                        break
                    }
                } catch {
                    continue
                }
            }
            let payload = body
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "`", with: "\\`")
                .replacingOccurrences(of: "$", with: "\\$")
            let js = "window.__rizalOm && window.__rizalOm(`\(payload)`)"
            await MainActor.run {
                self.webView?.evaluateJavaScript(js, completionHandler: nil)
            }
        }

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
