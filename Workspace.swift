import ProjectDescription

let workspace = Workspace(
    name: "Bloomly",
    projects: ["."],
    additionalFiles: [
        "README.md",
        "Docs/**",
        "Packages/**/Package.swift"
    ]
)
