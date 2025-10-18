import ProjectDescription

let workspace = Workspace(
    name: "BabyTrack",
    projects: ["."],
    additionalFiles: [
        "README.md",
        "Docs/**",
        "Packages/**/Package.swift"
    ]
)
