//
//  RestGenerator.swift
//  RestGenerator
//
//  Created by Brianna Zamora on 5/28/23.
//

import Foundation
import PackagePlugin

@main
struct RestGenerator: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let generationTool = try context.tool(named: "RestGeneration")
        let input = context.package.directory.appending("spec.yaml")
        let output = context.pluginWorkDirectory
        if #available(macOS 13.0, *) {
            try Process.run(
                URL(filePath: generationTool.path.string),
                arguments: [input.string, output.string]
            )
        } else {
            try Process.run(
                URL(fileURLWithPath: generationTool.path.string),
                arguments: [input.string, output.string]
            )
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension RestGenerator: XcodeCommandPlugin {
    func performCommand(context: XcodeProjectPlugin.XcodePluginContext, arguments: [String]) throws {
        let generationTool = try context.tool(named: "RestGeneration")
        let input = context.xcodeProject.directory.appending("spec.yaml")
        let output = context.pluginWorkDirectory
        if #available(macOS 13.0, *) {
            try Process.run(
                URL(filePath: generationTool.path.string),
                arguments: [input.string, output.string]
            )
        } else {
            try Process.run(
                URL(fileURLWithPath: generationTool.path.string),
                arguments: [input.string, output.string]
            )
        }
    }
}
#endif
