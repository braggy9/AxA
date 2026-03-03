// RoomID.swift
// AxA — Room identifiers and transition descriptors.

import Foundation

// MARK: - Room Identifiers

enum RoomID {
    case spawnBeach
    case crystalFields
    case lakeShoreEast
    case saltCave
}

// MARK: - Edge

enum Edge {
    case top, bottom, left, right
}

// MARK: - RoomTransition

struct RoomTransition {
    let destination: RoomID
    let entryEdge: Edge   // which edge the player enters from in the destination room
}
