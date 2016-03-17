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

import BlueSocket

import Foundation

// MARK: ServerResponse

public class ServerResponse : BlueSocketWriter {

    ///
    /// Socket for the ServerResponse
    ///
    private var socket: BlueSocket?
    
    ///
    /// TODO: ???
    ///
    private var startFlushed = false
    
    ///
    /// TODO: ???
    ///
    private var singleHeaders: [String: String] = [:]
    
    ///
    /// TODO: ???
    ///
    private var multiHeaders: [String: [String]] = [:]
    
    ///
    /// Status code
    ///
    public var status = HttpStatusCode.OK.rawValue
    
    ///
    /// Status code
    ///
    public var statusCode: HttpStatusCode? {
        get {
            return HttpStatusCode(rawValue: status)
        }
        set (newValue) {
            if let newValue = newValue where !startFlushed {
                status = newValue.rawValue
            }
        }
    }
    
    ///
    /// Initializes a ServerResponse instance
    ///
    init(socket: BlueSocket) {
        
        self.socket = socket
        setHeader("Date", value: SpiUtils.httpDate())
        
    }
    
    ///
    /// Get a specific headers for the response by key
    ///
    /// - Parameter key: the header key
    ///
    public func getHeader(key: String) -> String? {
        
        return singleHeaders[key]
        
    }
    
    ///
    /// Get all values on a specific key
    ///
    /// - Parameter key: the header key
    ///
    /// - Returns: a list of String values
    ///
    public func getHeaders(key: String) -> [String]? {
        
        return multiHeaders[key]
        
    }
    
    ///
    /// Set the value for a header
    ///
    /// - Parameter key: key 
    /// - Parameter value: the value
    ///
    public func setHeader(key: String, value: String) {
        singleHeaders[key] = value
        multiHeaders.removeValueForKey(key)
    }

    ///
    /// Set the value for a header (list)
    ///
    /// - Parameter key: key
    /// - Parameter value: the value
    ///
    public func setHeader(key: String, value: [String]) {
        multiHeaders[key] = value
        singleHeaders.removeValueForKey(key)
    }
    
    ///
    /// Remove a key from the header
    ///
    /// - Parameter key: key
    ///
    public func removeHeader(key: String) {
        singleHeaders.removeValueForKey(key)
        multiHeaders.removeValueForKey(key)
    }
    
    ///
    /// Write a string as a response 
    ///
    /// - Parameter text: String to write out socket
    ///
    /// - Throws: ???
    ///
    public func writeString(text: String) throws {
        
        if  let socket = socket {
            try flushStart()
            try socket.writeString(text)
        }
        
    }
    
    ///
    /// Write data as a response
    ///
    /// - Parameter data: data to write out socket
    ///
    /// - Throws: ???
    ///
    public func writeData(data: NSData) throws {
        
        if  let socket = socket {
            try flushStart()
            try socket.writeData(data)
        }
        
    }
    
    ///
    /// End the response
    ///
    /// - Parameter text: String to write out socket
    ///
    /// - Throws: ???
    ///
    public func end(text: String) throws {
        try writeString(text)
        try end()
    }
    
    ///
    /// End sending the response
    ///
    /// - Throws: ???
    ///
    public func end() throws {
        if  let socket = socket {
            try flushStart()
            socket.close()
        }
        socket = nil
    }
    
    ///
    /// Begin flushing the buffer
    ///
    /// - Throws: ???
    ///
    private func flushStart() throws {

        guard let socket = socket where !startFlushed else {
            return
        }

        try socket.writeString("HTTP/1.1 ")
        try socket.writeString(String(status))
        try socket.writeString(" ")
        var statusText = Http.statusCodes[status]

        if  statusText == nil {
            statusText = ""
        }

        try socket.writeString(statusText!)
        try socket.writeString("\r\n")

        for (key, value) in singleHeaders {
            try socket.writeString(key)
            try socket.writeString(": ")
            try socket.writeString(value)
            try socket.writeString("\r\n")
        }

        for (key, valueSet) in multiHeaders {
            for value in valueSet {
                try socket.writeString(key)
                try socket.writeString(": ")
                try socket.writeString(value)
                try socket.writeString("\r\n")
            }
        }

        try socket.writeString("\r\n")
        startFlushed = true
    }
}
