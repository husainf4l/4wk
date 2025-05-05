"use client";

import { useParams } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { useEffect, useState, useRef, useCallback } from "react";
import { ReportData, getReportBySessionId } from "@/services/firebase.service";
import useErrorHandler from "@/hooks/useErrorHandler";
import { useToast } from "@/components/ToastContext";
import ClientFeedbackForm from "@/components/form/ClientFeedbackForm";
import PasswordPrompt from "@/components/PasswordPrompt";

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

  // Password protection state
  const [isPasswordProtected, setIsPasswordProtected] = useState(false);
  const [passwordError, setPasswordError] = useState(false);

  const reportRef = useRef<HTMLDivElement>(null);
  const { error, handleError } = useErrorHandler();
  const { showToast } = useToast();

  // Use useCallback to memoize functions used in useEffect
  const checkReportAccess = useCallback(async () => {
    setLoading(true);
    try {
      const reportData = await getReportBySessionId(sessionId);

      // If we got back a report with passwordProtected flag
      if (reportData && "passwordProtected" in reportData) {
        setIsPasswordProtected(true);
        setLoading(false);
      } else if (reportData) {
        // No password required, got full report
        setReport(reportData);
        setLoading(false);
        showToast("Report loaded successfully", "success");
      } else {
        handleError(
          "No report found with this session ID. Please check and try again."
        );
        setLoading(false);
      }
    } catch (err) {
      handleError(err);
      showToast("Failed to load report", "error");
      setLoading(false);
    }
  }, [sessionId, handleError, showToast]);

  const fetchReport = useCallback(
    async (password?: string) => {
      try {
        setLoading(true);
        const reportData = await getReportBySessionId(sessionId, password);

        // Check if the report is password protected
        if (reportData && "passwordProtected" in reportData) {
          setIsPasswordProtected(true);
          setPasswordError(!!password); // If password was provided but we still get passwordProtected, it was wrong
          setLoading(false);
          return;
        }

        // If we got a full report back
        setReport(reportData);
        // Clear password protection state when we get full report data
        setIsPasswordProtected(false);

        if (!reportData) {
          handleError(
            "No report found with this session ID. Please check and try again."
          );
        } else {
          // Save authentication state in session storage
          if (password) {
            sessionStorage.setItem(`report_auth_${sessionId}`, "authenticated");
          }

          showToast("Report loaded successfully", "success");
        }
      } catch (err) {
        handleError(err);
        showToast("Failed to load report", "error");
      } finally {
        setLoading(false);
      }
    },
    [sessionId, handleError, showToast]
  );

  useEffect(() => {
    // Check if the user is already authenticated for this report
    const authStatus = sessionStorage.getItem(`report_auth_${sessionId}`);
    if (authStatus === "authenticated") {
      fetchReport(undefined);
    } else {
      // Just check if the report exists and if it needs a password
      checkReportAccess();
    }
  }, [sessionId, checkReportAccess, fetchReport]);

  const handlePasswordSubmit = (password: string) => {
    setPasswordError(false);
    fetchReport(password);
  };

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

  const ClientRequestList = ({ items }: { items: RequestItem[] }) => (
    <div className="flex flex-col space-y-2 sm:space-y-3 w-full">
      {(items || []).map((item, index) => (
        <div
          key={index}
          className="border-l-4 border-red-500  rounded-md overflow-hidden bg-gradient-to-r from-red-900/10 to-neutral-900 shadow-md"
        >
          <div className="flex justify-between items-center p-0.5">
            <div className="flex items-center flex-1">
              <div className="p-2 rounded-full mr-3 ml-2"></div>
              <div className="flex-1">
                <p className="text-white font-medium text-sm sm:text-base">
                  {item.request}
                </p>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );

  // Updated FindingsList component to match Client Requests style (with red border and no icons)
  const FindingsList = ({ items }: { items: FindingItem[] }) => (
    <div className="flex flex-col space-y-2 sm:space-y-3 w-full">
      {(items || []).map((item, index) => (
        <div
          key={index}
          className="border-l-4 border-red-500 rounded-md overflow-hidden bg-gradient-to-r from-red-900/10 to-neutral-900 shadow-md"
        >
          <div className="flex justify-between items-center p-0.5">
            <div className="flex items-center flex-1">
              <div className="flex-1 ml-5">
                <p className="text-white font-medium text-sm sm:text-base">
                  {item.finding}
                </p>
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

  // Updated ObservationsList component to match Client Requests style (with red border and no icons)
  const ObservationsList = ({ items }: { items: ObservationItem[] }) => (
    <div className="flex flex-col space-y-2 sm:space-y-3 w-full">
      {(items || []).map((item, index) => (
        <div
          key={index}
          className="border-l-4 border-red-500 rounded-md overflow-hidden bg-gradient-to-r from-red-900/10 to-neutral-900 shadow-md"
        >
          <div className="flex justify-between items-center p-0.5">
            <div className="flex items-center flex-1">
              <div className="flex-1 ml-5">
                <p className="text-white font-medium text-sm sm:text-base">
                  {item.observation}
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
    // Show password prompt if the report is password protected
    if (isPasswordProtected) {
      return (
        <PasswordPrompt onSubmit={handlePasswordSubmit} error={passwordError} />
      );
    }

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

    const ReportHeader = () => (
      <div className="mb-6 sm:mb-8">
        <div className="flex flex-col sm:flex-row sm:items-center gap-4 sm:gap-6 mb-4 sm:mb-6">
          {/* Mobile view (centered logo and title on separate line) */}
          <div className="flex flex-col items-center sm:hidden w-full">
            <div className=" mb-3">
              <Image
                src="/4wk.png"
                alt="4WK Logo"
                width={192}
                height={24}
                quality={100}
                className="rounded-md"
              />
            </div>
            <h1 className="text-xl font-bold text-white text-center">
              Initial Vehicle Report
            </h1>
            <p className="text-neutral-400 text-xs mt-1 text-center">
              <span className="inline-flex items-center bg-neutral-800/80 px-2 py-1 rounded text-xs mr-2">
                ID: {sessionId.substring(0, 6)}...
              </span>
              {formatDate(safeAccess(report, "createdAt", ""))}
            </p>
          </div>

          {/* Desktop view (original layout) */}
          <div className="hidden sm:flex sm:items-center">
            <div className="p-3 rounded-lg  mr-4">
              <Image
                src="/4wk.png"
                alt="4WK Logo"
                width={192}
                height={24}
                quality={100}
                className="rounded-md"
              />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-white">
                Initial Vehicle Report
              </h1>
              <p className="text-neutral-400 text-sm mt-1">
                <span className="inline-flex items-center bg-neutral-800/80 px-2 py-1 rounded text-xs mr-2">
                  ID: {sessionId.substring(0, 6)}...
                </span>
                <span className="inline">Generated on</span>{" "}
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
      <div className="p-2 sm:p-6 md:p-8">
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
            <div className="space-y-8 px-3 sm:px-5">
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
                    <p className="text-neutral-400 text-xs mb-1">Mileage</p>
                    <p className="text-white font-medium text-sm">
                      {safeAccess(report, "mileage", "") as string} km
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

          <Section title="Vehicle Notes">
            <div className="bg-neutral-900/30 rounded-lg p-5">
              {(safeAccess(report, "clientNotesImages", []) as string[])
                .length > 0 && (
                <div>
                  <h3 className="text-white font-medium text-sm sm:text-base mb-3 border-b border-neutral-700 pb-2">
                    Vehicle Images
                  </h3>
                  <ImageGallery
                    images={
                      safeAccess(report, "clientNotesImages", []) as string[]
                    }
                  />
                </div>
              )}
              {safeAccess(report, "clientNotes", "") && (
                <div className="mb-5">
                  <div className="bg-neutral-900 p-3 sm:p-4 rounded-md text-neutral-300 text-sm mt-2">
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
                  <ClientRequestList
                    items={
                      safeAccess(report, "clientRequests", []) as RequestItem[]
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
                  <FindingsList
                    items={
                      safeAccess(
                        report,
                        "inspectionFindings",
                        []
                      ) as FindingItem[]
                    }
                  />
                </div>
              )}

              {safeAccess(report, "inspectionNotes", "") && (
                <div className="mb-5">
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
                  <ObservationsList
                    items={
                      safeAccess(
                        report,
                        "testDriveObservations",
                        []
                      ) as ObservationItem[]
                    }
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

                  <div className="mt-10 flex flex-row justify-between">
                    <div />
                    <ClientFeedbackForm sessionId={sessionId} />
                  </div>
                </div>
              )}
            </div>
          </Section>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-neutral-900 bg-[radial-gradient(circle_at_center,rgba(120,120,120,0.05)_1px,transparent_1px)] bg-[length:24px_24px]">
      <main className="container mx-auto max-w-5xl sm:px-6 py-4 sm:py-8">
        {renderContent()}
      </main>
    </div>
  );
}
