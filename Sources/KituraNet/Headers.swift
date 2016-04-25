/**
 * Copyright IBM Corporation 2015
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

import Foundation

public struct Headers {
    
    ///
    /// The header storage
    ///
    internal var headers: [String: [String]] = [:]
    
    ///
    /// The map of case insensitive header fields to their actual names
    ///
    private var caseInsensitiveMap: [String: String] = [:]
    
    ///
    /// Gets the header (case insensitive)
    ///
    /// - Parameter key: the key
    ///
    /// - Returns: the value for the key
    ///
    public func getHeader(key: String) -> [String]? {
        if let headerKey = caseInsensitiveMap[key.lowercased()] {
            return headers[headerKey]
        }
        
        return nil
    }
    
    ///
    /// Set the header value
    ///
    /// - Parameter key: the key
    /// - Parameter value: the value
    ///
    /// - Returns: the value for the key as a list
    ///
    public mutating func setHeader(key: String, value: [String]) {
        
        headers[key] = value
        caseInsensitiveMap[key.lowercased()] = key
    }
    
    ///
    /// Set the header value
    ///
    /// - Parameter key: the key
    /// - Parameter value: the value
    ///
    /// - Returns: the value for the key as a list
    ///
    public mutating func setHeader(key: String, value: String) {
        
        setHeader(key, value: [value])
    }
    
    ///
    /// Append values to the header
    ///
    /// - Parameter key: the key
    /// - Parameter value: the value
    ///
    public mutating func append(key: String, value: [String]) {
        
        if headers[key] != nil {
            headers[key]? += value
        }
        else {
            setHeader(key, value: value)
        }
    }
    
    ///
    /// Append values to the header
    ///
    /// - Parameter key: the key
    /// - Parameter value: the value
    ///
    public mutating func append(key: String, value: String) {
        
        append(key, value: [value])
    }
    
    ///
    /// Remove the header by key (case insensitive)
    ///
    /// - Parameter key: the key
    ///
    public mutating func removeHeader(key: String) {
        
        if let headerKey = caseInsensitiveMap[key.lowercased()] {
            headers[headerKey] = nil
        }
        caseInsensitiveMap[key.lowercased()] = nil
    }
}