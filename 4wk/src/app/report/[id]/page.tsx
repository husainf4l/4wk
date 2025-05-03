"use client";

import { useParams } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { useEffect, useState, useRef } from "react";
import { ReportData, getReportBySessionId } from "@/services/firebase.service";
import useErrorHandler from "@/hooks/useErrorHandler";
import { useToast } from "@/components/ToastContext";

// Define interfaces for the complex object structures
interface ObservationItem extends Record<string, unknown> {
  id?: string;
  observation: string;
  argancy: string;
  price: number;
  visible?: boolean;
}

interface RequestItem extends Record<string, unknown> {
  request: string;
  argancy: string;
  price: number;
}

interface FindingItem extends Record<string, unknown> {
  finding: string;
  argancy: string;
  price: number;
}

export default function ReportDetailPage() {
  const params = useParams();
  const sessionId = params.id as string;

  const [loading, setLoading] = useState(true);
  const [report, setReport] = useState<ReportData | null>(null);
  const [activeImageUrl, setActiveImageUrl] = useState<string | null>(null);
  const [clientNotes, setClientNotes] = useState("");
  const [approvedItems, setApprovedItems] = useState<string[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  const reportRef = useRef<HTMLDivElement>(null);
  const { error, handleError } = useErrorHandler();
  const { showToast } = useToast();

  useEffect(() => {
    const fetchReport = async () => {
      try {
        setLoading(true);
        const reportData = await getReportBySessionId(sessionId);
        setReport(reportData);

        if (!reportData) {
          handleError(
            "No report found with this session ID. Please check and try again."
          );
        } else {
          showToast("Report loaded successfully", "success");
        }
      } catch (err) {
        handleError(err);
        showToast("Failed to load report", "error");
      } finally {
        setLoading(false);
      }
    };

    fetchReport();
  }, [sessionId, handleError, showToast]);

  // Helper function to safely access nested properties
  const safeAccess = <T, O extends object>(
    obj: O,
    path: string,
    fallback: T
  ): T => {
    try {
      return (
        (path.split(".").reduce((acc: unknown, part: string) => {
          if (
            acc &&
            typeof acc === "object" &&
            part in (acc as Record<string, unknown>)
          ) {
            return (acc as Record<string, unknown>)[part];
          }
          return null;
        }, obj as unknown) as T) || fallback
      );
    } catch {
      return fallback;
    }
  };

  const formatDate = (dateString: string) => {
    if (!dateString) return "";
    try {
      return new Date(dateString).toLocaleDateString("en-US", {
        year: "numeric",
        month: "short",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });
    } catch {
      return dateString;
    }
  };

  const ImageModal = ({
    url,
    onClose,
  }: {
    url: string;
    onClose: () => void;
  }) => (
    <div
      className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center p-2 sm:p-4 backdrop-blur-sm"
      onClick={onClose}
    >
      <div className="max-w-4xl w-full relative animate-fade-in">
        <button
          className="absolute top-0 right-0 sm:-top-12 text-white hover:text-red-500 flex items-center gap-2 transition-colors bg-black/40 sm:bg-transparent p-2 sm:p-0 rounded-full sm:rounded-none z-20"
          onClick={onClose}
        >
          <span className="hidden sm:inline">Close</span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-5 w-5"
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
        </button>
        <div className="relative w-full h-[70vh] sm:h-[80vh] rounded-lg overflow-hidden border border-neutral-700 shadow-2xl">
          <Image
            src={url}
            alt="Enlarged image"
            className="object-contain"
            fill
            unoptimized={url.includes("firebasestorage.googleapis.com")}
            sizes="100vw"
            priority
          />
          <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/70 to-transparent p-3 sm:p-4">
            <p className="text-white text-xs sm:text-sm truncate">
              Image from inspection report
            </p>
          </div>
        </div>
      </div>
    </div>
  );

  // New RequestList component specifically for client requests with a task-like design
  const RequestList = ({ items }: { items: RequestItem[] }) => (
    <div className="flex flex-col space-y-2 sm:space-y-3 w-full">
      {(items || []).map((item, index) => (
        <div
          key={index}
          className="border-l-4 border-red-500 rounded-md overflow-hidden bg-gradient-to-r from-red-900/10 to-neutral-900 shadow-md"
        >
          <div className="flex justify-between items-center p-0.5">
            <div className="flex items-center flex-1">
              <div className="bg-neutral-800/90 p-2 rounded-full mr-3 ml-2">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  className="h-5 w-5 text-red-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                  />
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
              </div>
              <div className="flex-1">
                <p className="text-white font-medium text-sm sm:text-base">
                  {item.request}
                </p>
                {typeof item.price === "number" && item.price > 0 && (
                  <p className="text-neutral-400 text-xs mt-1">
                    Estimated cost: ${item.price}
                  </p>
                )}
              </div>
            </div>
            {item.argancy && (
              <div
                className={`self-stretch flex items-center px-4 min-w-[90px] justify-center ${
                  item.argancy === "high"
                    ? "bg-red-900/40 text-red-300"
                    : item.argancy === "medium"
                    ? "bg-yellow-900/40 text-yellow-300"
                    : "bg-green-900/40 text-green-300"
                }`}
              >
                <span className="text-xs font-medium uppercase tracking-wider">
                  {item.argancy}
                </span>
              </div>
            )}
          </div>
        </div>
      ))}
    </div>
  );

  // Content to render
  const renderContent = () => {
    if (loading) {
      return (
        <div className="p-8 flex flex-col items-center justify-center min-h-[50vh]">
          <div className="w-12 h-12 border-4 border-neutral-700 border-t-red-600 rounded-full animate-spin"></div>
          <p className="mt-4 text-white font-medium">Loading report data...</p>
        </div>
      );
    }

    if (error.isError || !report) {
      return (
        <div className="p-8 flex items-center justify-center min-h-[50vh]">
          <div className="bg-neutral-800 border border-neutral-700 rounded-xl p-8 max-w-md w-full text-center">
            <div className="w-16 h-16 mx-auto mb-6 rounded-full flex items-center justify-center bg-red-900/30">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-8 w-8 text-red-500"
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
            <h2 className="text-2xl font-bold text-white mb-2">
              Report Not Found
            </h2>
            <p className="text-neutral-400 mb-6">
              {error.message || "Unable to load the requested report."}
            </p>
            <Link
              href="/report"
              className="inline-block bg-red-600 hover:bg-red-700 text-white px-5 py-2.5 rounded-md font-medium transition"
            >
              Back to Reports
            </Link>
          </div>
        </div>
      );
    }

    // Helper components
    const ImageGallery = ({ images }: { images: string[] }) => (
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 sm:gap-3 md:grid-cols-4 md:gap-4 mt-3 sm:mt-4">
        {images.map((url, index) => (
          <div
            key={index}
            className="aspect-square rounded-md overflow-hidden bg-neutral-900 cursor-pointer relative group shadow-md hover:shadow-lg transition-all duration-300"
            onClick={() => setActiveImageUrl(url)}
          >
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent opacity-80 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-300 z-10 flex items-end justify-center">
              <span className="text-white text-xs p-2">View</span>
            </div>
            <Image
              src={url || ""}
              alt={`Image ${index + 1}`}
              fill
              unoptimized={url.includes("firebasestorage.googleapis.com")}
              sizes="(max-width: 640px) 50vw, (max-width: 768px) 33vw, 25vw"
              className="object-cover sm:group-hover:scale-105 transition-transform duration-300"
            />
          </div>
        ))}
      </div>
    );

    // Updated Section component with more refined styling
    const Section = ({
      title,
      children,
      className = "",
    }: {
      title: string;
      children: React.ReactNode;
      className?: string;
    }) => (
      <div className={`mb-6 ${className}`}>
        <div className="border-b border-neutral-700 mb-4">
          <h2 className="text-white text-lg font-semibold py-3 px-4 sm:px-6 flex items-center">
            <span className="w-1 h-6 bg-red-700/80 rounded mr-3"></span>
            {title}
          </h2>
        </div>
        {children}
      </div>
    );

    // Updated TagList component to display each item on its own full line
    const TagList = ({
      items,
      valueKey,
    }: {
      items: Array<string | Record<string, unknown>>;
      valueKey?: string;
    }) => (
      <div className="flex flex-col space-y-2 sm:space-y-3 w-full">
        {(items || []).map((item, index) => {
          // If item is a string, render it directly
          if (typeof item === "string") {
            return (
              <div
                key={index}
                className="px-3 py-2.5 sm:px-4 sm:py-3 bg-neutral-900 text-white text-xs sm:text-sm rounded-md w-full"
              >
                {item || ""}
              </div>
            );
          }

          // If item is an object, extract the value using the valueKey
          const value =
            valueKey && typeof item === "object"
              ? (item[valueKey] as string)
              : null;

          if (value) {
            return (
              <div
                key={index}
                className="flex justify-between items-center bg-neutral-900 rounded-md overflow-hidden w-full"
              >
                <span className="px-3 py-2 sm:px-4 sm:py-2.5 text-white text-xs sm:text-sm">
                  {value}
                </span>
                {typeof item === "object" &&
                  "argancy" in item &&
                  typeof item.argancy === "string" && (
                    <span
                      className={`px-3 py-2 text-xs font-medium uppercase tracking-wider border-l min-w-[80px] text-center ${
                        item.argancy === "high"
                          ? "bg-red-900/30 text-red-300 border-red-500"
                          : item.argancy === "medium"
                          ? "bg-yellow-900/30 text-yellow-300 border-yellow-500"
                          : "bg-green-900/30 text-green-300 border-green-500"
                      }`}
                    >
                      {item.argancy as string}
                    </span>
                  )}
              </div>
            );
          }
          return null;
        })}
      </div>
    );

    const ReportHeader = () => (
      <div className="mb-6 sm:mb-8">
        <div className="flex flex-col sm:flex-row sm:items-center gap-4 sm:gap-6 mb-4 sm:mb-6">
          <div className="flex items-center">
            <div className="bg-white/10 backdrop-blur-sm p-2 sm:p-3 rounded-lg shadow-lg mr-3 sm:mr-4">
              <Image
                src="/4wk.svg"
                alt="4WK Logo"
                width={48}
                height={48}
                className="rounded-md h-8 sm:h-12 w-auto"
              />
            </div>
            <div>
              <h1 className="text-xl sm:text-2xl font-bold text-white">
                Vehicle Inspection Report
              </h1>
              <p className="text-neutral-400 text-xs sm:text-sm mt-1">
                <span className="inline-flex items-center bg-neutral-800/80 px-2 py-1 rounded text-xs mr-2">
                  ID: {sessionId.substring(0, 6)}...
                </span>
                <span className="hidden xs:inline">Generated on</span>{" "}
                {formatDate(safeAccess(report, "createdAt", ""))}
              </p>
            </div>
          </div>
        </div>
        <div className="h-1 w-full bg-gradient-to-r from-neutral-800 via-neutral-700 to-neutral-800 rounded-full relative overflow-hidden">
          <span className="absolute h-full w-32 bg-gradient-to-r from-red-700/60 to-transparent animate-pulse"></span>
        </div>
      </div>
    );

    return (
      <div className="p-4 sm:p-6 md:p-8">
        <ReportHeader />

        {activeImageUrl && (
          <ImageModal
            url={activeImageUrl}
            onClose={() => setActiveImageUrl(null)}
          />
        )}

        <div
          ref={reportRef}
          className="bg-gradient-to-br from-neutral-800 to-neutral-900 border border-neutral-700 rounded-lg overflow-hidden shadow-[0_0_20px_rgba(0,0,0,0.3)] backdrop-blur-sm"
        >
          <Section title="Vehicle & Client Details">
            <div className="space-y-8 px-5">
              {/* Report Overview */}
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between pb-5 border-b border-neutral-700">
                <div>
                  <h3 className="text-white font-medium text-base sm:text-lg">
                    Report Overview
                  </h3>
                  <p className="text-neutral-400 text-xs sm:text-sm mt-2">
                    ID: {safeAccess(report, "id", "")} | Created on{" "}
                    {formatDate(safeAccess(report, "createdAt", ""))}
                  </p>
                </div>
                <span className="mt-2 sm:mt-0 bg-neutral-700 px-3 py-1 rounded text-xs text-neutral-300 self-start sm:self-auto">
                  Last updated:{" "}
                  {formatDate(safeAccess(report, "updatedAt", ""))}
                </span>
              </div>

              {/* Client Information */}
              <div>
                <h3 className="text-white font-medium text-sm sm:text-base mb-4">
                  Client Information
                </h3>
                <div className="grid grid-cols-1 gap-5 sm:grid-cols-3 sm:gap-6 bg-neutral-900/50 p-5 rounded-md">
                  <div>
                    <p className="text-neutral-400 text-xs mb-1">Name</p>
                    <p className="text-white font-medium text-sm">
                      {safeAccess(report, "clientData.name", "") as string}
                    </p>
                  </div>
                  <div>
                    <p className="text-neutral-400 text-xs mb-1">Phone</p>
                    <p className="text-white font-medium text-sm">
                      {safeAccess(report, "clientData.phone", "") as string}
                    </p>
                  </div>
                  <div>
                    <p className="text-neutral-400 text-xs mb-1">Location</p>
                    <p className="text-white font-medium text-sm">
                      {
                        safeAccess(
                          report,
                          "clientData.address.city",
                          ""
                        ) as string
                      }
                      {safeAccess(report, "clientData.address.city", "") &&
                      safeAccess(report, "clientData.address.country", "")
                        ? ", "
                        : ""}
                      {
                        safeAccess(
                          report,
                          "clientData.address.country",
                          ""
                        ) as string
                      }
                    </p>
                  </div>
                </div>
              </div>

              {/* Vehicle Information */}
              <div>
                <h3 className="text-white font-medium text-sm sm:text-base mb-4">
                  Vehicle Information
                </h3>
                <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4 sm:gap-6 bg-neutral-900/50 p-5 rounded-md">
                  <div>
                    <p className="text-neutral-400 text-xs mb-1">Make/Model</p>
                    <p className="text-white font-medium text-sm">
                      {safeAccess(report, "carData.make", "") as string}{" "}
                      {safeAccess(report, "carData.model", "") as string}
                    </p>
                  </div>
                  <div>
                    <p className="text-neutral-400 text-xs mb-1">Year</p>
                    <p className="text-white font-medium text-sm">
                      {safeAccess(report, "carData.year", "") as string}
                    </p>
                  </div>
                  <div>
                    <p className="text-neutral-400 text-xs mb-1">
                      Plate Number
                    </p>
                    <p className="text-white font-medium text-sm">
                      {safeAccess(report, "carData.plateNumber", "") as string}
                    </p>
                  </div>
                  <div>
                    <p className="text-neutral-400 text-xs mb-1">VIN</p>
                    <p className="text-white font-medium text-sm">
                      {safeAccess(report, "carData.vin", "") as string}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </Section>

          <Section title="Client Requests">
            <div className="bg-neutral-900/30 rounded-lg p-5">
              {safeAccess(report, "clientNotes", "") && (
                <div className="mb-5">
                  <h3 className="text-white font-medium text-sm sm:text-base mb-3 border-b border-neutral-700 pb-2">
                    Client Notes
                  </h3>
                  <div className="bg-neutral-900 p-3 sm:p-4 rounded-md text-neutral-300 text-sm">
                    <p>{safeAccess(report, "clientNotes", "") as string}</p>
                  </div>
                </div>
              )}

              {(safeAccess(report, "clientRequests", []) as RequestItem[])
                .length > 0 && (
                <div className="mb-5">
                  <h3 className="text-white font-medium text-sm sm:text-base mb-3 border-b border-neutral-700 pb-2">
                    Client Requests
                  </h3>
                  <RequestList
                    items={
                      safeAccess(report, "clientRequests", []) as RequestItem[]
                    }
                  />
                </div>
              )}

              {(safeAccess(report, "clientNotesImages", []) as string[])
                .length > 0 && (
                <div>
                  <h3 className="text-white font-medium text-sm sm:text-base mb-3 border-b border-neutral-700 pb-2">
                    Client Provided Images
                  </h3>
                  <ImageGallery
                    images={
                      safeAccess(report, "clientNotesImages", []) as string[]
                    }
                  />
                </div>
              )}
            </div>
          </Section>

          <Section title="Inspection Findings">
            <div className="bg-neutral-900/30 rounded-lg p-5">
              {(safeAccess(report, "inspectionFindings", []) as FindingItem[])
                .length > 0 && (
                <div className="mb-5">
                  <h3 className="text-white font-medium text-sm sm:text-base mb-3 border-b border-neutral-700 pb-2">
                    Issues Found
                  </h3>
                  <TagList
                    items={
                      safeAccess(
                        report,
                        "inspectionFindings",
                        []
                      ) as FindingItem[]
                    }
                    valueKey="finding"
                  />
                </div>
              )}

              {safeAccess(report, "inspectionNotes", "") && (
                <div className="mb-5">
                  <h3 className="text-white font-medium text-sm sm:text-base mb-3 border-b border-neutral-700 pb-2">
                    Technician Notes
                  </h3>
                  <div className="bg-neutral-900 p-3 sm:p-4 rounded-md text-neutral-300 text-sm">
                    <p>{safeAccess(report, "inspectionNotes", "") as string}</p>
                  </div>
                </div>
              )}

              {(safeAccess(report, "inspectionImages", []) as string[]).length >
                0 && (
                <div>
                  <h3 className="text-white font-medium text-sm sm:text-base mb-3 border-b border-neutral-700 pb-2">
                    Inspection Images
                  </h3>
                  <ImageGallery
                    images={
                      safeAccess(report, "inspectionImages", []) as string[]
                    }
                  />
                </div>
              )}
            </div>
          </Section>

          <Section title="Test Drive Results">
            <div className="bg-neutral-900/30 rounded-lg p-5">
              {safeAccess(report, "testDriveNotes", "") && (
                <div className="mb-5">
                  <h3 className="text-white font-medium text-sm sm:text-base mb-3 border-b border-neutral-700 pb-2">
                    Test Drive Notes
                  </h3>
                  <div className="bg-neutral-900 p-3 sm:p-4 rounded-md text-neutral-300 text-sm">
                    <p>{safeAccess(report, "testDriveNotes", "") as string}</p>
                  </div>
                </div>
              )}

              {(
                safeAccess(
                  report,
                  "testDriveObservations",
                  []
                ) as ObservationItem[]
              ).length > 0 && (
                <div className="mb-5">
                  <h3 className="text-white font-medium text-sm sm:text-base mb-3 border-b border-neutral-700 pb-2">
                    Observations
                  </h3>
                  <TagList
                    items={
                      safeAccess(
                        report,
                        "testDriveObservations",
                        []
                      ) as ObservationItem[]
                    }
                    valueKey="observation"
                  />
                </div>
              )}

              {(safeAccess(report, "testDriveImages", []) as string[]).length >
                0 && (
                <div>
                  <h3 className="text-white font-medium text-sm sm:text-base mb-3 border-b border-neutral-700 pb-2">
                    Test Drive Images
                  </h3>
                  <ImageGallery
                    images={
                      safeAccess(report, "testDriveImages", []) as string[]
                    }
                  />
                </div>
              )}
            </div>
          </Section>

          <Section title="Conclusion">
            <div className="bg-neutral-900/30 rounded-lg p-5">
              {safeAccess(report, "recommendations", "") && (
                <div className="mb-5">
                  <h3 className="text-white font-medium text-sm sm:text-base mb-3 border-b border-neutral-700 pb-2">
                    Recommendations
                  </h3>
                  <div className="bg-neutral-900 p-3 sm:p-4 rounded-md text-neutral-300 text-sm">
                    <p>{safeAccess(report, "recommendations", "") as string}</p>
                  </div>
                </div>
              )}

              {safeAccess(report, "summary", "") && (
                <div>
                  <h3 className="text-white font-medium text-sm sm:text-base mb-3 border-b border-neutral-700 pb-2">
                    Summary
                  </h3>
                  <div className="bg-neutral-900 p-3 sm:p-4 rounded-md text-neutral-300 text-sm">
                    <p>{safeAccess(report, "summary", "") as string}</p>
                  </div>
                </div>
              )}
            </div>
          </Section>

          <Section title="Client Feedback">
            <div className="bg-gradient-to-r from-neutral-800 to-neutral-900 rounded-lg p-5 border border-neutral-700/50">
              {submitted ? (
                <div className="flex flex-col items-center justify-center py-8">
                  <div className="w-16 h-16 rounded-full bg-green-900/20 flex items-center justify-center mb-4">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      className="h-8 w-8 text-green-500"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M5 13l4 4L19 7"
                      />
                    </svg>
                  </div>
                  <h3 className="text-white text-lg font-medium mb-2">
                    Thank You for Your Feedback!
                  </h3>
                  <p className="text-neutral-400 text-center max-w-md">
                    Your response has been submitted successfully. We appreciate
                    your input and will be in touch soon.
                  </p>
                </div>
              ) : (
                <>
                  <div className="mb-6">
                    <h3 className="text-white font-medium text-base sm:text-lg mb-2">
                      Your Response
                    </h3>
                    <p className="text-neutral-400 text-sm">
                      Please review the inspection report and provide your
                      feedback below. You can approve service items, add notes,
                      or request additional information.
                    </p>
                  </div>

                  {(
                    safeAccess(
                      report,
                      "inspectionFindings",
                      []
                    ) as FindingItem[]
                  ).length > 0 && (
                    <div className="mb-6">
                      <h4 className="text-white font-medium text-sm mb-3">
                        Approve Service Items
                      </h4>
                      <div className="space-y-2">
                        {(
                          safeAccess(
                            report,
                            "inspectionFindings",
                            []
                          ) as FindingItem[]
                        ).map((item, index) => (
                          <div
                            key={index}
                            className="flex items-center bg-neutral-900 px-4 py-3 rounded-md"
                          >
                            <input
                              type="checkbox"
                              id={`approve-item-${index}`}
                              className="w-4 h-4 rounded border-neutral-600 text-red-600 focus:ring-red-500 bg-neutral-800"
                              checked={approvedItems.includes(
                                item.finding as string
                              )}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  setApprovedItems([
                                    ...approvedItems,
                                    item.finding as string,
                                  ]);
                                } else {
                                  setApprovedItems(
                                    approvedItems.filter(
                                      (i) => i !== item.finding
                                    )
                                  );
                                }
                              }}
                            />
                            <label
                              htmlFor={`approve-item-${index}`}
                              className="ml-3 text-sm text-white cursor-pointer flex-1"
                            >
                              {item.finding as string}
                              <span
                                className={`ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                                  item.argancy === "high"
                                    ? "bg-red-900/50 text-red-300"
                                    : item.argancy === "medium"
                                    ? "bg-yellow-900/50 text-yellow-300"
                                    : "bg-green-900/50 text-green-300"
                                }`}
                              >
                                {item.argancy as string}
                              </span>
                            </label>
                            {typeof item.price === "number" &&
                              item.price > 0 && (
                                <span className="text-neutral-400 text-sm">
                                  ${item.price}
                                </span>
                              )}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  <div className="mb-6">
                    <label
                      htmlFor="client-notes"
                      className="block text-white font-medium text-sm mb-2"
                    >
                      Additional Notes
                    </label>
                    <textarea
                      id="client-notes"
                      className="w-full bg-neutral-800 border border-neutral-700 rounded-md px-4 py-3 text-white placeholder-neutral-500 focus:outline-none focus:ring-2 focus:ring-red-500/50 focus:border-red-500"
                      rows={4}
                      placeholder="Add any additional requests, questions, or feedback here..."
                      value={clientNotes}
                      onChange={(e) => setClientNotes(e.target.value)}
                    ></textarea>
                  </div>

                  <div className="flex flex-wrap gap-3 justify-end">
                    <button
                      onClick={() => {
                        // TODO: Implement actual submission to backend
                        setSubmitting(true);
                        setTimeout(() => {
                          setSubmitting(false);
                          setSubmitted(true);
                          showToast(
                            "Feedback submitted successfully!",
                            "success"
                          );
                        }, 1500);
                      }}
                      disabled={submitting}
                      className={`px-5 py-2.5 rounded-md font-medium transition-colors flex items-center gap-2 ${
                        submitting
                          ? "bg-neutral-700 text-neutral-300 cursor-not-allowed"
                          : "bg-red-600 hover:bg-red-700 text-white"
                      }`}
                    >
                      {submitting ? (
                        <>
                          <svg
                            className="animate-spin h-4 w-4 text-neutral-300"
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                          >
                            <circle
                              className="opacity-25"
                              cx="12"
                              cy="12"
                              r="10"
                              stroke="currentColor"
                              strokeWidth="4"
                            ></circle>
                            <path
                              className="opacity-75"
                              fill="currentColor"
                              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                            ></path>
                          </svg>
                          Processing...
                        </>
                      ) : (
                        <>Submit Feedback</>
                      )}
                    </button>
                  </div>
                </>
              )}
            </div>
          </Section>

          <div className="p-6 sm:p-8 text-center border-t border-neutral-700 mt-6">
            <div className="flex flex-col items-center justify-center gap-3 mb-5">
              <Image
                src="/4wk.svg"
                alt="4WK Logo"
                width={24}
                height={24}
                className="rounded-sm"
              />
              <span className="text-white font-medium text-sm">4WK Garage</span>

              <button
                onClick={() => window.print()}
                className="flex items-center gap-2 bg-red-700/20 hover:bg-red-700/30 px-6 py-2.5 rounded-md text-white border border-red-700/40 transition-all duration-200 mt-4"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  className="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2h2m2 4h6a2 2 0 002-2v-4a2 2-2H9a2 2 0 00-2 2v-4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                  />
                </svg>
                Print Report
              </button>
            </div>
            <p className="text-neutral-400 text-xs">
              © {new Date().getFullYear()} 4WK - Vehicle inspection report
              generated on {formatDate(safeAccess(report, "createdAt", ""))}
            </p>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-neutral-900 bg-[radial-gradient(circle_at_center,rgba(120,120,120,0.05)_1px,transparent_1px)] bg-[length:24px_24px]">
      <main className="container mx-auto max-w-5xl px-3 sm:px-6 py-4 sm:py-8">
        {renderContent()}
      </main>
    </div>
  );
}
