# Consolidating (merging) ADRs

Prefer one ADR per skill/theme over a stream of tiny decision files (ADR-086).
Merge a cluster into a survivor ADR in this order — the deterministic steps are
scripted by [`../scripts/retire-adr.sh`](../scripts/retire-adr.sh); the judgment
steps stay manual.

1. **Map the scope.** List every reference to each absorbed number first, so the
   repointing is known up front:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/retire-adr.sh" refs <NNN> [NNN...]
   ```

2. **Fold content** into the survivor: keep the **lowest** number as the survivor,
   broaden its title, add a "consolidates ADR-NNN" note and the absorbed decisions.

3. **Retire** the absorbed ADRs (moves to `retired/`, flips status, drops index
   rows, adds sorted `adrs_retired.md` rows):

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/maintainer/scripts/retire-adr.sh" retire <NNN> [NNN...]
   ```

4. **Repoint** every `implements:` marker and prose reference from the absorbed
   numbers to the survivor. Markers are deterministic (remove the absorbed marker,
   keep/extend the survivor's); prose needs a human eye. In a `SKILL.md`
   `implements:` line, **delete** the absorbed marker rather than converting it
   when the survivor's marker is already present (avoid a duplicate).

5. **Verify zero dangling refs** — rerun `retire-adr.sh refs <NNN...>`. The only
   hits left should be the survivor's intentional "consolidates ADR-NNN" notes.

6. **Run the gates:** `check-adr-implements.py`, then `run-all-plugin-tests.sh`.
   Watch the maintainer SKILL.md token budget (<10k on-invoke, ADR-003) —
   put new long-form guidance in a reference like this one, not in `SKILL.md`.

## Methodology (sample → retro → enrich)

Consolidation is built up incrementally: do an early small merge, run a
retrospective that enriches the scripts/skills, do another, then a bigger batch.
`retire-adr.sh` is the first deterministic component; the goal is a fuller
`combine-adrs` orchestrator (it would script steps 3–4's deterministic parts and
emit the manual checklist). See the worklist for the running plan.

## Retiring a single ADR

When an ADR becomes Superseded, Deprecated, or Rejected, move it out of the
active set: set its `status:`, move the file to `docs/adr/retired/`, remove its
row from `docs/adr/index.md`, and add a one-line entry to
`docs/adr/adrs_retired.md` (linking into `retired/`). Active ADRs keep only
active decisions; the `test_adr_retired.py` contract enforces this split.
`new-adr.sh` scans `retired/` when allocating numbers, so retired numbers are
never reused.

Use the [`retire-adr.sh`](../scripts/retire-adr.sh) helper (subcommands `refs`
and `retire`) for the deterministic parts instead of hand-editing those four
files.

## History

- **Sample 1 (2026-06-24):** merged the adr-mode naming-convention ADR into
  ADR-065 (adr mode: creation script + naming convention). Proved the retire +
  repoint + grep-verify loop; produced `retire-adr.sh`.
- **Sample 2 (2026-06-24):** merged the low-token single-agent ADR into ADR-003
  (low token use and single-agent default); 7 prose refs repointed across
  five sibling ADRs + hub. **Found and fixed a `retire-adr.sh` bug:** the
  retire one-liner `open(src,'w').write(open(src).read()…)` truncated the file
  before the inline read ran, leaving an **empty** retired ADR. Fixed to read
  into a variable first and skip empty sources. Lesson: never read and truncate
  the same path in one expression; the first sample missed it because it used a
  read-then-write variable form.
