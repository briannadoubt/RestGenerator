//
//  RestGenerationError.swift
//  RestGeneration
//
//  Created by Brianna Zamora on 5/28/23.
//

import Foundation

public enum RestGenerationError: LocalizedError {
    case specfileNotFound(path: String)

    public var localizedDescription: String {
        switch self {
        case .specfileNotFound(let path):
            return "Spec not found at path: \(path)"
        }
    }
}
