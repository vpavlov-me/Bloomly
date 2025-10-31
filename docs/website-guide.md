# Website Guide

## Overview
- Public marketing microsite lives in `docs/index.html` and is published through GitHub Pages.
- The `website` branch is configured with the `docs/` directory as the Pages source; pushing to that branch updates the live site.
- Stack is plain HTML/CSS with inline styles, Google Fonts, and no build tooling, so any browser can preview it directly.

## Local preview
- Prerequisite: Python 3 (bundled with the project toolchain) or another static file server.
- Steps:
  1. `cd docs`
  2. `python3 -m http.server 4100`
  3. Open `http://localhost:4100` and verify layout on desktop and mobile breakpoints.
- Close the server with `Ctrl+C` when finished.

## Editing workflow
- Duplicate the `website` branch locally (`git fetch origin website && git switch website`) before making changes.
- Update `docs/index.html`; keep sections and class names consistent to avoid breaking existing styling.
- Use semantic HTML, keep assets under `docs/`, and compress images before committing.
- After edits, re-run the local preview and check contrast/accessibility (e.g., using browser devtools).

## Deploying changes
- Push a feature branch to origin and open a PR targeting `website` to keep marketing changes isolated from app code.
- Once merged, GitHub Pages picks up the update automatically (allow a few minutes for propagation).
- Verify the production site under the repository’s GitHub Pages URL after each deployment.

## Maintenance tips
- Validate external links (App Store, GitHub) when releasing new builds.
- Monitor Google Fonts usage; if privacy is a concern, consider self-hosting the font files inside `docs/`.
- Keep testimonials and pricing details synced with actual product features to avoid mismatched promises.
