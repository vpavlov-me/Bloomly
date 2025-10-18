# CloudKit Setup

1. Enable the **iCloud** capability with CloudKit in the BabyTrack app target and watch extension.
2. Create the container `iCloud.com.example.BabyTrack` in the Apple Developer portal.
3. In CloudKit Dashboard:
   - Deploy the schema to the development environment.
   - Create record types `Event` and `Measurement`.
   - Add fields `id (String)`, `payload (Bytes)`, `updatedAt (Date)`.
4. Update entitlements if bundle identifiers change.
5. For production rollout, promote the schema from development to production and monitor metrics.
