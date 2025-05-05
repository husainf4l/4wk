"use client";

import { ReactNode, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { onAuthChange, signOut } from "@/services/auth.service";

interface User {
  uid: string;
  email: string | null;
  displayName?: string | null;
}

interface AppLayoutProps {
  children: ReactNode;
  requireAuth?: boolean;
}

export default function AppLayout({
  children,
  requireAuth = true,
}: AppLayoutProps) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const unsubscribe = onAuthChange((currentUser) => {
      if (currentUser) {
        setUser({
          uid: currentUser.uid,
          email: currentUser.email,
          displayName: currentUser.displayName,
        });
      } else {
        setUser(null);
        if (requireAuth) {
          router.push("/login");
        }
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, [router, requireAuth]);

  const handleSignOut = async () => {
    try {
      await signOut();
      router.push("/login");
    } catch (error) {
      console.error("Error signing out:", error);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-neutral-900 flex items-center justify-center">
        <div className="flex flex-col items-center">
          <div className="w-12 h-12 border-4 border-neutral-700 border-t-red-600 rounded-full animate-spin"></div>
          <p className="mt-4 text-white font-medium">Loading...</p>
        </div>
      </div>
    );
  }

  if (requireAuth && !user) {
    return null; // Auth check will redirect to login
  }

  return (
    <div className="min-h-screen bg-neutral-900 flex flex-col">
      {/* Header/Nav */}
      <header className="bg-black py-4 px-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/dashboard">
            <Image
              src="/4wk.png"
              alt="4WK Logo"
              width={192}
              height={24}
              quality={100}
              className="rounded-md cursor-pointer"
            />
          </Link>
        </div>

        <div className="flex items-center gap-4">
          {user && (
            <>
              <span className="text-neutral-400 text-sm hidden sm:inline-block">
                {user.email}
              </span>
              <button
                onClick={handleSignOut}
                className="text-white bg-neutral-800 hover:bg-neutral-700 px-4 py-2 rounded-md text-sm transition-colors"
              >
                Sign Out
              </button>
            </>
          )}
        </div>
      </header>

      {/* Main Content */}
      <div className="flex flex-col md:flex-row flex-1">
        {/* Sidebar - Only show when user is logged in */}
        {user && (
          <aside className="w-full md:w-64 bg-neutral-800 border-r border-neutral-700">
            <nav className="p-4">
              <div className="px-4 py-3 text-xs font-semibold text-neutral-500 uppercase tracking-wider">
                Main
              </div>
              <div className="space-y-1">
                <Link
                  href="/dashboard"
                  className={`flex items-center px-4 py-3 rounded-md group ${
                    window.location.pathname === "/dashboard"
                      ? "text-white bg-neutral-700"
                      : "text-neutral-300 hover:bg-neutral-700 hover:text-white"
                  }`}
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-5 w-5 mr-3 text-neutral-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
                    />
                  </svg>
                  Dashboard
                </Link>
                <Link
                  href="/report"
                  className={`flex items-center px-4 py-3 rounded-md group ${
                    window.location.pathname.startsWith("/report")
                      ? "text-white bg-neutral-700"
                      : "text-neutral-300 hover:bg-neutral-700 hover:text-white"
                  }`}
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-5 w-5 mr-3 text-neutral-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                    />
                  </svg>
                  Reports
                </Link>
              </div>

              <div className="mt-8 px-4 py-3 text-xs font-semibold text-neutral-500 uppercase tracking-wider">
                Management
              </div>
              <div className="space-y-1">
                <Link
                  href="/clients"
                  className={`flex items-center px-4 py-3 rounded-md group ${
                    window.location.pathname.startsWith("/clients")
                      ? "text-white bg-neutral-700"
                      : "text-neutral-300 hover:bg-neutral-700 hover:text-white"
                  }`}
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-5 w-5 mr-3 text-neutral-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
                    />
                  </svg>
                  Clients
                </Link>
                <Link
                  href="/garages"
                  className={`flex items-center px-4 py-3 rounded-md group ${
                    window.location.pathname.startsWith("/garages")
                      ? "text-white bg-neutral-700"
                      : "text-neutral-300 hover:bg-neutral-700 hover:text-white"
                  }`}
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-5 w-5 mr-3 text-neutral-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                    />
                  </svg>
                  Garages
                </Link>
                <Link
                  href="/vehicles"
                  className={`flex items-center px-4 py-3 rounded-md group ${
                    window.location.pathname.startsWith("/vehicles")
                      ? "text-white bg-neutral-700"
                      : "text-neutral-300 hover:bg-neutral-700 hover:text-white"
                  }`}
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-5 w-5 mr-3 text-neutral-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                    />
                  </svg>
                  Vehicles
                </Link>
                <Link
                  href="/jobcards"
                  className={`flex items-center px-4 py-3 rounded-md group ${
                    window.location.pathname.startsWith("/jobcards")
                      ? "text-white bg-neutral-700"
                      : "text-neutral-300 hover:bg-neutral-700 hover:text-white"
                  }`}
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-5 w-5 mr-3 text-neutral-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                    />
                  </svg>
                  Job Cards
                </Link>
              </div>
            </nav>
          </aside>
        )}

        {/* Main Content Area */}
        <main className="flex-1 overflow-auto">{children}</main>
      </div>
    </div>
  );
}
