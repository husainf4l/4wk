"use client";

import Image from "next/image";
import { useState } from "react";
import { useRouter } from "next/navigation";

export default function ReportPage() {
  const [sessionCode, setSessionCode] = useState("");
  const router = useRouter();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (sessionCode.trim()) {
      router.push(`/report/${sessionCode.trim()}`);
    }
  };

  return (
    <div className="min-h-screen bg-neutral-900 flex flex-col">
      {/* Header section with logo */}
      <div className="w-full bg-black py-6 px-8 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Image
            src="/4wk.svg"
            alt="4wk Logo"
            width={40}
            height={40}
            className="rounded-md"
          />
        </div>
        <div className="h-8 w-8 rounded-full bg-neutral-800 flex items-center justify-center cursor-pointer hover:bg-neutral-700 transition">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-4 w-4 text-white"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </div>
      </div>

      {/* Main content */}
      <div className="flex-1 flex flex-col md:flex-row">
        {/* Left side - decorative */}
        <div className="hidden md:block md:w-1/2 bg-neutral-950 relative overflow-hidden">
          <div className="absolute inset-0 opacity-30">
            <Image
              src="/file.svg"
              alt="Background Pattern"
              width={600}
              height={600}
              className="absolute top-1/4 left-1/2 -translate-x-1/2 opacity-10"
            />
          </div>
          <div className="absolute inset-0 flex flex-col items-center justify-center p-12">
            <div className="w-20 h-1 bg-red-600 mb-8"></div>
            <h2 className="text-4xl font-black text-white mb-6 tracking-tight">
              Garage Report
            </h2>
            <p className="text-neutral-400 text-center max-w-xs leading-relaxed">
              Access your complete vehicle service history, diagnostics, and
              recommendations with your unique session code.
            </p>
          </div>
        </div>

        {/* Right side - form */}
        <div className="w-full md:w-1/2 flex items-center justify-center p-8">
          <div className="w-full max-w-md">
            <div className="md:hidden mb-10 text-center">
              <h2 className="text-3xl font-black text-white mb-3 tracking-tight">
                Garage Report
              </h2>
              <p className="text-neutral-400 text-center max-w-xs mx-auto leading-relaxed">
                Access your complete vehicle service history.
              </p>
            </div>

            <div className="bg-neutral-800 border border-neutral-700 rounded-lg p-8">
              <h3 className="text-xl font-bold text-white mb-6">
                Enter Session Code
              </h3>

              <form className="space-y-6" onSubmit={handleSubmit}>
                <div className="space-y-2">
                  <label
                    htmlFor="session"
                    className="text-sm text-neutral-400 font-medium"
                  >
                    Session Code
                  </label>
                  <input
                    id="session"
                    name="session"
                    type="text"
                    placeholder="XJ29-4WK"
                    className="w-full px-4 py-3 rounded-md border border-neutral-700 bg-neutral-900 text-white placeholder-neutral-500 focus:outline-none focus:ring-1 focus:ring-red-500"
                    value={sessionCode}
                    onChange={(e) => setSessionCode(e.target.value)}
                    required
                  />
                  <p className="text-xs text-neutral-500 mt-2">
                    This code was provided to you after your service
                  </p>
                </div>

                <button
                  type="submit"
                  className="w-full bg-red-600 hover:bg-red-700 text-white py-3 rounded-md font-semibold transition-colors"
                >
                  Access Report
                </button>
              </form>

              <div className="mt-6 pt-6 border-t border-neutral-700 flex items-center justify-between">
                <span className="text-xs text-neutral-500">Need help?</span>
                <button className="text-xs text-red-500 hover:text-red-400">
                  Contact Support
                </button>
              </div>
            </div>

            <div className="mt-8 text-center">
              <p className="text-neutral-600 text-sm">
                © 2025 GIXAT. All rights reserved.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
