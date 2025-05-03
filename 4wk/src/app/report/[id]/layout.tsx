// This is a server component
import { ReactNode } from "react";

// This function informs Next.js which paths to pre-generate at build time
export async function generateStaticParams() {
  // Return an array of params to pre-render
  // For now we'll include a placeholder parameter
  // In a real application, you'd fetch all report IDs from your database
  return [
    { id: "placeholder" },
    // Add more IDs as needed
  ];
}

export default function ReportLayout({ children }: { children: ReactNode }) {
  return <>{children}</>;
}
