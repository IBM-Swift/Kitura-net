/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import XCTest

@testable import KituraNet

import Foundation
import Dispatch

protocol KituraNetTest {

    func expectation(_ index: Int) -> XCTestExpectation
    func waitExpectation(timeout t: TimeInterval, handler: XCWaitCompletionHandler?)
}

extension KituraNetTest {

    func doSetUp() {
        PrintLogger.use()
    }

    func doTearDown() {
        //       sleep(10)
    }

    func performServerTest(_ delegate: ServerDelegate, asyncTasks: @escaping (XCTestExpectation) -> Void...) {
        do {
            let server = HTTP.createServer()
            server.delegate = delegate

            var expectations: [XCTestExpectation] = []

            for index in 0..<asyncTasks.count {
                expectations.append(expectation(index))
            }

            // convert var to let to get around compile error on 3.0 Release in Xcode 8.1
            let exps = expectations

            server.started {
                let requestQueue = DispatchQueue(label: "Request queue")

                for (index, asyncTask) in asyncTasks.enumerated() {
                    let expectation = exps[index]
                    requestQueue.async {
                        asyncTask(expectation)
                    }
                }
            }

            // server.started callback above needs to be set before server.listen
            try server.listen(on: 8090)

            waitExpectation(timeout: 10) { error in
                // blocks test until request completes
                server.stop()
                XCTAssertNil(error);
            }
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func performRequest(_ method: String, path: String, callback: @escaping ClientRequest.Callback, headers: [String: String]? = nil, requestModifier: ((ClientRequest) -> Void)? = nil) {
        var allHeaders = [String: String]()
        if  let headers = headers  {
            for  (headerName, headerValue) in headers  {
                allHeaders[headerName] = headerValue
            }
        }
        allHeaders["Content-Type"] = "text/plain"
        let options: [ClientRequest.Options] = [.method(method), .hostname("localhost"), .port(8090), .path(path), .headers(allHeaders)]
        let req = HTTP.request(options, callback: callback)
        if let requestModifier = requestModifier {
            requestModifier(req)
        }
        req.end()
    }
}

extension XCTestCase: KituraNetTest {

    func expectation(_ index: Int) -> XCTestExpectation {
        let expectationDescription = "\(type(of: self))-\(index)"
        return self.expectation(description: expectationDescription)
    }

    func waitExpectation(timeout t: TimeInterval, handler: XCWaitCompletionHandler?) {
        self.waitForExpectations(timeout: t, handler: handler)
    }
}
