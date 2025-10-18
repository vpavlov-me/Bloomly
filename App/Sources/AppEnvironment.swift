//
//  AppEnvironment.swift
//  BabyTrack
//
//  Provides dependency container wiring repositories and services.
//

import Foundation
import Tracking
import Measurements
import Sync
import Paywall

@MainActor
final class AppEnvironment: ObservableObject {
    let persistenceController: PersistenceController
    let eventsRepository: EventsRepository
    let measurementsRepository: MeasurementsRepository
    let growthService: GrowthChartingService
    let storeClient: StoreClient
    let syncService: SyncService

    init(
        persistenceController: PersistenceController = .shared,
        eventsRepository: EventsRepository? = nil,
        measurementsRepository: MeasurementsRepository? = nil,
        growthService: GrowthChartingService? = nil,
        storeClient: StoreClient? = nil,
        syncService: SyncService? = nil
    ) {
        self.persistenceController = persistenceController
        let context = persistenceController.container.viewContext
        self.eventsRepository = eventsRepository ?? CoreDataEventsRepository(context: context)
        self.measurementsRepository = measurementsRepository ?? CoreDataMeasurementsRepository(context: context)
        self.growthService = growthService ?? WHOChartingService()
        self.storeClient = storeClient ?? StoreKitStoreClient()
        self.syncService = syncService ?? CloudKitSyncService(mapper: DefaultRecordMapper(), tracker: CoreDataChangeTracker(context: context))
    }
}
