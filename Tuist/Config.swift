import ProjectDescription

let config = Config(
    compatibleXcodeVersions: [.list(["16.0", "16.1", "16.2", "16.3", "16.4"])],
    generationOptions: [
        .automaticSchemes(options: .disabled)
    ]
)
