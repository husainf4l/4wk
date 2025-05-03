"use client";

import React, { useState } from "react";
import Link from "next/link";
import LoadingSpinner from "./LoadingSpinner";

interface Column<T> {
  header: string;
  accessor: keyof T | ((item: T) => React.ReactNode);
  className?: string;
}

interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  loading?: boolean;
  onRowClick?: (item: T) => void;
  keyExtractor: (item: T) => string | number;
  emptyMessage?: string;
  className?: string;
  rowClassName?: (item: T) => string;
  detailPath?: (item: T) => string;
}

function DataTable<T>({
  data,
  columns,
  loading = false,
  onRowClick,
  keyExtractor,
  emptyMessage = "No data available",
  className = "",
  rowClassName,
  detailPath,
}: DataTableProps<T>) {
  const [sortColumn, setSortColumn] = useState<keyof T | null>(null);
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("asc");

  const handleSort = (column: keyof T) => {
    if (sortColumn === column) {
      setSortDirection(sortDirection === "asc" ? "desc" : "asc");
    } else {
      setSortColumn(column);
      setSortDirection("asc");
    }
  };

  const sortedData = React.useMemo(() => {
    if (!sortColumn) return data;

    return [...data].sort((a, b) => {
      const aValue = a[sortColumn];
      const bValue = b[sortColumn];

      if (typeof aValue === "string" && typeof bValue === "string") {
        return sortDirection === "asc"
          ? aValue.localeCompare(bValue)
          : bValue.localeCompare(aValue);
      }

      if (typeof aValue === "number" && typeof bValue === "number") {
        return sortDirection === "asc" ? aValue - bValue : bValue - aValue;
      }

      return 0;
    });
  }, [data, sortColumn, sortDirection]);

  const renderCell = (item: T, column: Column<T>): React.ReactNode => {
    if (typeof column.accessor === "function") {
      return column.accessor(item);
    }

    // We need to handle the value explicitly and ensure it's a valid React node
    const value = item[column.accessor];

    // Convert to string if it's not a valid ReactNode
    if (value === null || value === undefined) {
      return "";
    }

    // Try to convert to string for primitive values
    if (
      typeof value === "string" ||
      typeof value === "number" ||
      typeof value === "boolean"
    ) {
      return String(value);
    }

    // For complex objects, convert to JSON string
    if (typeof value === "object") {
      try {
        return JSON.stringify(value);
      } catch {
        return "[Object]";
      }
    }

    // Fallback
    return String(value);
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-[200px]">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  if (data.length === 0) {
    return (
      <div className="text-center py-10 text-neutral-400">{emptyMessage}</div>
    );
  }

  return (
    <div className={`overflow-x-auto ${className}`}>
      <table className="w-full text-sm text-left text-neutral-300">
        <thead className="text-xs uppercase text-neutral-400 border-b border-neutral-700">
          <tr>
            {columns.map((column, index) => (
              <th
                key={index}
                className={`px-4 py-3 ${column.className || ""} ${
                  typeof column.accessor === "string" ? "cursor-pointer" : ""
                }`}
                onClick={() =>
                  typeof column.accessor === "string" &&
                  handleSort(column.accessor)
                }
              >
                <div className="flex items-center">
                  {column.header}
                  {sortColumn === column.accessor && (
                    <span className="ml-1">
                      {sortDirection === "asc" ? "↑" : "↓"}
                    </span>
                  )}
                </div>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {sortedData.map((item) => {
            const key = keyExtractor(item);
            const row = (
              <tr
                key={key}
                className={`border-b border-neutral-800 hover:bg-neutral-800 transition-colors ${
                  onRowClick || detailPath ? "cursor-pointer" : ""
                } ${rowClassName ? rowClassName(item) : ""}`}
                onClick={() => onRowClick && onRowClick(item)}
              >
                {columns.map((column, index) => (
                  <td
                    key={index}
                    className={`px-4 py-3 ${column.className || ""}`}
                  >
                    {renderCell(item, column)}
                  </td>
                ))}
              </tr>
            );

            if (detailPath) {
              return (
                <Link key={key} href={detailPath(item)}>
                  {row}
                </Link>
              );
            }

            return row;
          })}
        </tbody>
      </table>
    </div>
  );
}

export default DataTable;
