"use client";

import React, { ReactNode } from "react";
import Link from "next/link";

interface StatCardProps {
  title: string;
  value: string | number;
  icon?: ReactNode;
  change?: {
    value: number;
    isPositive: boolean;
  };
  link?: string;
  className?: string;
  loading?: boolean;
}

const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  icon,
  change,
  link,
  className = "",
  loading = false,
}) => {
  const CardContent = () => (
    <div
      className={`bg-neutral-800 border border-neutral-700 rounded-lg shadow-lg p-6 transition-all hover:border-neutral-500 ${className}`}
    >
      <div className="flex justify-between">
        <div>
          <p className="text-neutral-400 text-sm font-medium mb-1">{title}</p>
          {loading ? (
            <div className="h-8 w-24 bg-neutral-700 animate-pulse rounded"></div>
          ) : (
            <p className="text-white text-2xl font-bold">{value}</p>
          )}

          {change && !loading && (
            <div className="mt-2 flex items-center">
              <span
                className={`text-xs font-medium ${
                  change.isPositive ? "text-green-500" : "text-red-500"
                }`}
              >
                {change.isPositive ? "↑" : "↓"} {Math.abs(change.value)}%
              </span>
              <span className="text-neutral-500 text-xs ml-1">
                vs last period
              </span>
            </div>
          )}
        </div>

        {icon && <div className="text-neutral-400">{icon}</div>}
      </div>
    </div>
  );

  if (link) {
    return (
      <Link href={link} className="block">
        <CardContent />
      </Link>
    );
  }

  return <CardContent />;
};

export default StatCard;
