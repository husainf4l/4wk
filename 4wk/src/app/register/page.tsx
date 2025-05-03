"use client";

import { useState, FormEvent, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { signUp, onAuthChange } from "@/services/auth.service";

// Add AuthError interface
interface AuthError {
  code: string;
  message: string;
}

export default function RegisterPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    // Redirect already authenticated users
    const unsubscribe = onAuthChange((user) => {
      if (user) {
        router.push("/dashboard");
      }
    });

    return () => unsubscribe();
  }, [router]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validate passwords match
    if (password !== confirmPassword) {
      setError("Passwords do not match");
      return;
    }

    // Validate password strength
    if (password.length < 6) {
      setError("Password should be at least 6 characters long");
      return;
    }

    setLoading(true);

    try {
      await signUp(email, password);
      router.push("/dashboard");
    } catch (err: unknown) {
      console.error("Registration error:", err);
      setError(getErrorMessage((err as AuthError).code));
    } finally {
      setLoading(false);
    }
  };

  const getErrorMessage = (errorCode: string) => {
    switch (errorCode) {
      case "auth/email-already-in-use":
        return "An account with this email already exists";
      case "auth/invalid-email":
        return "Invalid email address format";
      case "auth/weak-password":
        return "Password is too weak. Please use a stronger password";
      case "auth/operation-not-allowed":
        return "Account creation is currently disabled";
      default:
        return "Failed to create account. Please try again";
    }
  };

  return (
    <div className="min-h-screen bg-neutral-900 flex flex-col">
      {/* Header section with logo */}
      <div className="w-full bg-black py-6 px-8 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Image
            src="/4wk.png"
            alt="4wk Logo"
            width={40}
            height={40}
            className="rounded-md"
          />
          <span className="text-white font-bold text-xl">GIXAT</span>
        </div>
      </div>

      {/* Main content */}
      <div className="flex-1 flex flex-col md:flex-row">
        {/* Left side - decorative */}
        <div className="hidden md:block md:w-1/2 bg-neutral-950 relative overflow-hidden">
          <div className="absolute inset-0 opacity-30">
            <Image
              src="/window.svg"
              alt="Background Pattern"
              width={600}
              height={600}
              className="absolute top-1/4 left-1/2 -translate-x-1/2 opacity-10"
            />
          </div>
          <div className="absolute inset-0 flex flex-col items-center justify-center p-12">
            <div className="w-20 h-1 bg-red-600 mb-8"></div>
            <h2 className="text-4xl font-black text-white mb-6 tracking-tight">
              Create Account
            </h2>
            <p className="text-neutral-400 text-center max-w-xs leading-relaxed">
              Join GIXAT to access and manage vehicle inspection reports.
            </p>
          </div>
        </div>

        {/* Right side - form */}
        <div className="w-full md:w-1/2 flex items-center justify-center p-8">
          <div className="w-full max-w-md">
            <div className="md:hidden mb-10 text-center">
              <h2 className="text-3xl font-black text-white mb-3 tracking-tight">
                Create Account
              </h2>
              <p className="text-neutral-400 text-center max-w-xs mx-auto leading-relaxed">
                Join GIXAT today.
              </p>
            </div>

            <div className="bg-neutral-800 border border-neutral-700 rounded-lg p-8">
              <h3 className="text-xl font-bold text-white mb-6">Sign Up</h3>

              {error && (
                <div className="mb-6 p-3 rounded-md bg-red-900/30 border border-red-900/50">
                  <p className="text-red-400 text-sm">{error}</p>
                </div>
              )}

              <form className="space-y-6" onSubmit={handleSubmit}>
                <div className="space-y-2">
                  <label
                    htmlFor="email"
                    className="text-sm text-neutral-400 font-medium"
                  >
                    Email Address
                  </label>
                  <input
                    id="email"
                    name="email"
                    type="email"
                    placeholder="your.email@example.com"
                    className="w-full px-4 py-3 rounded-md border border-neutral-700 bg-neutral-900 text-white placeholder-neutral-500 focus:outline-none focus:ring-1 focus:ring-red-500"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <label
                    htmlFor="password"
                    className="text-sm text-neutral-400 font-medium"
                  >
                    Password
                  </label>
                  <input
                    id="password"
                    name="password"
                    type="password"
                    placeholder="••••••••"
                    className="w-full px-4 py-3 rounded-md border border-neutral-700 bg-neutral-900 text-white placeholder-neutral-500 focus:outline-none focus:ring-1 focus:ring-red-500"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                  <p className="text-xs text-neutral-500 mt-1">
                    Must be at least 6 characters
                  </p>
                </div>

                <div className="space-y-2">
                  <label
                    htmlFor="confirmPassword"
                    className="text-sm text-neutral-400 font-medium"
                  >
                    Confirm Password
                  </label>
                  <input
                    id="confirmPassword"
                    name="confirmPassword"
                    type="password"
                    placeholder="••••••••"
                    className="w-full px-4 py-3 rounded-md border border-neutral-700 bg-neutral-900 text-white placeholder-neutral-500 focus:outline-none focus:ring-1 focus:ring-red-500"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    required
                  />
                </div>

                <button
                  type="submit"
                  className="w-full bg-red-600 hover:bg-red-700 text-white py-3 rounded-md font-semibold transition-colors flex items-center justify-center"
                  disabled={loading}
                >
                  {loading ? (
                    <span className="h-5 w-5 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></span>
                  ) : null}
                  {loading ? "Creating Account..." : "Create Account"}
                </button>
              </form>

              <div className="mt-6 pt-6 border-t border-neutral-700">
                <p className="text-neutral-500 text-center text-sm">
                  Already have an account?{" "}
                  <Link
                    href="/login"
                    className="text-red-500 hover:text-red-400 font-medium"
                  >
                    Sign in
                  </Link>
                </p>
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
