# Contributing Skill Ideas

Use this area to suggest or develop skills without changing the plugin's live
`skills/` inventory.

## Lifecycle

1. **Proposal:** Add `proposals/<skill-name>.md` using
   `proposals/TEMPLATE.md`. A proposal may be an idea, a workflow gap, or a
   partial design. It is not loaded as a skill.
2. **Incubator:** A maintainer moves an accepted proposal to
   `incubator/<skill-name>/` using `incubator/TEMPLATE.md` as the starting
   `SKILL.md`. Incubator candidates may include scripts, references, and assets,
   but remain undiscoverable by Claude and Codex.
3. **Promotion:** A maintainer validates the candidate and moves the complete
   skill directory to `skills/<skill-name>/`. Promotion is the point at which
   the candidate becomes part of the supported plugin surface.

Contributors do not edit or merge directly into `skills/`; maintainers own
incubation and promotion. The proposal itself still needs to reach the
repository through the team's normal contribution channel, such as a pull
request or issue-derived patch.

## Proposal Requirements

- Use a lowercase, hyphenated candidate name.
- Describe the problem and give at least two realistic trigger examples.
- Explain why an existing skill cannot absorb the workflow cleanly.
- Identify likely scripts, references, assets, or external tools.
- Avoid credentials, production data, generated output, and copied proprietary
  documentation.

## Incubator Requirements

- Keep the directory name and frontmatter `name` identical.
- Treat the candidate as experimental and unavailable to normal routing.
- Follow the same frontmatter and support-file rules as production skills.
- Add focused tests when the candidate introduces deterministic behavior.
- Record unresolved questions in the candidate's `SKILL.md`; do not add an
  auxiliary README.

## Maintainer Commands

- `maintainer review-contrib <candidate>` reviews a proposal or incubator
  candidate and reports `reject`, `revise`, `incubate`, or `promote`.
- `maintainer promote-contrib <candidate>` performs the final checks and moves
  an incubator candidate into `skills/`.
- `maintainer all` validates production skills only. Contribution candidates
  are reviewed explicitly because they may be intentionally incomplete.

