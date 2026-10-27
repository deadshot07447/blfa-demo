import sanitizeHtml from 'sanitize-html';

export function cleanHtml(dirty: string): string {
  if (!dirty) return '';
  return sanitizeHtml(dirty, {
    allowedTags: [
      'p', 'b', 'i', 'em', 'strong', 'a', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
      'ul', 'ol', 'li', 'blockquote', 'code', 'pre', 'br', 'hr', 'span'
    ],
    allowedAttributes: {
      a: ['href', 'title', 'target', 'rel'],
      span: ['class'],
    },
    allowedSchemes: ['http', 'https', 'mailto'],
  });
}