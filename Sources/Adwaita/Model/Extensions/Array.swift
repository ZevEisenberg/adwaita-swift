//
//  Array.swift
//  Adwaita
//
//  Created by david-swift on 06.08.23.
//

import Foundation

extension Array: View where Element == View {

    /// The array's view body is the array itself.
    public var view: Body { self }

    /// Get a widget from a collection of views.
    /// - Parameter modifiers: Modify views before being updated.
    /// - Returns: A widget.
    public func widget(modifiers: [(View) -> View]) -> Widget {
        if count == 1, let widget = self[safe: 0]?.widget(modifiers: modifiers) {
            return widget
        } else {
            var modified = self
            for (index, view) in modified.enumerated() {
                for modifier in modifiers {
                    modified[safe: index] = modifier(view)
                }
            }
            return VStack { modified }
        }
    }

    /// Update a collection of views with a collection of view storages.
    /// - Parameters:
    ///     - storage: The collection of view storages.
    ///     - modifiers: Modify views before being updated.
    ///     - updateProperties: Whether to update properties.
    public func update(_ storage: [ViewStorage], modifiers: [(View) -> View], updateProperties: Bool) {
        for (index, element) in enumerated() {
            if let storage = storage[safe: index] {
                element
                    .widget(modifiers: modifiers)
                    .updateStorage(storage, modifiers: modifiers, updateProperties: updateProperties)
            }
        }
    }

}

extension Array where Element == WindowSceneGroup {

    /// Get the content of an array of window scene groups.
    /// - Returns: The array of windows.
    public func windows() -> [WindowScene] {
        flatMap { $0.windows() }
    }

}

extension Array where Element == String {

    /// Get the C version of the array.
    var cArray: UnsafePointer<UnsafePointer<CChar>?>? {
        let cStrings = self.map { $0.utf8CString }
        let cStringPointers = cStrings.map { $0.withUnsafeBufferPointer { $0.baseAddress } }
        let optionalCStringPointers = cStringPointers + [nil]
        var optionalCStringPointersCopy = optionalCStringPointers
        optionalCStringPointersCopy.withUnsafeMutableBufferPointer { bufferPointer in
            bufferPointer.baseAddress?.advanced(by: cStrings.count).pointee = nil
        }
        let flatArray = optionalCStringPointersCopy.compactMap { $0 }
        let pointer = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: flatArray.count + 1)
        for (index, element) in flatArray.enumerated() {
            pointer.advanced(by: index).pointee = element
        }
        pointer.advanced(by: flatArray.count).pointee = nil
        return UnsafePointer(pointer)
    }

}

extension Array {

    /// Accesses the element at the specified position safely.
    /// - Parameters:
    ///   - index: The position of the element to access.
    ///
    ///   Access and set elements the safe way:
    ///   ```swift
    ///   var array = ["Hello", "World"]
    ///   print(array[safe: 2] ?? "Out of range")
    ///   ```
    public subscript(safe index: Int?) -> Element? {
        get {
            if let index, checkIndex(index) {
                return self[index]
            }
            return nil
        }
        set {
            if let index, let value = newValue, checkIndex(index) {
                self[index] = value
            }
        }
    }

    /// Check if a given index is valid for the array.
    /// - Parameter index: The index to test.
    /// - Returns: Return whether the index is valid or not.
    private func checkIndex(_ index: Int) -> Bool {
        index < count && index >= 0
    }

}
