// 
// Copyright 2021 New Vector Ltd
// Copyright 2021 Qwerty Networks
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit
import WebKit

class MasterWebView: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    var id = ""
    
    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userAgent = "Cron"
        let urlRequest = URL(string: id)!
    
        webView.customUserAgent = userAgent
        webView.load(URLRequest(url: urlRequest))
        
        let backButton = UIBarButtonItem(title: "back", style: .done, target: webView, action: #selector(webView!.goBack))
        self.navigationItem.rightBarButtonItem = backButton
        navigationController?.isToolbarHidden = false
    }
}
