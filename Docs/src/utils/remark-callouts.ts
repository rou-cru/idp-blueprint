import { visit } from 'unist-util-visit';
import type { Root } from 'mdast';
import type { ContainerDirective } from 'mdast-util-directive';

/**
 * Remark plugin to transform callouts (:::tip, :::note, etc.)
 * into our custom Callout components
 */
export function remarkCallouts() {
  return (tree: Root) => {
    visit(tree, 'containerDirective', (node: ContainerDirective) => {
      // Check if this is a callout directive
      const validTypes = ['tip', 'caution', 'danger', 'note', 'warning', 'info'];

      if (!validTypes.includes(node.name)) {
        return;
      }

      // Extract title from attributes if provided
      const title = node.attributes?.title;

      // Transform to JSX
      const data = node.data || (node.data = {});
      const tagName = 'Callout';

      data.hName = tagName;
      data.hProperties = {
        type: node.name,
        ...(title && { title }),
      };
    });
  };
}
