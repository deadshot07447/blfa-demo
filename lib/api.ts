export interface Post {
  id: string;
  title: string;
  slug: string;
  date: string;
  excerpt: string;
  content: string;
}

export function getGraphQLUrl(): string {
  if (typeof window === 'undefined') {
    return (
      process.env.WORDPRESS_INTERNAL_API_URL ||
      process.env.NEXT_PUBLIC_WORDPRESS_API_URL ||
      'http://localhost:9000/graphql'
    );
  }
  return process.env.NEXT_PUBLIC_WORDPRESS_API_URL || 'http://localhost:9000/graphql';
}

export async function fetchGraphQL<T>(
  query: string,
  variables: Record<string, unknown> = {}
): Promise<{ data: T | null; error: string | null }> {
  const url = getGraphQLUrl();

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query, variables }),
      next: { revalidate: 60 },
    });

    if (!res.ok) {
      return {
        data: null,
        error: `Backend responded with HTTP status ${res.status} (${res.statusText})`,
      };
    }

    const json = await res.json();
    if (json.errors && json.errors.length > 0) {
      return {
        data: null,
        error: json.errors.map((e: { message: string }) => e.message).join(', '),
      };
    }

    return { data: json.data as T, error: null };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Unknown network error';
    return {
      data: null,
      error: `Could not connect to WordPress backend at ${url}. Please verify that the backend is running. (${msg})`,
    };
  }
}

export async function getAllPosts(): Promise<{ posts: Post[]; error: string | null }> {
  const query = `
    query GetAllPosts {
      posts(first: 20, where: { orderby: { field: DATE, order: DESC } }) {
        nodes {
          id
          title
          slug
          date
          excerpt
        }
      }
    }
  `;

  const { data, error } = await fetchGraphQL<{ posts?: { nodes: Post[] } }>(query);
  if (error || !data?.posts?.nodes) {
    return { posts: [], error };
  }

  return { posts: data.posts.nodes, error: null };
}

export async function getPostBySlug(
  slug: string
): Promise<{ post: Post | null; error: string | null }> {
  const query = `
    query GetPostBySlug($id: ID!) {
      post(id: $id, idType: SLUG) {
        id
        title
        slug
        date
        excerpt
        content
      }
    }
  `;

  const { data, error } = await fetchGraphQL<{ post?: Post | null }>(query, { id: slug });
  if (error) {
    return { post: null, error };
  }

  return { post: data?.post || null, error: null };
}