import type { Metadata } from 'next';
import Link from 'next/link';
import './globals.css';

export const metadata: Metadata = {
  title: 'BLFA Demo - Headless WordPress & Next.js',
  description: 'Minimal headless WordPress Next.js demo using WPGraphQL',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <header>
          <div className="header-inner">
            <Link href="/" className="site-title">
              blfa-demo
            </Link>
          </div>
        </header>
        <main>{children}</main>
        <footer>
          <p>&copy; 2026 blfa-demo. Minimal headless WordPress &amp; Next.js showcase.</p>
        </footer>
      </body>
    </html>
  );
}