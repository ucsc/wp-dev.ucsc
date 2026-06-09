# Block Implementation Templates

Canonical skeletons for ucsc-gutenberg-blocks. Replace `BlockName` / `block-name` / `exampleAttr` throughout.

All paths relative to `public/wp-content/plugins/ucsc-gutenberg-blocks/`.

## PHP Class — `classes/BlockName.php`

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

Rules:
- One class per block.
- Constructor hooks into `init` via `add_action` — never register blocks directly in the constructor.
- Block namespace is `ucscblocks/*` (not `ucsc/*`).
- `editor_script` references the shared `ucscblocks` handle enqueued in `index.php`.
- `theHTML()` validates attributes, then delegates to a template.
- Escape all output. Never echo unescaped user or API data.

## PHP Template — `templates/block-name.php`

```php
<?php
// Variables set before require: $example, $data
?>
<div class="wp-block-ucscblocks-block-name">
    <?php echo esc_html($example); ?>
</div>
```

Keep logic minimal — compute values in the render method, pass as local variables via `require`.

## Block JS — `src/blocks/BlockName.js`

The module must export a function; `src/index.js` calls it to register.

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

Rules:
- Use `wp.blocks.registerBlockType` (global), not an ES import.
- Block namespace is `ucscblocks/*`.
- Category is `common` (existing convention).
- Module exports a function; `src/index.js` imports and calls it.

## Registration — `src/index.js`

```js
import BlockName from './blocks/BlockName';

// alongside existing calls:
BlockName();
```

## Registration — `index.php`

```php
require_once plugin_dir_path(__FILE__) . 'classes/BlockName.php';
new BlockName();
```

Place next to the other block registrations.

## REST API addition (if the block needs its own endpoint)

Add to the PHP class:

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
