import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'إدارة مدرسة الجوادين',
  description: 'لوحة التحكم الإدارية لمدرسة الجوادين',
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ar" dir="rtl">
      <body>{children}</body>
    </html>
  );
}
