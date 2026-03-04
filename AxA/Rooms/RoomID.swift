// RoomID.swift
// AxA — Room identifiers and transition descriptors.

import Foundation

// MARK: - Room Identifiers

enum RoomID {
    case spawnBeach
    case crystalFields
    case lakeShoreEast
    case saltCave
    case lakeShoreWest
    case nonoGrove
    case monontoeLair
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
