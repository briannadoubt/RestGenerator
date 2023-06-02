//
//  RestGeneration.swift
//  RestGeneration
//
//  Created by Brianna Zamora on 5/28/23.
//

import Foundation
import ArgumentParser
import SwiftSyntax
import SwiftSyntaxBuilder
import Swagger
import SwagGenKit

var logs: [(Date, String)] = []

@main
struct RestGeneration: AsyncParsableCommand {
    @Argument(
        help: "The OpenAPI Swagger spec",
        completion: .file(extensions: ["yaml", "yml", "json"]),
        transform: { path in
            URL(fileURLWithPath: path)
        }
    )
    var spec: URL

    @Argument(
        help: "The directory where the generated files will be output",
        completion: .directory,
        transform: { path in
            URL(fileURLWithPath: path)
        }
    )
    var output: URL

    func run() async throws {
        try log("Running Rest Generation")

        guard FileManager.default.fileExists(atPath: spec.path) else {
            try log("Path for spec not found: \(spec.path)")
            throw RestGenerationError.specfileNotFound(path: spec.path)
        }

        try log("Instantiating spec file...")

        let swagger = try SwaggerSpec(url: spec)

        try log("Instantiated spec file!")

        let title = swagger.info.title.replacingOccurrences(of: " ", with: "")

        let servers = swagger.servers

        if servers.isEmpty {
            try log("No servers found")
        }

        for server in servers {
            let name = server.name ?? title
            try log("Creating \(name) Interface")

            let url = server.url

            func functions() -> String {
                var functions: [String] = []

                for operation in swagger.operations {
                    func parameters() -> String {
                        var parameters: [String] = []
                        for parameter in operation.parameters {
                            let value = parameter.value
                            let json = value.json
                            let schema = json["schema"] as? [AnyHashable: Any]
                            let type = schema?["type"] as? String
                            let parameterString = "\(value.name): \(type?.pascalCased ?? "Any")\(value.required ? "" : "?")"
                            parameters.append(parameterString)
                        }
                        return parameters.joined(separator: ", ")
                    }

                    let function = """
                        public func \(operation.generatedIdentifier)(\(parameters())) async throws \(
                            operation.defaultResponse?.name == nil
                                ? ""
                                : "-> " + (operation.defaultResponse?.name ?? "Void")
                            ){
                            try await \(operation.method)(
                                path: "\(operation.path.replacingOccurrences(of: "{", with: "\\(").replacingOccurrences(of: "}", with: ")"))",
                                query: nil, // [URLQueryItem]?
                                headers: nil, // [String : String]?\(operation.requestBody != nil ? operation.requestBody?.value.content.jsonSchema?.metadata.title ?? "" : "")
                                cachePolicy: cachePolicy,
                                timeout: timeout
                            )
                        }
                    """

                    functions.append(function)
                }
                return functions.joined(separator: "\n\n")
            }

            let restClient = """
                //
                //  \(name).swift
                //  \(name)
                //
                //  Created by \(swagger.info.contact?.name ?? "A Robot") on \(Date().formatted(date: .abbreviated, time: .omitted)).
                //

                import Foundation
                import Rest

                public actor \(name): RestClient {
                    public let baseUrl: URL
                    public let session: URLSessionProtocol

                    public let encoder = JSONEncoder()
                    public let decoder = JSONDecoder()

                    let timeout: TimeInterval = 60.0
                    let cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy

                    public init(baseUrl: URL = URL(string: "\(url)")!, session: URLSessionProtocol = URLSession.shared) {
                        self.baseUrl = baseUrl
                        self.session = session
                    }

                \(functions())
                }
                """

            let fileName = "\(name).swift"
            try log("Generated \(fileName)!")

            try log(restClient)

            try log("Saving \(fileName) to /Sources/\(name)/")

            let outputPath = "Sources/\(name)/\(fileName)"

            if !FileManager.default.fileExists(atPath: outputPath) {
                if !FileManager.default.fileExists(atPath: "Sources/\(name)") {
                    try FileManager.default.createDirectory(
                        atPath: "Sources/\(name)",
                        withIntermediateDirectories: true
                    )
                }
                FileManager.default.createFile(atPath: outputPath, contents: nil)
            }

            do {
                try restClient.write(
                    toFile: outputPath,
                    atomically: true,
                    encoding: .utf8
                )
                try log("Wrote contents to \(fileName) successfully!")
            } catch {
                try! log("Failed to write contents to \(fileName) with error: \(error)")
            }
        }
    }

    func log(_ message: String) throws {
        logs.append((Date(), message))
        try printLogs()
    }

    func printLogs() throws {
        try logs
            .map { date, message in
                if #available(iOS 16.0, macOS 13.0, *) {
                    return date.ISO8601Format(.iso8601(timeZone: .autoupdatingCurrent, includingFractionalSeconds: true, dateSeparator: .dash, dateTimeSeparator: .standard, timeSeparator: .colon)) + ": " + message
                } else {
                    return date.formatted() + ": " + message
                }
            }
            .joined(separator: "\n")
            .write(
                toFile: "logs.txt",
                atomically: true,
                encoding: .utf8
            )
    }
}

extension String {
    func appendLineToURL(fileURL: URL) throws {
         try (self + "\n").appendToURL(fileURL: fileURL)
     }

     func appendToURL(fileURL: URL) throws {
         let data = self.data(using: String.Encoding.utf8)!
         try data.append(fileURL: fileURL)
     }
 }

extension String {
    var lowercasingFirst: String { prefix(1).lowercased() + dropFirst() }
    var uppercasingFirst: String { prefix(1).uppercased() + dropFirst() }

    var camelCased: String {
        guard !isEmpty else { return "" }
        let parts = components(separatedBy: .alphanumerics.inverted)
        let first = parts.first!.lowercasingFirst
        let rest = parts.dropFirst().map { $0.uppercasingFirst }

        return ([first] + rest).joined()
    }

    var pascalCased: String {
        guard !isEmpty else { return "" }
        let parts = components(separatedBy: .alphanumerics.inverted)
        let first = parts.first!.uppercasingFirst
        let rest = parts.dropFirst().map { $0.uppercasingFirst }
        return ([first] + rest).joined()
    }
}

 extension Data {
     func append(fileURL: URL) throws {
         if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
             defer {
                 fileHandle.closeFile()
             }
             fileHandle.seekToEndOfFile()
             fileHandle.write(self)
         }
         else {
             try write(to: fileURL, options: .atomic)
         }
     }
 }

extension OutputStream: TextOutputStream {
    public func write(_ string: String) {
        var s = string
        write(&s, maxLength: s.maximumLengthOfBytes(using: .utf8))
    }
}
