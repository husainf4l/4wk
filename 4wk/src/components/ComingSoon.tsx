import React from "react";
import Link from "next/link";
import Image from "next/image";

const ComingSoon = () => (
  <div className="min-h-screen flex items-center justify-center bg-neutral-900">
    <div className="bg-white p-10 rounded-3xl shadow-2xl text-center max-w-md w-full">
      <div className="relative h-12 mx-auto mb-6">
        <Image
          src="/4wk.svg"
          alt="Logo"
          fill
          style={{ objectFit: "contain" }}
          priority
        />
      </div>
      <h1 className="text-4xl font-bold text-neutral-900 mb-4">Coming Soon</h1>
      <p className="text-lg text-gray-600 mb-8">
        We’re working hard to launch our new website.
        <br />
        Stay tuned for something amazing!
      </p>
      <Link
        href="/report"
        className="inline-block bg-neutral-900 hover:bg-neutral-700 text-white px-5 py-2.5 rounded-md font-medium transition mb-6"
      >
        View Reports
      </Link>
      <div className="mx-auto w-12 h-12 border-4 border-gray-200 border-t-neutral-900 rounded-full animate-spin"></div>
    </div>
  </div>
);

export default ComingSoon;
