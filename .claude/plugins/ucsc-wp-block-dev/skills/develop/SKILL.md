---
name: develop
description: Add a Gutenberg block or feature to the ucsc-gutenberg-blocks plugin. Before investigating or implementing, require the target block, GUI, or app and a plain-language feature description; prefer but do not require a Jira ID.
---

# Develop — Add a Block or Feature

Guided flow for adding a new Gutenberg block or extending an existing one in `ucsc-gutenberg-blocks`.

Primarily touches `classes/` and `src/blocks/`.

All paths relative to `public/wp-content/plugins/ucsc-gutenberg-blocks/`.

## Universal Command Intake

Apply ADR-011: resolve the target, natural-language feature request, and
optional Jira key/URL from the full input and session context, regardless of
order. Preserve explicit user instructions and ask one concise question only
when missing or conflicting information blocks the workflow.

When Jira, Confluence, pasted ticket details, or issue normalization applies,
read [`references/issue-context.md`](references/issue-context.md) and merge its
compact implementation brief into this workflow.

Before using tools, require the user to choose a target. Resolve known slugs and
aliases through
[`references/targets/index.md`](references/targets/index.md), then read only the
selected target reference. Do not load all target references.

Target references:

- [`references/targets/campus-directory.md`](references/targets/campus-directory.md)
- [`references/targets/class-schedule.md`](references/targets/class-schedule.md)
- [`references/targets/course-catalog.md`](references/targets/course-catalog.md)

Domain references:

- [`references/domain/blocks.md`](references/domain/blocks.md)
- [`references/domain/references/blocks-reference.md`](references/domain/references/blocks-reference.md)
- [`references/domain/references/stack-profile.md`](references/domain/references/stack-profile.md)

## 1. Secure the Target and Feature Description

Before using tools, investigating, or writing code, obtain both required inputs from the user:

1. **Target** — the block, GUI, or app being worked on.
2. **Feature description** — what should be added or changed. A plain-language description is sufficient.

If either input is missing, ask one concise question for all missing inputs and wait for the answer. Request a Jira ID in the same clarification when none was supplied, but Jira is preferred, not required. See ADR-008 and ADR-009.

For an unlisted target, confirm its canonical slug and scope before proceeding.
Add a target reference only when the resulting domain guidance will be reused.

After the required intake is complete, clarify implementation details as needed:

- **Render model** — dynamic (PHP render callback, server-rendered HTML) or static (editor `save()` returns JSX)?
- **Data source** — static content, REST API, LDAP, PeopleSoft, or none?
- **Editor controls** — what attributes does the editor need? (text, URL, toggle, select, etc.)

Default to dynamic blocks with PHP render callbacks unless the block has no server-side data needs.

## 2. Find the Nearest Existing Block

Before writing from scratch, find the existing block that most closely resembles the new one:

```bash
ls classes/
ls src/blocks/
```

Read the nearest match — PHP class and JS file. Use its patterns for class structure, REST registration, transient caching, and block registration. Do not invent new patterns.

## 3. PHP Class

Create `classes/<BlockName>.php`:

```php
<?php

class BlockName {
    public function __construct() {
        add_action('init', array($this, 'adminAssets'));
    }

    public function adminAssets() {
        register_block_type('ucscblocks/block-name', array(
            'editor_script' => 'ucscblocks',
            'render_callback' => array($this, 'theHTML'),
        ));
    }

    public function theHTML($attributes) {
        $example = esc_html($attributes['exampleAttr'] ?? '');
        ob_start();
        require plugin_dir_path(__FILE__) . '../templates/block-name.php';
        return ob_get_clean();
    }
}
```

- One class per block.
- Constructor hooks into `init` via `add_action` — never register blocks directly in the constructor.
- Block namespace is `ucscblocks/*` (not `ucsc/*`).
- `editor_script` references the shared `ucscblocks` handle enqueued in `index.php`.
- `theHTML()` validates attributes, then delegates to a template.
- Escape all output. Never echo unescaped user or API data.

## 4. Template

Create `templates/block-name.php` for substantial markup:

```php
<?php
// Variables set before require: $example, $data
?>
<div class="wp-block-ucscblocks-block-name">
    <?php echo esc_html($example); ?>
</div>
```

Keep logic minimal in templates — compute values in the render method, pass as local variables.

## 5. Block JS (editor side)

Create `src/blocks/BlockName.js`. The module must export a function — `src/index.js` calls it to register:

```js
import { InspectorControls } from '@wordpress/block-editor';
import { Panel, PanelBody, TextControl } from '@wordpress/components';

const BlockName = () => {
    wp.blocks.registerBlockType('ucscblocks/block-name', {
        title: 'Block Name',
        icon: 'admin-generic',
        category: 'common',
        attributes: {
            exampleAttr: { type: 'string', default: '' },
        },
        edit: ({ attributes, setAttributes }) => {
            return (
                <>
                    <InspectorControls key="setting">
                        <Panel>
                            <PanelBody title="Settings">
                                <TextControl
                                    label="Example"
                                    value={attributes.exampleAttr}
                                    onChange={(val) => setAttributes({ exampleAttr: val })}
                                />
                            </PanelBody>
                        </Panel>
                    </InspectorControls>
                    <div>Block preview</div>
                </>
            );
        },
        save: () => {
            return null;
        },
    });
};

export default BlockName;
```

- Uses `wp.blocks.registerBlockType` (global), not an ES import of `registerBlockType`.
- Block namespace is `ucscblocks/*`.
- Category is `common` (existing convention).
- Module exports a function; `src/index.js` imports and calls it.

## 6. Register in index.js

Add an import and call to `src/index.js`:

```js
import BlockName from './blocks/BlockName';

// ... alongside existing calls:
BlockName();
```

## 7. Register in index.php

Add require and instantiation to `index.php`:

```php
require_once plugin_dir_path(__FILE__) . 'classes/BlockName.php';
new BlockName();
```

Place next to the other block registrations.

## 8. REST API (if needed)

If the block needs its own endpoint, add a method to the PHP class:

```php
public function __construct() {
    add_action('init', array($this, 'adminAssets'));
    add_action('rest_api_init', array($this, 'register_routes'));
}

public function register_routes() {
    register_rest_route('ucsc/v1', '/block-name/data', [
        'methods' => 'GET',
        'callback' => [$this, 'get_data'],
        'permission_callback' => '__return_true',
    ]);
}

public function get_data($request) {
    $cached = get_transient('ucsc_block_name_data');
    if ($cached !== false) return $cached;
    // fetch ...
    set_transient('ucsc_block_name_data', $data, HOUR_IN_SECONDS);
    return $data;
}
```

## 9. Validate

```bash
npm run build        # must complete without errors
```

Note: the plugin does not currently have a `test` script in `package.json`. If Jest tests are added in the future, run `npm test` and write tests in `src/blocks/__tests__/BlockName.test.js`.

## 10. Complete the Feature Phase

After implementing, remind the user that this change needs build verification
in the Docker environment with the `run` skill before it is treated as ready.

If applicable validation is complete and no Jira ID was captured, the completion summary may ask for it again. Do not repeat the prompt when an ID is already known, and do not treat a missing ID as incomplete work. See ADR-010.

Per ADR-029, offer to generate a Conventional Commit message for the completed feature. Generate message text only if the user accepts. Do not run `git add`, `git commit`, `git push`, or equivalent staging, commit, or push operations.

## Plugin-dev Tools

When this workflow creates or modifies plugin components (skills, manifest, hooks), use the following tools:

- **`plugin-dev:plugin-validator`** — validate plugin structure, manifest, and naming via `Agent` with `subagent_type: "plugin-dev:plugin-validator"`.
- **`plugin-dev:skill-reviewer`** — review skill quality and description effectiveness via `Agent` with `subagent_type: "plugin-dev:skill-reviewer"`.
- **`plugin-dev:skill-development`** — guidance on skill structure and frontmatter via `Skill` with `skill: "plugin-dev:skill-development"`.
