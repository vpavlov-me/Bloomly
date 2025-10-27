import CoreData
import Foundation
import os.log

/// Core Data implementation of BabyRepository
public actor CoreDataBabyRepository: BabyRepository {
    private let context: NSManagedObjectContext
    private let logger = Logger(subsystem: "com.example.babytrack", category: "BabyRepository")

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func create(_ dto: BabyDTO) async throws -> BabyDTO {
        logger.info("Creating baby: \(dto.name)")

        // Validate input
        guard !dto.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BabyRepositoryError.validationFailed(reason: "Baby name cannot be empty")
        }

        guard dto.birthDate <= Date() else {
            throw BabyRepositoryError.validationFailed(reason: "Birth date cannot be in the future")
        }

        return try await context.perform {
            let entity = NSEntityDescription.entity(forEntityName: "Baby", in: self.context)!
            let baby = NSManagedObject(entity: entity, insertInto: self.context)

            baby.setValue(dto.id, forKey: "id")
            baby.setValue(dto.name, forKey: "name")
            baby.setValue(dto.birthDate, forKey: "birthDate")
            baby.setValue(dto.createdAt, forKey: "createdAt")
            baby.setValue(dto.updatedAt, forKey: "updatedAt")

            // Process photo if provided
            if let photoData = dto.photoData {
                do {
                    let processedData = try PhotoProcessor.process(photoData)
                    baby.setValue(processedData, forKey: "photoData")
                } catch {
                    throw BabyRepositoryError.photoProcessingFailed(error)
                }
            }

            do {
                try self.context.save()
                self.logger.info("Baby created successfully: \(dto.id)")
                return self.mapToDTO(baby)
            } catch {
                self.logger.error("Failed to create baby: \(error.localizedDescription)")
                throw BabyRepositoryError.persistence(error)
            }
        }
    }

    public func read(id: UUID) async throws -> BabyDTO {
        logger.debug("Reading baby with id: \(id)")

        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Baby")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            do {
                let results = try self.context.fetch(request)
                guard let baby = results.first else {
                    throw BabyRepositoryError.notFound
                }
                return self.mapToDTO(baby)
            } catch let error as BabyRepositoryError {
                throw error
            } catch {
                throw BabyRepositoryError.persistence(error)
            }
        }
    }

    public func update(_ dto: BabyDTO) async throws -> BabyDTO {
        logger.info("Updating baby: \(dto.id)")

        // Validate input
        guard !dto.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BabyRepositoryError.validationFailed(reason: "Baby name cannot be empty")
        }

        guard dto.birthDate <= Date() else {
            throw BabyRepositoryError.validationFailed(reason: "Birth date cannot be in the future")
        }

        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Baby")
            request.predicate = NSPredicate(format: "id == %@", dto.id as CVarArg)
            request.fetchLimit = 1

            do {
                let results = try self.context.fetch(request)
                guard let baby = results.first else {
                    throw BabyRepositoryError.notFound
                }

                baby.setValue(dto.name, forKey: "name")
                baby.setValue(dto.birthDate, forKey: "birthDate")
                baby.setValue(dto.updatedAt, forKey: "updatedAt")

                // Process photo if provided
                if let photoData = dto.photoData {
                    do {
                        let processedData = try PhotoProcessor.process(photoData)
                        baby.setValue(processedData, forKey: "photoData")
                    } catch {
                        throw BabyRepositoryError.photoProcessingFailed(error)
                    }
                } else {
                    baby.setValue(nil, forKey: "photoData")
                }

                try self.context.save()
                self.logger.info("Baby updated successfully: \(dto.id)")
                return self.mapToDTO(baby)
            } catch let error as BabyRepositoryError {
                throw error
            } catch {
                self.logger.error("Failed to update baby: \(error.localizedDescription)")
                throw BabyRepositoryError.persistence(error)
            }
        }
    }

    public func delete(id: UUID) async throws {
        logger.info("Deleting baby: \(id)")

        try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Baby")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            do {
                let results = try self.context.fetch(request)
                guard let baby = results.first else {
                    throw BabyRepositoryError.notFound
                }

                // Soft delete: mark as deleted (if isDeleted field exists)
                // For now, we'll do hard delete as Baby entity doesn't have isDeleted flag
                self.context.delete(baby)

                try self.context.save()
                self.logger.info("Baby deleted successfully: \(id)")
            } catch let error as BabyRepositoryError {
                throw error
            } catch {
                self.logger.error("Failed to delete baby: \(error.localizedDescription)")
                throw BabyRepositoryError.persistence(error)
            }
        }
    }

    public func fetchAll() async throws -> [BabyDTO] {
        logger.debug("Fetching all babies")

        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Baby")
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

            do {
                let results = try self.context.fetch(request)
                return results.map { self.mapToDTO($0) }
            } catch {
                self.logger.error("Failed to fetch babies: \(error.localizedDescription)")
                throw BabyRepositoryError.persistence(error)
            }
        }
    }

    public func fetchActive() async throws -> BabyDTO? {
        logger.debug("Fetching active baby")

        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Baby")
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            request.fetchLimit = 1

            do {
                let results = try self.context.fetch(request)
                return results.first.map { self.mapToDTO($0) }
            } catch {
                self.logger.error("Failed to fetch active baby: \(error.localizedDescription)")
                throw BabyRepositoryError.persistence(error)
            }
        }
    }

    // MARK: - Private Helpers

    private func mapToDTO(_ object: NSManagedObject) -> BabyDTO {
        BabyDTO(
            id: object.value(forKey: "id") as? UUID ?? UUID(),
            name: object.value(forKey: "name") as? String ?? "",
            birthDate: object.value(forKey: "birthDate") as? Date ?? Date(),
            photoData: object.value(forKey: "photoData") as? Data,
            createdAt: object.value(forKey: "createdAt") as? Date ?? Date(),
            updatedAt: object.value(forKey: "updatedAt") as? Date ?? Date()
        )
    }
}
