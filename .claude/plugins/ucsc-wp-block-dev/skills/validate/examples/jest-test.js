/**
 * Jest test template for a ucsc-gutenberg-blocks dynamic block.
 *
 * Location: src/blocks/__tests__/BlockName.test.js
 * Run in-container: npm run test -- --testPathPattern=BlockName
 *
 * Key constraints (from CLAUDE.md):
 * - @wordpress/* packages are NOT installed; mock them with { virtual: true }
 * - Child components (dropdowns, layouts) must also be mocked
 * - Use @testing-library/react + jest-dom
 */

import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';

// Mock WordPress packages — virtual: true because they are not installed
jest.mock('@wordpress/blocks', () => ({
  registerBlockType: jest.fn(),
}), { virtual: true });

jest.mock('@wordpress/components', () => ({
  PanelBody: ({ children, title }) => (
    <div data-testid="panel-body" data-title={title}>{children}</div>
  ),
  TextControl: ({ label, value, onChange }) => (
    <input aria-label={label} value={value} onChange={(e) => onChange(e.target.value)} />
  ),
}), { virtual: true });

jest.mock('@wordpress/block-editor', () => ({
  useBlockProps: () => ({}),
  InspectorControls: ({ children }) => <div>{children}</div>,
}), { virtual: true });

// Mock child components unique to this block
jest.mock('../../components/MyDropdown', () => ({ label, disabled }) => (
  <div data-testid="my-dropdown" data-label={label} data-disabled={String(disabled)} />
));

// Capture the registered block config
let registeredBlock = null;
global.wp = {
  blocks: {
    registerBlockType: (name, config) => {
      registeredBlock = { name, ...config };
    },
  },
};

// Import after mocks are set up
const MyBlock = require('../MyBlock').default;

describe('MyBlock', () => {
  beforeEach(() => {
    registeredBlock = null;
    MyBlock(); // trigger registerBlockType
  });

  it('registers with the correct block name', () => {
    expect(registeredBlock.name).toBe('ucscblocks/myblock');
  });

  it('edit component renders the inspector control', () => {
    const { Edit } = registeredBlock;
    const attrs = { title: 'Hello', showFilter: true };
    render(<Edit attributes={attrs} setAttributes={jest.fn()} />);
    expect(screen.getByTestId('panel-body')).toBeInTheDocument();
  });

  it('save returns null (dynamic block — rendered server-side)', () => {
    expect(registeredBlock.save()).toBeNull();
  });

  it('renders the dropdown in enabled state by default', () => {
    const { Edit } = registeredBlock;
    render(<Edit attributes={{ showFilter: true }} setAttributes={jest.fn()} />);
    expect(screen.getByTestId('my-dropdown')).toHaveAttribute('data-disabled', 'false');
  });
});
