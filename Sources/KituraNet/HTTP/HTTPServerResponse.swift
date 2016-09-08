/*
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
 */

import KituraSys

import Foundation

// MARK: HTTPServerResponse

/// This class implements the `ServerResponse` protocol for outgoing server
/// responses via the HTTP protocol.
public class HTTPServerResponse : ServerResponse {

    /// Size of buffer
    private static let bufferSize = 2000

    /// Buffer for HTTP response line, headers, and short bodies
    private var buffer: Data

    /// Whether or not the HTTP response line and headers have been flushed.
    private var startFlushed = false

    /// The HTTP headers to be sent to the client as part of the response.
    public var headers = HeadersContainer()
    
    /// Status code
    private var status = HTTPStatusCode.OK.rawValue
    
    /// Corresponding socket processor
    private weak var processor : IncomingHTTPSocketProcessor?

    /// HTTP status code of the response.
    public var statusCode: HTTPStatusCode? {
        get {
            return HTTPStatusCode(rawValue: status)
        }
        set (newValue) {
            if let newValue = newValue, !startFlushed {
                status = newValue.rawValue
            }
        }
    }

    /// Initializes a HTTPServerResponse instance
    init(processor: IncomingHTTPSocketProcessor) {
        self.processor = processor
        buffer = Data(capacity: HTTPServerResponse.bufferSize)
        headers["Date"] = [SPIUtils.httpDate()]
    }

    /// Write a string as a response.
    ///
    /// - Parameter from: String data to be written.
    /// - Throws: Socket.error if an error occurred while writing to a socket.
    public func write(from string: String) throws {
        try flushStart()
        try writeToSocketThroughBuffer(text: string)
    }

    /// Write data as a response.
    ///
    /// - Parameter from: Data object that contains the data to be written.
    /// - Throws: Socket.error if an error occurred while writing to a socket.
    public func write(from data: Data) throws {
        if  let processor = processor {
            try flushStart()
            if  buffer.count + data.count > HTTPServerResponse.bufferSize  &&  buffer.count != 0  {
                processor.write(from: buffer)
                buffer.count = 0
            }
            if  data.count > HTTPServerResponse.bufferSize {
                processor.write(from: data)
            }
            else {
                buffer.append(data)
            }
        }
    }

    /// Write a string and end sending the response.
    ///
    /// - Parameter text: String to write to a socket.
    /// - Throws: Socket.error if an error occurred while writing to a socket.
    public func end(text: String) throws {
        try write(from: text)
        try end()
    }
    
    /// End sending the response.
    ///
    /// - Throws: Socket.error if an error occurred while writing to a socket.
    public func end() throws {
        if let processor = processor {
            processor.drain()
        
            try flushStart()
            
            let keepAlive = processor.isKeepAlive
            if  keepAlive {
                processor.keepAlive()
            }
            
            if  buffer.count > 0  {
                processor.write(from: buffer)
            }
            
            if !keepAlive  {
                processor.close()
            }
        }
    }

    /// Begin flushing the buffer
    ///
    /// - Throws: Socket.error if an error occurred while writing to a socket
    private func flushStart() throws {

        if  startFlushed  {
            return
        }

        var headerData = ""
        headerData.append("HTTP/1.1 ")
        headerData.append(String(status))
        headerData.append(" ")
        var statusText = HTTP.statusCodes[status]

        if  statusText == nil {
            statusText = ""
        }

        headerData.append(statusText!)
        headerData.append("\r\n")

        for (key, valueSet) in headers.headers {
            for value in valueSet {
                headerData.append(key)
                headerData.append(": ")
                headerData.append(value)
                headerData.append("\r\n")
            }
        }
        let keepAlive = processor?.isKeepAlive ?? false
        if  keepAlive {
            headerData.append("Connection: Keep-Alive\r\n")
            headerData.append("Keep-Alive: timeout=\(Int(IncomingHTTPSocketProcessor.keepAliveTimeout)), max=\((processor?.numberOfRequests ?? 1) - 1)\r\n")
        }
        else {
            headerData.append("Connection: Close\r\n")
        }
        
        headerData.append("\r\n")
        try writeToSocketThroughBuffer(text: headerData)
        startFlushed = true
    }

    /// Function to write Strings to the socket through the buffer
    ///
    /// Throws: Socket.error if an error occurred while writing to a socket
    private func writeToSocketThroughBuffer(text: String) throws {
        guard let processor = processor,
              let utf8Data = StringUtils.toUtf8String(text) else {
            return
        }

        if  buffer.count + utf8Data.count > HTTPServerResponse.bufferSize  &&  buffer.count != 0  {
            processor.write(from: buffer)
            buffer.count = 0
        }
        if  utf8Data.count > HTTPServerResponse.bufferSize {
            processor.write(from: utf8Data)
        }
        else {
            buffer.append(utf8Data)
        }
    }
    
    /// Reset this response object back to its initial state
    public func reset() {
        status = HTTPStatusCode.OK.rawValue
        buffer.count = 0
        startFlushed = false
        headers.removeAll()
        headers["Date"] = [SPIUtils.httpDate()]
    }
}
