//
//  Session.swift
//  WWDC
//
//  Created by Guilherme Rambo on 06/02/17.
//  Copyright © 2017 Guilherme Rambo. All rights reserved.
//

import Cocoa
import RealmSwift

/// Specifies a session in an event, with its related keywords, assets, instances, user favorites and user bookmarks
public class Session: Object {

    /// Unique identifier
    public dynamic var identifier = ""

    /// Session year
    public dynamic var year = 0

    /// Session number
    public dynamic var number = ""

    /// Title
    public dynamic var title = ""

    public dynamic var staticContentId = ""

    /// Description
    public dynamic var summary = ""

    /// The event identifier for the event this session belongs to
    public dynamic var eventIdentifier = ""

    /// Track name
    public dynamic var trackName = ""

    /// Track identifier
    public dynamic var trackIdentifier = ""

    /// The session's focuses
    public let focuses = List<Focus>()

    /// The session's assets (videos, slides, links)
    public let assets = List<SessionAsset>()

    /// Whether this session is downloaded
    public dynamic var isDownloaded = false

    /// Session favorite
    public let favorites = List<Favorite>()

    /// Session progress
    public let progresses = List<SessionProgress>()

    /// Session bookmarks
    public let bookmarks = List<Bookmark>()

    /// Transcript identifier for the session
    public dynamic var transcriptIdentifier: String = ""

    /// Shortcut to get the full transcript text (used during search)
    public dynamic var transcriptText: String = ""

    /// Fetches and returns the transcript object associated with the session
    public func transcript() -> Transcript? {
        guard let realm = realm else { return nil }
        guard !transcriptIdentifier.isEmpty else { return nil }

        return realm.objects(Transcript.self).filter("identifier == %@", transcriptIdentifier).first
    }

    /// The session's track
    public let track = LinkingObjects(fromType: Track.self, property: "sessions")

    /// The event this session belongs to
    public let event = LinkingObjects(fromType: Event.self, property: "sessions")

    /// Instances of this session
    public let instances = LinkingObjects(fromType: SessionInstance.self, property: "session")

    public override static func primaryKey() -> String? {
        return "identifier"
    }

    //    public func transcript() -> Transcript? {
    //        guard let realm = self.realm else { return nil }
    //        guard !transcriptIdentifier.isEmpty else { return nil }
    //
    //        return realm.objects(Transcript.self).filter("identifier == %@", self.transcriptIdentifier).first
    //    }

    public static let videoPredicate: NSPredicate = NSPredicate(format: "ANY assets.rawAssetType == %@", SessionAssetType.streamingVideo.rawValue)

    public static func standardSort(sessionA: Session, sessionB: Session) -> Bool {
        guard let eventA = sessionA.event.first, let eventB = sessionB.event.first else { return false }
        guard let trackA = sessionA.track.first, let trackB = sessionB.track.first else { return false }

        if trackA.order == trackB.order {
            if eventA.startDate == eventB.startDate {
                return sessionA.title < sessionB.title
            } else {
                return eventA.startDate > eventB.startDate
            }
        } else {
            return trackA.order < trackB.order
        }
    }

    public static func standardSortForSchedule(sessionA: Session, sessionB: Session) -> Bool {
        guard let instanceA = sessionA.instances.first, let instanceB = sessionB.instances.first else { return false }

        return SessionInstance.standardSort(instanceA: instanceA, instanceB: instanceB)
    }

    func merge(with other: Session, in realm: Realm) {
        assert(other.identifier == identifier, "Can't merge two objects with different identifiers!")

        title = other.title
        number = other.number
        summary = other.summary
        eventIdentifier = other.eventIdentifier
        trackIdentifier = other.trackIdentifier
        staticContentId = other.staticContentId
        trackName = other.trackName

        // merge assets
        let assets = other.assets.filter { otherAsset in
            return !self.assets.contains(where: { $0.identifier == otherAsset.identifier })
        }

        self.assets.append(objectsIn: assets)

        let otherFocuses = other.focuses.map { newFocus -> (Focus) in
            if newFocus.realm == nil,
                let existingFocus = realm.object(ofType: Focus.self, forPrimaryKey: newFocus.name)
            {
                return existingFocus
            } else {
                return newFocus
            }
        }

        focuses.removeAll()
        focuses.append(objectsIn: otherFocuses)
    }
    
}
