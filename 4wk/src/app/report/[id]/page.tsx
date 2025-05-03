"use client";

import { useParams } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { useEffect, useState, useRef } from "react";
import { ReportData, getReportBySessionId } from "@/services/firebase.service";
import AppLayout from "@/components/AppLayout";
import useErrorHandler from "@/hooks/useErrorHandler";
import { useToast } from "@/components/ToastContext";

export default function ReportDetailPage() {
  const params = useParams();
  const sessionId = params.id as string;

  const [loading, setLoading] = useState(true);
  const [report, setReport] = useState<ReportData | null>(null);
  const [activeImageUrl, setActiveImageUrl] = useState<string | null>(null);

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
          handleError("No report found with this session ID. Please check and try again.");
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
      className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4"
      onClick={onClose}
    >
      <div className="max-w-4xl w-full relative">
        <button
          className="absolute -top-12 right-0 text-white hover:text-red-500"
          onClick={onClose}
        >
          Close &times;
        </button>
        <div className="relative w-full h-[80vh]">
          <Image
            src={url}
            alt="Enlarged image"
            className="object-contain rounded-lg"
            fill
            unoptimized={url.includes("firebasestorage.googleapis.com")}
            sizes="(max-width: 768px) 100vw, 80vw"
          />
        </div>
      </div>
    </div>
  );

  // Content to render inside AppLayout
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
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2 md:gap-3 mt-3">
        {images.map((url, index) => (
          <div
            key={index}
            className="aspect-square rounded-md overflow-hidden bg-neutral-900 cursor-pointer relative"
            onClick={() => setActiveImageUrl(url)}
          >
            <Image
              src={url || ""}
              alt={`Image ${index + 1}`}
              fill
              unoptimized={url.includes("firebasestorage.googleapis.com")}
              sizes="(max-width: 768px) 50vw, 25vw"
              className="object-cover hover:opacity-90 transition"
            />
          </div>
        ))}
      </div>
    );

    const RatingDisplay = ({ rating }: { rating: number }) => (
      <div className="flex items-center gap-1 mt-1">
        {[1, 2, 3, 4, 5].map((star) => (
          <svg
            key={star}
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            className={`w-5 h-5 ${
              star <= (rating || 0) ? "text-yellow-500" : "text-neutral-600"
            }`}
          >
            <path
              fillRule="evenodd"
              d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.007 5.404.433c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.433 2.082-5.006z"
              clipRule="evenodd"
            />
          </svg>
        ))}
        <span className="ml-1 text-neutral-400 text-sm">{rating || 0}/5</span>
      </div>
    );

    const Section = ({
      title,
      children,
      className = "",
    }: {
      title: string;
      children: React.ReactNode;
      className?: string;
    }) => (
      <div className={`p-4 sm:p-6 border-b border-neutral-700 ${className}`}>
        <h2 className="text-white text-lg font-semibold mb-3 sm:mb-4">{title}</h2>
        {children}
      </div>
    );

    const TagList = ({ items }: { items: string[] }) => (
      <div className="flex flex-wrap gap-2">
        {(items || []).map((item, index) => (
          <span
            key={index}
            className="px-3 py-1 bg-neutral-900 text-white text-sm rounded-full"
          >
            {item || ""}
          </span>
        ))}
      </div>
    );

    const ReportHeader = () => (
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-3">
          <Link
            href="/report"
            className="bg-neutral-800 hover:bg-neutral-700 p-2 rounded-full transition-colors"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-5 w-5 text-white"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M10 19l-7-7m0 0l7-7m-7 7h18"
              />
            </svg>
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-white">Vehicle Inspection Report</h1>
            <p className="text-neutral-400 text-sm">
              ID: {sessionId}
            </p>
          </div>
        </div>
        <div className="flex gap-2">
          <button 
            onClick={() => window.print()}
            className="flex items-center gap-2 bg-neutral-800 hover:bg-neutral-700 px-4 py-2 rounded-md text-white transition-colors"
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
                d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
              />
            </svg>
            Print
          </button>
        </div>
      </div>
    );

    return (
      <div className="p-8">
        <ReportHeader />

        {activeImageUrl && (
          <ImageModal
            url={activeImageUrl}
            onClose={() => setActiveImageUrl(null)}
          />
        )}

        <div
          ref={reportRef}
          className="bg-neutral-800 border border-neutral-700 rounded-lg overflow-hidden shadow-lg"
        >
          <Section title="">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 sm:gap-4">
              <div>
                <div className="flex items-center mb-2">
                  <h1 className="text-white text-xl sm:text-2xl font-bold">
                    Vehicle Inspection Report
                  </h1>
                </div>
                <p className="text-neutral-400 text-xs sm:text-sm mt-1">
                  Report ID: {safeAccess(report, "id", "")}
                </p>
                <p className="text-neutral-400 text-xs sm:text-sm">
                  Created on {formatDate(safeAccess(report, "createdAt", ""))}
                </p>
              </div>
              <div className="bg-neutral-900 px-3 py-2 sm:px-4 sm:py-3 rounded-md mt-2 sm:mt-0">
                <p className="text-neutral-400 text-xs sm:text-sm">
                  Condition Rating
                </p>
                <RatingDisplay
                  rating={safeAccess(report, "conditionRating", 0) as number}
                />
              </div>
            </div>
          </Section>

          <Section title="Client Information">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3 sm:gap-6">
              <div>
                <p className="text-neutral-400 text-xs sm:text-sm">Name</p>
                <p className="text-white font-medium text-sm sm:text-base">
                  {safeAccess(report, "clientData.name", "") as string}
                </p>
              </div>
              <div>
                <p className="text-neutral-400 text-xs sm:text-sm">Phone</p>
                <p className="text-white font-medium text-sm sm:text-base">
                  {safeAccess(report, "clientData.phone", "") as string}
                </p>
              </div>
              <div>
                <p className="text-neutral-400 text-xs sm:text-sm">Location</p>
                <p className="text-white font-medium text-sm sm:text-base">
                  {safeAccess(report, "clientData.address.city", "") as string}
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
          </Section>

          <Section title="Vehicle Information">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3 sm:gap-6">
              <div>
                <p className="text-neutral-400 text-xs sm:text-sm">
                  Make/Model
                </p>
                <p className="text-white font-medium text-sm sm:text-base">
                  {safeAccess(report, "carData.make", "") as string}{" "}
                  {safeAccess(report, "carData.model", "") as string}
                </p>
              </div>
              <div>
                <p className="text-neutral-400 text-xs sm:text-sm">Year</p>
                <p className="text-white font-medium text-sm sm:text-base">
                  {safeAccess(report, "carData.year", "") as string}
                </p>
              </div>
              <div>
                <p className="text-neutral-400 text-xs sm:text-sm">
                  Plate Number
                </p>
                <p className="text-white font-medium text-sm sm:text-base">
                  {safeAccess(report, "carData.plateNumber", "") as string}
                </p>
              </div>
              <div>
                <p className="text-neutral-400 text-xs sm:text-sm">VIN</p>
                <p className="text-white font-medium text-sm sm:text-base">
                  {safeAccess(report, "carData.vin", "") as string}
                </p>
              </div>
            </div>
          </Section>

          <Section title="Inspection Findings">
            {(safeAccess(report, "inspectionFindings", []) as string[]).length >
              0 && (
              <>
                <h3 className="text-white font-medium text-sm sm:text-base mb-2">
                  Issues Found
                </h3>
                <TagList
                  items={
                    safeAccess(report, "inspectionFindings", []) as string[]
                  }
                />
              </>
            )}

            {safeAccess(report, "inspectionNotes", "") && (
              <div className="mt-4">
                <h3 className="text-white font-medium text-sm sm:text-base mb-2">
                  Technician Notes
                </h3>
                <div className="bg-neutral-900 p-3 sm:p-4 rounded-md text-neutral-300 text-sm sm:text-base">
                  <p>{safeAccess(report, "inspectionNotes", "") as string}</p>
                </div>
              </div>
            )}

            {(safeAccess(report, "inspectionImages", []) as string[]).length >
              0 && (
              <div className="mt-4">
                <h3 className="text-white font-medium text-sm sm:text-base mb-2">
                  Inspection Images
                </h3>
                <ImageGallery
                  images={
                    safeAccess(report, "inspectionImages", []) as string[]
                  }
                />
              </div>
            )}
          </Section>

          <Section title="Client Requests and Notes">
            {(safeAccess(report, "clientRequests", []) as string[]).length >
              0 && (
              <div className="mb-4">
                <h3 className="text-white font-medium text-sm sm:text-base mb-2">
                  Client Requests
                </h3>
                <TagList
                  items={safeAccess(report, "clientRequests", []) as string[]}
                />
              </div>
            )}

            {safeAccess(report, "clientNotes", "") && (
              <div className="mt-4">
                <h3 className="text-white font-medium text-sm sm:text-base mb-2">
                  Client Notes
                </h3>
                <div className="bg-neutral-900 p-3 sm:p-4 rounded-md text-neutral-300 text-sm sm:text-base">
                  <p>{safeAccess(report, "clientNotes", "") as string}</p>
                </div>
              </div>
            )}

            {(safeAccess(report, "clientNotesImages", []) as string[]).length >
              0 && (
              <div className="mt-4">
                <h3 className="text-white font-medium text-sm sm:text-base mb-2">
                  Client Provided Images
                </h3>
                <ImageGallery
                  images={
                    safeAccess(report, "clientNotesImages", []) as string[]
                  }
                />
              </div>
            )}
          </Section>

          <Section title="Test Drive Results">
            {safeAccess(report, "testDriveNotes", "") && (
              <div className="mb-4">
                <h3 className="text-white font-medium text-sm sm:text-base mb-2">
                  Test Drive Notes
                </h3>
                <div className="bg-neutral-900 p-3 sm:p-4 rounded-md text-neutral-300 text-sm sm:text-base">
                  <p>{safeAccess(report, "testDriveNotes", "") as string}</p>
                </div>
              </div>
            )}

            {(safeAccess(report, "testDriveObservations", []) as string[])
              .length > 0 && (
              <div className="mt-4">
                <h3 className="text-white font-medium text-sm sm:text-base mb-2">
                  Observations
                </h3>
                <TagList
                  items={
                    safeAccess(report, "testDriveObservations", []) as string[]
                  }
                />
              </div>
            )}

            {(safeAccess(report, "testDriveImages", []) as string[]).length >
              0 && (
              <div className="mt-4">
                <h3 className="text-white font-medium text-sm sm:text-base mb-2">
                  Test Drive Images
                </h3>
                <ImageGallery
                  images={safeAccess(report, "testDriveImages", []) as string[]}
                />
              </div>
            )}
          </Section>

          <Section title="Conclusion">
            {safeAccess(report, "recommendations", "") && (
              <div className="mb-4">
                <h3 className="text-white font-medium text-sm sm:text-base mb-2">
                  Recommendations
                </h3>
                <div className="bg-neutral-900 p-3 sm:p-4 rounded-md text-neutral-300 text-sm sm:text-base">
                  <p>{safeAccess(report, "recommendations", "") as string}</p>
                </div>
              </div>
            )}

            {safeAccess(report, "summary", "") && (
              <div className="mt-4">
                <h3 className="text-white font-medium text-sm sm:text-base mb-2">
                  Summary
                </h3>
                <div className="bg-neutral-900 p-3 sm:p-4 rounded-md text-neutral-300 text-sm sm:text-base">
                  <p>{safeAccess(report, "summary", "") as string}</p>
                </div>
              </div>
            )}
          </Section>
        </div>
      </div>
    );
  };

  return <AppLayout>{renderContent()}</AppLayout>;
}
