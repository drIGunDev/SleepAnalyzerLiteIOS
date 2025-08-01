//
//  Tools.swift
//  BLECommunication
//
//  Created by Dolores(chatGPT) on 01.04.25.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localized(with args: CVarArg...) -> String {
        String(format: self.localized, arguments: args)
    }
}
