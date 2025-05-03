"use client";

import { useState, FormEvent, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { signIn, onAuthChange } from "@/services/auth.service";
import useErrorHandler from "@/hooks/useErrorHandler";
import { useToast } from "@/components/ToastContext";
import AppLayout from "@/components/AppLayout";

// Fix the any type by adding proper error interface
interface AuthError {
  code: string;
  message: string;
}

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const { error, handleError, clearError } = useErrorHandler();
  const { showToast } = useToast();

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
    clearError();
    setLoading(true);

    try {
      await signIn(email, password);
      showToast("Successfully signed in!", "success");
      router.push("/dashboard");
    } catch (err: unknown) {
      console.error("Login error:", err);
      handleError(err);
      showToast(getErrorMessage((err as AuthError).code), "error");
    } finally {
      setLoading(false);
    }
  };

  const getErrorMessage = (errorCode: string) => {
    switch (errorCode) {
      case "auth/invalid-email":
        return "Invalid email address format";
      case "auth/user-disabled":
        return "This account has been disabled";
      case "auth/user-not-found":
        return "No account found with this email";
      case "auth/wrong-password":
        return "Incorrect password";
      case "auth/too-many-requests":
        return "Too many unsuccessful login attempts. Please try again later";
      default:
        return "Failed to sign in. Please try again";
    }
  };

  return (
    <AppLayout requireAuth={false}>
      <div className="min-h-screen bg-neutral-900 flex flex-col">
        {/* Main content */}
        <div className="flex-1 flex flex-col md:flex-row">
          {/* Left side - decorative */}
          <div className="hidden md:block md:w-1/2 bg-neutral-950 relative overflow-hidden">
            <div className="absolute inset-0 opacity-30">
              <Image
                src="/globe.svg"
                alt="Background Pattern"
                width={600}
                height={600}
                className="absolute top-1/4 left-1/2 -translate-x-1/2 opacity-10"
              />
            </div>
            <div className="absolute inset-0 flex flex-col items-center justify-center p-12">
              <div className="w-20 h-1 bg-red-600 mb-8"></div>
              <h2 className="text-4xl font-black text-white mb-6 tracking-tight">
                Welcome Back
              </h2>
              <p className="text-neutral-400 text-center max-w-xs leading-relaxed">
                Sign in to access your account and manage vehicle inspection
                reports.
              </p>
            </div>
          </div>

          {/* Right side - form */}
          <div className="w-full md:w-1/2 flex items-center justify-center p-8">
            <div className="w-full max-w-md">
              <div className="md:hidden mb-10 text-center">
                <h2 className="text-3xl font-black text-white mb-3 tracking-tight">
                  Welcome Back
                </h2>
                <p className="text-neutral-400 text-center max-w-xs mx-auto leading-relaxed">
                  Sign in to your account.
                </p>
              </div>

              <div className="bg-neutral-800 border border-neutral-700 rounded-lg p-8 shadow-lg">
                <h3 className="text-xl font-bold text-white mb-6">Sign In</h3>

                {error.isError && (
                  <div className="mb-6 p-3 rounded-md bg-red-900/30 border border-red-900/50">
                    <p className="text-red-400 text-sm">{error.message}</p>
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
                    <div className="flex justify-between items-center">
                      <label
                        htmlFor="password"
                        className="text-sm text-neutral-400 font-medium"
                      >
                        Password
                      </label>
                      <Link
                        href="/forgot-password"
                        className="text-xs text-red-500 hover:text-red-400"
                      >
                        Forgot Password?
                      </Link>
                    </div>
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
                  </div>

                  <button
                    type="submit"
                    className="w-full bg-red-600 hover:bg-red-700 text-white py-3 rounded-md font-semibold transition-colors flex items-center justify-center"
                    disabled={loading}
                  >
                    {loading ? (
                      <span className="h-5 w-5 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></span>
                    ) : null}
                    {loading ? "Signing in..." : "Sign In"}
                  </button>
                </form>

                <div className="mt-6 pt-6 border-t border-neutral-700">
                  <p className="text-neutral-500 text-center text-sm">
                    Don&apos;t have an account?{" "}
                    <Link
                      href="/register"
                      className="text-red-500 hover:text-red-400 font-medium"
                    >
                      Create account
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
    </AppLayout>
  );
}
