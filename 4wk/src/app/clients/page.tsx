"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { onAuthChange, signOut } from "@/services/auth.service";

interface ClientData {
  id: string;
  name: string;
  phone: string;
  address?: {
    city?: string;
    country?: string;
  };
  garageId: string;
  carsId: string[];
  sessionsId: string[];
}

interface User {
  email: string | null;
  uid: string;
}

export default function ClientsPage() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [clients, setClients] = useState<ClientData[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const router = useRouter();

  useEffect(() => {
    // Check if user is authenticated, if not redirect to login
    const unsubscribe = onAuthChange((currentUser) => {
      setUser(currentUser);
      setLoading(false);

      if (!currentUser) {
        router.push("/login");
      } else {
        fetchClients();
      }
    });

    return () => unsubscribe();
  }, [router]);

  const fetchClients = async () => {
    setIsLoading(true);

    try {
      const response = await fetch("/api/firebase/clients");
      const data = await response.json();
      setClients(data);
    } catch (error) {
      console.error("Error fetching clients:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSignOut = async () => {
    try {
      await signOut();
      router.push("/login");
    } catch (error) {
      console.error("Error signing out:", error);
    }
  };

  const filteredClients = clients.filter(
    (client) =>
      client.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      client.phone.toLowerCase().includes(searchTerm.toLowerCase()) ||
      client.address?.city?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      client.address?.country?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) {
    return (
      <div className="min-h-screen bg-neutral-900 flex items-center justify-center">
        <div className="flex flex-col items-center">
          <div className="w-12 h-12 border-4 border-neutral-700 border-t-red-600 rounded-full animate-spin"></div>
          <p className="mt-4 text-white font-medium">Loading clients...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-neutral-900 flex flex-col">
      {/* Header/Nav */}
      <header className="bg-black py-4 px-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Image
            src="/4wk.svg"
            alt="4WK Logo"
            width={40}
            height={40}
            className="rounded-md"
          />
          <span className="text-white font-bold text-xl">GIXAT</span>
        </div>

        <div className="flex items-center gap-4">
          <span className="text-neutral-400 text-sm hidden sm:inline-block">
            {user?.email}
          </span>
          <button
            onClick={handleSignOut}
            className="text-white bg-neutral-800 hover:bg-neutral-700 px-4 py-2 rounded-md text-sm"
          >
            Sign Out
          </button>
        </div>
      </header>

      {/* Main Content */}
      <div className="flex flex-col md:flex-row flex-1">
        {/* Sidebar */}
        <aside className="w-full md:w-64 bg-neutral-800 border-r border-neutral-700">
          <nav className="p-4">
            <div className="px-4 py-3 text-xs font-semibold text-neutral-500 uppercase tracking-wider">
              Main
            </div>
            <div className="space-y-1">
              <Link
                href="/dashboard"
                className="flex items-center px-4 py-3 text-neutral-300 hover:bg-neutral-700 hover:text-white rounded-md group"
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
                className="flex items-center px-4 py-3 text-neutral-300 hover:bg-neutral-700 hover:text-white rounded-md group"
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
                className="flex items-center px-4 py-3 text-white bg-neutral-700 rounded-md group"
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
                className="flex items-center px-4 py-3 text-neutral-300 hover:bg-neutral-700 hover:text-white rounded-md group"
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
                className="flex items-center px-4 py-3 text-neutral-300 hover:bg-neutral-700 hover:text-white rounded-md group"
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
            </div>
          </nav>
        </aside>

        {/* Main Content */}
        <main className="flex-1 p-8">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-8">
            <div>
              <h1 className="text-2xl font-bold text-white">Clients</h1>
              <p className="mt-1 text-neutral-400">
                Manage your client information
              </p>
            </div>
            <div className="mt-4 md:mt-0">
              <button
                className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-md flex items-center gap-2 transition-colors"
                onClick={() => console.log("New client")}
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  className="h-5 w-5"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fillRule="evenodd"
                    d="M10 5a1 1 0 011 1v3h3a1 1 0 110 2h-3v3a1 1 0 11-2 0v-3H6a1 1 0 110-2h3V6a1 1 0 011-1z"
                    clipRule="evenodd"
                  />
                </svg>
                New Client
              </button>
            </div>
          </div>

          {/* Search Bar */}
          <div className="relative mb-6">
            <input
              type="text"
              placeholder="Search clients..."
              className="w-full px-4 py-3 pl-10 rounded-md border border-neutral-700 bg-neutral-800 text-white placeholder-neutral-500 focus:outline-none focus:ring-1 focus:ring-red-500"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-5 w-5 text-neutral-500 absolute left-3 top-3.5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
          </div>

          {/* Clients Table */}
          <div className="bg-neutral-800 rounded-lg border border-neutral-700 overflow-hidden">
            <div className="overflow-x-auto">
              {isLoading ? (
                <div className="py-20 text-center">
                  <div className="w-10 h-10 border-4 border-neutral-700 border-t-red-600 rounded-full animate-spin mx-auto"></div>
                  <p className="mt-4 text-neutral-400">Loading clients...</p>
                </div>
              ) : filteredClients.length > 0 ? (
                <table className="w-full text-left">
                  <thead className="bg-neutral-900">
                    <tr>
                      <th className="px-6 py-4 text-xs font-medium text-neutral-400 uppercase tracking-wider">
                        Name
                      </th>
                      <th className="px-6 py-4 text-xs font-medium text-neutral-400 uppercase tracking-wider">
                        Phone
                      </th>
                      <th className="px-6 py-4 text-xs font-medium text-neutral-400 uppercase tracking-wider">
                        Location
                      </th>
                      <th className="px-6 py-4 text-xs font-medium text-neutral-400 uppercase tracking-wider">
                        Cars
                      </th>
                      <th className="px-6 py-4 text-xs font-medium text-neutral-400 uppercase tracking-wider">
                        Sessions
                      </th>
                      <th className="px-6 py-4 text-xs font-medium text-neutral-400 uppercase tracking-wider">
                        Actions
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-neutral-700">
                    {filteredClients.map((client) => (
                      <tr key={client.id} className="hover:bg-neutral-700/50">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center">
                            <div className="h-8 w-8 rounded-full bg-red-600/20 text-red-500 flex items-center justify-center">
                              {client.name.charAt(0).toUpperCase()}
                            </div>
                            <div className="ml-3">
                              <p className="text-white font-medium">
                                {client.name}
                              </p>
                              <p className="text-neutral-400 text-sm">
                                {client.garageId}
                              </p>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-white">
                          {client.phone || "-"}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-white">
                          {client.address ? (
                            <>
                              {client.address.city && (
                                <span>{client.address.city}</span>
                              )}
                              {client.address.city &&
                                client.address.country && <span>, </span>}
                              {client.address.country && (
                                <span>{client.address.country}</span>
                              )}
                            </>
                          ) : (
                            "-"
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className="px-2 py-1 text-xs rounded-full bg-blue-900/30 text-blue-400">
                            {client.carsId?.length || 0}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className="px-2 py-1 text-xs rounded-full bg-green-900/30 text-green-400">
                            {client.sessionsId?.length || 0}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                          <div className="flex space-x-2">
                            <button className="text-blue-500 hover:text-blue-400">
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                className="h-5 w-5"
                                viewBox="0 0 20 20"
                                fill="currentColor"
                              >
                                <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
                              </svg>
                            </button>
                            <button className="text-red-500 hover:text-red-400">
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                className="h-5 w-5"
                                viewBox="0 0 20 20"
                                fill="currentColor"
                              >
                                <path
                                  fillRule="evenodd"
                                  d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z"
                                  clipRule="evenodd"
                                />
                              </svg>
                            </button>
                            <button className="text-yellow-500 hover:text-yellow-400">
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                className="h-5 w-5"
                                viewBox="0 0 20 20"
                                fill="currentColor"
                              >
                                <path d="M10 12a2 2 0 100-4 2 2 0 000 4z" />
                                <path
                                  fillRule="evenodd"
                                  d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z"
                                  clipRule="evenodd"
                                />
                              </svg>
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ) : (
                <div className="py-20 text-center">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-12 w-12 text-neutral-500 mx-auto"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={1}
                      d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
                    />
                  </svg>
                  <p className="mt-4 text-neutral-400">No clients found</p>
                </div>
              )}
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
