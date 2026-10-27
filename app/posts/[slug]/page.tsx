import type { Metadata } from 'next';
import Link from 'next/link';
import { getPostBySlug } from '@/lib/api';
import { cleanHtml } from '@/lib/sanitize';

export const revalidate = 60;

interface PostPageProps {
  params: {
    slug: string;
  };
}

export async function generateMetadata({ params }: PostPageProps): Promise<Metadata> {
  const { post } = await getPostBySlug(params.slug);
  if (!post) {
    return {
      title: 'Post Not Found - blfa-demo',
    };
  }
  return {
    title: `${post.title} - blfa-demo`,
  };
}

export default async function PostPage({ params }: PostPageProps) {
  const { post, error } = await getPostBySlug(params.slug);

  return (
    <article>
      <Link href="/" className="back-link">
        &larr; Back to all posts
      </Link>

      {error && (
        <div className="notice notice-error" role="alert">
          <p><strong>Notice:</strong> Unable to retrieve post content.</p>
          <p>{error}</p>
        </div>
      )}

      {!error && !post && (
        <div className="notice">
          <h2>Post Not Found</h2>
          <p>The requested post could not be found. It may have been removed or the slug is incorrect.</p>
        </div>
      )}

      {post && (
        <div>
          <h1>{post.title}</h1>
          {post.date && (
            <p className="post-date">
              {new Date(post.date).toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
              })}
            </p>
          )}
          <div
            className="post-content"
            dangerouslySetInnerHTML={{ __html: cleanHtml(post.content || post.excerpt) }}
          />
        </div>
      )}
    </article>
  );
}