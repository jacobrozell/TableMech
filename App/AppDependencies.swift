import Foundation
import Observation
import SwiftData
import TableMechData
import TableMechDomain

@Observable
@MainActor
public final class AppDependencies {
    public let content: any ContentCatalogRepository
    public let matchSessions: any MatchSessionRepository
    public let releaseSurface: any ReleaseSurfaceProviding
    public let logger: any AppLogging
    public let modelContainer: ModelContainer
    let preferences: AppPreferences
    /// Bumps when a match is saved or deleted. Play and Force reload from this.
    var sessionRevision = 0

    public init(
        content: any ContentCatalogRepository = BundleContentCatalogRepository(),
        matchSessions: (any MatchSessionRepository)? = nil,
        releaseSurface: any ReleaseSurfaceProviding = ReleaseSurface(),
        logger: any AppLogging = ConsoleAppLogger(),
        modelContainer: ModelContainer? = nil
    ) {
        let container: ModelContainer
        if let modelContainer {
            container = modelContainer
        } else {
            do {
                container = try PersistenceController.makeContainer()
            } catch {
                logger.error("SwiftData store failed; using in-memory. \(error)", category: "persistence")
                do {
                    container = try PersistenceController.makeContainer(inMemory: true)
                } catch {
                    preconditionFailure("SwiftData unavailable even in-memory: \(error)")
                }
            }
        }
        let stored = matchSessions ?? SwiftDataMatchSessionRepository(container: container)
        let revising = SessionRevisionRepository(base: stored)
        self.modelContainer = container
        self.content = content
        self.matchSessions = revising
        self.releaseSurface = releaseSurface
        self.logger = logger
        self.preferences = AppPreferences()
        revising.onMutation = { [weak self] in
            guard let self else { return }
            self.sessionRevision += 1
        }
    }
}

/// Forwards match saves and deletes, then bumps `AppDependencies.sessionRevision`.
@MainActor
private final class SessionRevisionRepository: MatchSessionRepository {
    private let base: any MatchSessionRepository
    var onMutation: (@MainActor () -> Void)?

    init(base: any MatchSessionRepository) {
        self.base = base
    }

    func loadActive(mode: GameModeId) throws -> MatchSession? {
        try base.loadActive(mode: mode)
    }

    func save(_ session: MatchSession) throws {
        try base.save(session)
        onMutation?()
    }

    func delete(id: UUID) throws {
        try base.delete(id: id)
        onMutation?()
    }

    func deleteAll() throws {
        try base.deleteAll()
        onMutation?()
    }
}
