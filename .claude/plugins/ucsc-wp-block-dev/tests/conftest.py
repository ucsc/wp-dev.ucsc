"""Shared fixtures for ucsc-wp-block-dev plugin tests."""

import pytest
from pathlib import Path


@pytest.fixture()
def blocks_tree(tmp_path):
    """Minimal ucsc-gutenberg-blocks project tree for path-based assertions."""
    plugin = tmp_path / "public" / "wp-content" / "plugins" / "ucsc-gutenberg-blocks"
    plugin.mkdir(parents=True)

    (plugin / "index.php").write_text(
        "<?php\n/**\n * Plugin Name: UCSC Gutenberg Blocks\n */\n"
        "require_once plugin_dir_path(__FILE__) . 'classes/Accordion.php';\n"
        "new Accordion();\n"
    )

    src = plugin / "src"
    src.mkdir()
    (src / "index.js").write_text(
        "import './blocks/Accordion';\n"
    )

    blocks = src / "blocks"
    blocks.mkdir()
    (blocks / "Accordion.js").write_text(
        "import { registerBlockType } from '@wordpress/blocks';\n"
        "registerBlockType('ucsc/accordion', { title: 'Accordion', edit() {}, save() { return null; } });\n"
    )

    tests_dir = blocks / "__tests__"
    tests_dir.mkdir()
    (tests_dir / "Accordion.test.js").write_text(
        "import { registerBlockType } from '@wordpress/blocks';\n"
        "test('registers accordion block', () => { expect(true).toBe(true); });\n"
    )

    classes = plugin / "classes"
    classes.mkdir()
    (classes / "Accordion.php").write_text(
        "<?php\nclass Accordion {\n"
        "    public function __construct() {\n"
        "        register_block_type('ucsc/accordion', ['render_callback' => [$this, 'render']]);\n"
        "    }\n"
        "    public function render($attrs) { return '<div>accordion</div>'; }\n"
        "}\n"
    )

    templates = plugin / "templates"
    templates.mkdir()
    (templates / "accordion.php").write_text(
        "<?php\n?><div class=\"wp-block-ucsc-accordion\"><?php echo esc_html($title); ?></div>\n"
    )

    (plugin / "package.json").write_text(
        '{"name":"ucsc-gutenberg-blocks","scripts":{"build":"wp-scripts build","start":"wp-scripts start","test":"jest"},'
        '"devDependencies":{"@wordpress/scripts":"^22.3.0"}}\n'
    )

    build = plugin / "build"
    build.mkdir()
    (build / "index.js").write_text("/* built */")
    (build / "index.asset.php").write_text("<?php return ['dependencies' => [], 'version' => '1.0'];")

    return tmp_path
