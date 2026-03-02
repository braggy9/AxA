// RoomID.swift
// AxA — Room identifiers and transition descriptors.

import Foundation

// MARK: - Room Identifiers

enum RoomID {
    case spawnBeach
    case crystalFields
    // More rooms added in later stages
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
