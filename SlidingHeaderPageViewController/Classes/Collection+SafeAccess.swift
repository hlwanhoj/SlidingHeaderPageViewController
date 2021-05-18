//
//  Collection+SafeAccess.swift
//  SlidingHeaderPageViewController
//
//  Created by hlwanhoj on 18/5/2021.
//

import Foundation

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension RangeReplaceableCollection {
    @discardableResult mutating func safelyRemove(at i: Self.Index) -> Self.Element? {
        if indices.contains(i) {
            return remove(at: i)
        }
        return nil
    }
    
    func safelyRemoving(at i: Self.Index) -> Self {
        var c = self
        c.safelyRemove(at: i)
        return c
    }
}
