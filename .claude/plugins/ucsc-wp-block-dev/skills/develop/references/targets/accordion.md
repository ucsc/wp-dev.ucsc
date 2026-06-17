# Accordion Target

Read this reference when the selected target is `accordion`.

## Identity

- **Plugin**: `ucsc-gutenberg-blocks`
- **Dev block name**: `ucscblocks/accordion`
- **Rendered block name**: `ucsc/accordion`

## Rendered-HTML Detection

Dynamic block — strips `<!-- wp: -->` comments from `content.rendered`.
Detect via either fingerprint:

- `ucsc-block-accordion` (class on each `<details>` element)
- `ucsc-accordion-wrapper` (class on the wrapper `<div>`)

The accordion renders as native `<details>` / `<summary>` elements with class
`ucsc-block-accordion`.

## Usage Scale

As of June 2026, the accordion block is used on ~50 sites across ~182 pages.
It is one of the most widely deployed UCSC custom blocks.
