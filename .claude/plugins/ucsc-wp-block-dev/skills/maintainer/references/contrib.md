# Contributed-skill review and promotion

implements: ADR-038-MAINTAINER-CONTRIB

Full checklists for the maintainer `review-contrib` and `promote-contrib` modes
(reached as `skill review-contrib <candidate>` and `skill promote <candidate>`).
The `## review-contrib` / `## promote-contrib` sections in `SKILL.md` are the
lean dispatch stubs; this file is the operational detail. Read
`contrib/README.md` before reviewing or promoting.

## review-contrib

Review a proposal under `contrib/proposals/` or a candidate under
`contrib/incubator/`. Require the candidate name when it is not clear from the
request.

For a proposal:

1. Check that it follows `contrib/proposals/TEMPLATE.md`.
2. Compare its triggers and workflow with existing production skills.
3. Check that the scope is specific to UCSC WordPress block development.
4. Return one decision: `reject`, `revise`, or `incubate`, with concise reasons.
5. For `incubate`, create `contrib/incubator/<skill-name>/SKILL.md` from
   `contrib/incubator/TEMPLATE.md`, carrying forward the accepted proposal
   details. Keep the original proposal until promotion for review history.

For an incubator candidate:

1. Apply the `skill-development` guidance.
2. Check trigger clarity, workflow completeness, overlap, security, support-file
   references, tests, and realistic examples.
3. Return one decision: `revise` or `promote`, with remaining work listed.

Do not place a candidate under `skills/` during review.

## promote-contrib

Promote a named directory from `contrib/incubator/<skill-name>/` into
`skills/<skill-name>/`. Read `contrib/README.md` and apply the
`skill-development` guidance first.

Before moving files:

1. Confirm no production skill has the same name or substantially overlapping
   triggers.
2. Confirm the directory name matches the frontmatter `name`.
3. Confirm the description clearly states behavior and trigger context.
4. Confirm every support file is linked from `SKILL.md`.
5. Run focused candidate tests or examples.

After moving files:

1. Update `README.md`, `AGENTS.md`, the `hub` skill, and the maintainer slide
   deck when the new skill changes those inventories.
2. Add or update structural tests for the supported skill surface.
3. Run `self-test`, `validate`, `check-references`, and `review-skills`.
4. Remove the corresponding proposal only after the promotion checks pass.

If any check fails, leave the candidate in `contrib/incubator/` and report the
required revisions.
