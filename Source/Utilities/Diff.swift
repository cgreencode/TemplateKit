//
//  Diff.swift
//  TemplateKit
//
//  Created by Matias Cudich on 10/30/16.
//  Copyright © 2016 Matias Cudich. All rights reserved.
//

import Foundation

public enum DiffStep: Equatable {
  case insert(Int)
  case delete(Int)
  case move(Int, Int)
  case update(Int)
}

public func ==(lhs: DiffStep, rhs: DiffStep) -> Bool {
  switch (lhs, rhs) {
  case let (.insert(lhsIndex), .insert(rhsIndex)):
    return lhsIndex == rhsIndex
  case let (.delete(lhsIndex), .delete(rhsIndex)):
    return lhsIndex == rhsIndex
  case let (.move(lhsFromIndex, lhsToIndex), .move(rhsFromIndex, rhsToIndex)):
    return lhsFromIndex == rhsFromIndex && lhsToIndex == rhsToIndex
  case let (.update(lhsIndex), .update(rhsIndex)):
    return lhsIndex == rhsIndex
  default:
    return false
  }
}

enum Counter {
  case zero
  case one
  case many

  mutating func increment() {
    switch self {
    case .zero:
      self = .one
    case .one:
      self = .many
    case .many:
      break
    }
  }
}

class SymbolEntry {
  var oc: Counter = .zero
  var nc: Counter = .zero
  var olno = [Int]()

  var occursInBoth: Bool {
    return oc != .zero && nc != .zero
  }
}

enum Entry {
  case symbol(SymbolEntry)
  case index(Int)
}

// Based on http://dl.acm.org/citation.cfm?id=359467.
//
// And other implementations at:
// * https://github.com/Instagram/IGListKit
// * https://github.com/andre-alves/PHDiff
//
public func diff<T: Hashable>(_ old: [T], _ new: [T]) -> [DiffStep] {
  var table = [Int: SymbolEntry]()
  var oa = [Entry]()
  var na = [Entry]()

  // Pass 1 comprises the following: (a) each line i of file N is read in sequence; (b) a symbol
  // table entry for each line i is created if it does not already exist; (c) NC for the line's
  // symbol table entry is incremented; and (d) NA [i] is set to point to the symbol table entry of
  // line i.
  for item in new {
    let entry = table[item.hashValue] ?? SymbolEntry()
    table[item.hashValue] = entry
    entry.nc.increment()
    na.append(.symbol(entry))
  }

  // Pass 2 is identical to pass 1 except that it acts on file O, array OA, and counter OC,
  // and OLNO for the symbol table entry is set to the line's number.
  for (index, item) in old.enumerated() {
    let entry = table[item.hashValue] ?? SymbolEntry()
    table[item.hashValue] = entry
    entry.oc.increment()
    entry.olno.append(index)
    oa.append(.symbol(entry))
  }

  // In pass 3 we use observation 1 and process only those lines having NC = OC = 1. Since each
  // represents (we assume) the same unmodified line, for each we replace the symbol table pointers
  // in NA and OA by the number of the line in the other file. For example, if NA[i] corresponds to
  // such a line, we look NA[i] up in the symbol table and set NA[i] to OLNO and OA[OLNO] to i.
  // In pass 3 we also "find" unique virtual lines immediately before the first and immediately
  // after the last lines of the files.
  for (index, item) in na.enumerated() {
    if case .symbol(let entry) = item, entry.occursInBoth {
      guard entry.olno.count > 0 else { continue }

      let oldIndex = entry.olno.removeFirst()
      na[index] = .index(oldIndex)
      oa[oldIndex] = .index(index)
    }
  }

  // In pass 4, we apply observation 2 and process each line in NA in ascending order: If NA[i]
  // points to OA[j] and NA[i + 1] and OA[j + 1] contain identical symbol table entry pointers, then
  // OA[j + 1] is set to line i + 1 and NA[i + 1] is set to line j + 1.
  var i = 1
  while (i < na.count - 1) {
    if case .index(let j) = na[i], j + 1 < oa.count {
      if case .symbol(let newEntry) = na[i + 1], case .symbol(let oldEntry) = oa[j + 1], newEntry === oldEntry {
        na[i + 1] = .index(j + 1)
        oa[j + 1] = .index(i + 1)
      }
    }
    i += 1
  }

  // In pass 5, we also apply observation 2 and process each entry in descending order: if NA[i]
  // points to OA[j] and NA[i - 1] and OA[j - 1] contain identical symbol table pointers, then
  // NA[i - 1] is replaced by j - 1 and OA[j - 1] is replaced by i - 1.
  i = na.count - 1
  while (i > 0) {
    if case .index(let j) = na[i], j - 1 >= 0 {
      if case .symbol(let newEntry) = na[i - 1], case .symbol(let oldEntry) = oa[j - 1], newEntry === oldEntry {
        na[i - 1] = .index(j - 1)
        oa[j - 1] = .index(i - 1)
      }
    }
    i -= 1
  }

  var steps = [DiffStep]()

  var deleteOffsets = Array(repeating: 0, count: old.count)
  var runningOffset = 0
  for (index, item) in oa.enumerated() {
    deleteOffsets[index] = runningOffset
    if case .symbol(_) = item {
      steps.append(.delete(index))
      runningOffset += 1
    }
  }

  runningOffset = 0

  for (index, item) in na.enumerated() {
    switch item {
    case .symbol(_):
      steps.append(.insert(index))
      runningOffset += 1
    case .index(let oldIndex):
      // The object has changed, so it should be updated.
      if old[oldIndex] != new[index] {
        steps.append(.update(index))
      }

      let deleteOffset = deleteOffsets[oldIndex]
      // The object is not at the expected position, so move it.
      if (oldIndex - deleteOffset + runningOffset) != index {
        steps.append(.move(oldIndex, index))
      }
    }
  }

  // Sort the steps to allow for a single-pass array update.
  var insertions = [DiffStep]()
  var updates = [DiffStep]()
  var indexedDeletions: [[DiffStep]] = Array(repeating: [], count: old.count)

  for step in steps {
    switch step {
    case .insert:
      insertions.append(step)
    case let .delete(fromIndex):
      indexedDeletions[fromIndex].append(step)
    case let .move(fromIndex, toIndex):
      insertions.append(.insert(toIndex))
      indexedDeletions[fromIndex].append(.delete(fromIndex))
    case .update:
      updates.append(step)
    }
  }

  let deletions = indexedDeletions.flatMap { $0.first }.reversed()

  return deletions + insertions + updates
}
