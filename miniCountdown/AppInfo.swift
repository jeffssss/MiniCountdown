//
//  AppInfo.swift
//  miniCountdown
//
//  Created by Trae AI on 2024/06/10.
//

import Foundation

struct AppInfo: Identifiable, Hashable {
    let bundleIdentifier: String
    let name: String
    
    var id: String { bundleIdentifier }
}