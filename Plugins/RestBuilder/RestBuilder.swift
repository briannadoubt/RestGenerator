//
//  RustBuilder.swift
//  RustBuilder
//
//  Created by Brianna Zamora on 5/29/23.
//

import Foundation
import PackagePlugin

@main
struct RestBuilder: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        let generationTool = try context.tool(named: "RestGeneration")
        let input = context.package.directory.appending("spec.yaml")
        let output = context.pluginWorkDirectory.appending("Sources")
        return [
            .buildCommand(
                displayName: "Generate Rest Client",
                executable: generationTool.path,
                arguments: [input.string, output.string]
            )
        ]
    }
}
