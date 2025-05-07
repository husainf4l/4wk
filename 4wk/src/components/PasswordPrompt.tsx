import React, { useState } from "react";
import Image from "next/image";

interface PasswordPromptProps {
  onSubmit: (password: string) => void;
  error?: boolean;
}

const PasswordPrompt: React.FC<PasswordPromptProps> = ({ onSubmit, error }) => {
  const [password, setPassword] = useState("");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(password);
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-[50vh] p-6">
      <div className="w-full max-w-md p-8 space-y-8 bg-gradient-to-br from-neutral-800 to-neutral-900 rounded-lg shadow-lg border border-neutral-700">
        <div className="text-center">
          <div className="flex justify-center mb-4">
            <Image
              src="/4wk.png"
              alt="4WK Logo"
              width={192}
              height={24}
              quality={100}
              className="rounded-md mb-6"
            />
          </div>
          <h2 className="mt-2 text-2xl font-bold text-white">
            Password Protected Report
          </h2>
          <div className="mt-4 mb-2 h-1 w-full bg-gradient-to-r from-neutral-800 via-neutral-700 to-neutral-800 rounded-full relative overflow-hidden">
            <span className="absolute h-full w-32 bg-gradient-to-r from-red-700/60 to-transparent animate-pulse"></span>
          </div>
          <p className="mt-4 text-sm text-neutral-400">
            This report is protected. Please enter the 5-letter password to view
            it.
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div>
            <label htmlFor="password" className="sr-only">
              Password
            </label>
            <input
              id="password"
              name="password"
              type="password"
              maxLength={5}
              required
              className={`relative block w-full px-3 py-2 border ${
                error ? "border-red-500" : "border-neutral-700"
              } rounded-md focus:outline-none focus:ring-red-500 focus:border-red-500 focus:z-10 sm:text-sm bg-neutral-900 text-white placeholder-neutral-500`}
              placeholder="Enter your password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
            {error && (
              <p className="mt-2 text-sm text-red-500">
                Incorrect password. Please try again.
              </p>
            )}
          </div>
          <div>
            <button
              type="submit"
              className="relative flex justify-center w-full px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 border border-transparent rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 focus:ring-offset-neutral-900"
            >
              Access Report
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default PasswordPrompt;
