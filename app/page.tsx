import Link from 'next/link';
import { getAllPosts } from '@/lib/api';
import { cleanHtml } from '@/lib/sanitize';

export const dynamic = 'force-dynamic';

export default async function HomePage() {
  const { posts, error } = await getAllPosts();

  return (
    <div>
      <h1>Latest Posts</h1>

      {error && (
        <div className="notice notice-error" role="alert">
          <p><strong>Notice:</strong> Unable to connect to the backend service.</p>
          <p>{error}</p>
        </div>
      )}

      {!error && posts.length === 0 && (
        <div className="notice">
          <p>No posts available at this time.</p>
        </div>
      )}

      {posts.length > 0 && (
        <ul className="post-list">
          {posts.map((post) => {
            const formattedDate = post.date
              ? new Date(post.date).toLocaleDateString('en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                })
              : '';

            return (
              <li key={post.id} className="post-item">
                <h2 className="post-title">
                  <Link href={`/posts/${post.slug}`}>{post.title}</Link>
                </h2>
                {formattedDate && <p className="post-date">{formattedDate}</p>}
                {post.excerpt && (
                  <div
                    className="post-excerpt"
                    dangerouslySetInnerHTML={{ __html: cleanHtml(post.excerpt) }}
                  />
                )}
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}