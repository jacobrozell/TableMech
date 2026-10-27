import Foundation
import Observation
import SwiftData
import TableMechData

@Observable
@MainActor
public final class AppDependencies {
    public let content: any ContentCatalogRepository
    public let matchSessions: any MatchSessionRepository
    public let releaseSurface: any ReleaseSurfaceProviding
    public let logger: any AppLogging
    public let modelContainer: ModelContainer

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
        self.modelContainer = container
        self.content = content
        self.matchSessions = matchSessions ?? SwiftDataMatchSessionRepository(container: container)
        self.releaseSurface = releaseSurface
        self.logger = logger
    }
}
