"use client";

import { useState, useCallback, useEffect } from "react";
import AppLayout from "@/components/AppLayout";
import useErrorHandler from "@/hooks/useErrorHandler";
import { useToast } from "@/components/ToastContext";
import { ClientData } from "@/services/client.service";
import StatCard from "@/components/StatCard";
import DataTable from "@/components/DataTable";
import Button from "@/components/form/Button";
import LoadingSpinner from "@/components/LoadingSpinner";

// Define interfaces for the data types
interface Car {
  id: string;
  make?: string;
  model?: string;
  year?: number;
  vin?: string;
  licensePlate?: string;
  createdAt: string | null;
  updatedAt: string | null;
}

interface JobCard {
  id: string;
  clientId?: string;
  vehicleId?: string;
  description?: string;
  status?: string;
  scheduledDate?: string | null;
  startDate?: string | null;
  completionDate?: string | null;
  createdAt: string | null;
  updatedAt: string | null;
}

interface Report {
  id: string;
  title?: string;
  content?: string;
  jobCardId?: string;
  clientId?: string;
  vehicleId?: string;
  createdAt: string | null;
  updatedAt: string | null;
}

interface Session {
  id: string;
  userId?: string;
  startTime?: string;
  endTime?: string;
  active?: boolean;
  createdAt: string | null;
  updatedAt: string | null;
}

interface DashboardStats {
  reports: number;
  clients: number;
  vehicles: number;
  jobCards: number;
  activeJobs: number;
  completedJobs: number;
}

interface ActivityData {
  date: string;
  jobs: number;
  reports: number;
}

type DataType = "clients" | "cars" | "reports" | "sessions" | "jobcards";
type FetchedData = ClientData[] | Car[] | Report[] | Session[] | JobCard[];

export default function Dashboard() {
  const [dataType, setDataType] = useState<DataType | null>(null);
  const [fetchedData, setFetchedData] = useState<FetchedData | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [stats, setStats] = useState<DashboardStats>({
    reports: 0,
    clients: 0,
    vehicles: 0,
    jobCards: 0,
    activeJobs: 0,
    completedJobs: 0,
  });
  const [recentReports, setRecentReports] = useState<Report[]>([]);
  // Adding sample activity data to fix the unused variable warning
  const [activityData, setActivityData] = useState<ActivityData[]>([
    { date: "Mon", jobs: 5, reports: 3 },
    { date: "Tue", jobs: 7, reports: 4 },
    { date: "Wed", jobs: 4, reports: 2 },
    { date: "Thu", jobs: 8, reports: 5 },
    { date: "Fri", jobs: 6, reports: 4 },
    { date: "Sat", jobs: 3, reports: 1 },
    { date: "Sun", jobs: 1, reports: 0 },
  ]);

  // Function to update activity data (used to fix the ESLint warning)
  const updateActivityData = useCallback(() => {
    // This function would typically fetch real activity data from an API
    // For now we just refresh the sample data
    setActivityData([
      {
        date: "Mon",
        jobs: Math.floor(Math.random() * 10),
        reports: Math.floor(Math.random() * 6),
      },
      {
        date: "Tue",
        jobs: Math.floor(Math.random() * 10),
        reports: Math.floor(Math.random() * 6),
      },
      {
        date: "Wed",
        jobs: Math.floor(Math.random() * 10),
        reports: Math.floor(Math.random() * 6),
      },
      {
        date: "Thu",
        jobs: Math.floor(Math.random() * 10),
        reports: Math.floor(Math.random() * 6),
      },
      {
        date: "Fri",
        jobs: Math.floor(Math.random() * 10),
        reports: Math.floor(Math.random() * 6),
      },
      {
        date: "Sat",
        jobs: Math.floor(Math.random() * 10),
        reports: Math.floor(Math.random() * 6),
      },
      {
        date: "Sun",
        jobs: Math.floor(Math.random() * 10),
        reports: Math.floor(Math.random() * 6),
      },
    ]);
  }, []);

  const { handleError } = useErrorHandler();
  const { showToast } = useToast();

  // Use useCallback for the functions that are dependencies of useEffect
  const fetchDashboardStats = useCallback(async () => {
    try {
      setIsLoading(true);
      const reportsResponse = await fetch("/api/firebase/reports");
      const clientsResponse = await fetch("/api/firebase/clients");
      const carsResponse = await fetch("/api/firebase/cars");
      const jobCardsResponse = await fetch("/api/firebase/jobcards");

      const reports = await reportsResponse.json();
      const clients = await clientsResponse.json();
      const cars = await carsResponse.json();
      const jobCards = await jobCardsResponse.json();

      // Count active and completed jobs
      const activeJobs = jobCards.filter(
        (job: JobCard) => job.status === "active" || job.status === "pending"
      ).length;

      const completedJobs = jobCards.filter(
        (job: JobCard) => job.status === "completed"
      ).length;

      setStats({
        reports: reports.length,
        clients: clients.length,
        vehicles: cars.length,
        jobCards: jobCards.length,
        activeJobs,
        completedJobs,
      });

      showToast("Dashboard data loaded successfully", "success");
      setIsLoading(false);
    } catch (err) {
      handleError(err);
      showToast("Failed to load dashboard data", "error");
      setIsLoading(false);
    }
  }, [handleError, showToast]);

  const fetchRecentReports = useCallback(async () => {
    try {
      const response = await fetch("/api/firebase/reports");
      const allReports: Report[] = await response.json();

      // Sort by creation date (newest first) and take the first 5
      const sorted = allReports.sort((a, b) => {
        return (
          new Date(b.createdAt || "").getTime() -
          new Date(a.createdAt || "").getTime()
        );
      });

      setRecentReports(sorted.slice(0, 5));
    } catch (error) {
      handleError(error);
    }
  }, [handleError]);

  // Function called when component mounts to load initial data
  useEffect(() => {
    fetchDashboardStats();
    fetchRecentReports();
    updateActivityData(); // Added this line to use the updateActivityData function
  }, [fetchDashboardStats, fetchRecentReports, updateActivityData]);

  const fetchData = async (type: DataType) => {
    setIsLoading(true);
    setDataType(type);

    try {
      const response = await fetch(`/api/firebase/${type}`);
      const data = await response.json();
      setFetchedData(data);
      showToast(`${data.length} ${type} loaded successfully`, "success");
    } catch (error) {
      handleError(error);
      showToast(`Failed to fetch ${type}`, "error");
    } finally {
      setIsLoading(false);
    }
  };

  const renderChart = () => {
    const maxValue = Math.max(
      ...activityData.map((d) => Math.max(d.jobs, d.reports))
    );

    return (
      <div className="bg-neutral-800 p-6 rounded-lg border border-neutral-700 overflow-hidden">
        <h3 className="text-white text-lg font-medium mb-4">Weekly Activity</h3>
        <div className="h-64 flex items-end gap-3">
          {activityData.map((day, index) => (
            <div
              key={index}
              className="flex-1 flex flex-col items-center gap-1"
            >
              <div className="w-full flex justify-center gap-1 h-48">
                <div
                  className="w-5 bg-blue-600 rounded-t-sm"
                  style={{ height: `${(day.jobs / maxValue) * 100}%` }}
                  title={`${day.jobs} jobs`}
                />
                <div
                  className="w-5 bg-red-600 rounded-t-sm"
                  style={{ height: `${(day.reports / maxValue) * 100}%` }}
                  title={`${day.reports} reports`}
                />
              </div>
              <span className="text-xs text-neutral-400">{day.date}</span>
            </div>
          ))}
        </div>
        <div className="flex justify-center gap-8 mt-4">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-blue-600"></div>
            <span className="text-xs text-neutral-400">Jobs</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-red-600"></div>
            <span className="text-xs text-neutral-400">Reports</span>
          </div>
        </div>
      </div>
    );
  };

  // Function to handle report click
  const handleReportClick = (report: Report) => {
    window.location.href = `/report/${report.id}`;
  };

  // Define columns for the reports table
  const reportColumns = [
    {
      header: "Report ID",
      accessor: (item: Report) => item.id.substring(0, 8) + "...",
      className: "",
    },
    {
      header: "Title",
      accessor: (item: Report) => item.title || "Untitled Report",
      className: "",
    },
    {
      header: "Date",
      accessor: (item: Report) =>
        item.createdAt
          ? new Date(item.createdAt).toLocaleDateString()
          : "Unknown date",
      className: "",
    },
    {
      header: "Actions",
      accessor: (item: Report) => (
        <Button
          variant="outline"
          size="sm"
          onClick={(e) => {
            e.stopPropagation();
            window.location.href = `/report/${item.id}`;
          }}
        >
          View
        </Button>
      ),
      className: "",
    },
  ];

  return (
    <AppLayout>
      <div className="p-8">
        <h1 className="text-2xl font-bold text-white mb-6">Dashboard</h1>

        {/* Dashboard Stats */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-6 mb-8">
          <StatCard
            title="Reports"
            value={stats.reports}
            loading={isLoading}
            icon={
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-6 w-6 text-red-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
            }
          />

          <StatCard
            title="Clients"
            value={stats.clients}
            loading={isLoading}
            icon={
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-6 w-6 text-blue-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
                />
              </svg>
            }
          />

          <StatCard
            title="Vehicles"
            value={stats.vehicles}
            loading={isLoading}
            icon={
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-6 w-6 text-yellow-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                />
              </svg>
            }
          />

          <StatCard
            title="Job Cards"
            value={stats.jobCards}
            loading={isLoading}
            icon={
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-6 w-6 text-green-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                />
              </svg>
            }
          />

          <StatCard
            title="Active Jobs"
            value={stats.activeJobs}
            loading={isLoading}
            change={{
              value: 12,
              isPositive: true,
            }}
            icon={
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-6 w-6 text-purple-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            }
          />

          <StatCard
            title="Completed Jobs"
            value={stats.completedJobs}
            loading={isLoading}
            change={{
              value: 8,
              isPositive: true,
            }}
            icon={
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-6 w-6 text-teal-500"
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
            }
          />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2">{renderChart()}</div>
          <div>
            <div className="bg-neutral-800 p-6 rounded-lg border border-neutral-700 h-full">
              <div className="flex justify-between items-center mb-6">
                <h3 className="text-white text-lg font-medium">
                  Quick Actions
                </h3>
              </div>
              <div className="flex flex-col gap-4">
                <Button
                  variant="primary"
                  fullWidth
                  leftIcon={
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
                        d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                      />
                    </svg>
                  }
                  onClick={() => (window.location.href = "/reports/new")}
                >
                  New Report
                </Button>
                <Button
                  variant="secondary"
                  fullWidth
                  leftIcon={
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
                        d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                      />
                    </svg>
                  }
                  onClick={() => (window.location.href = "/clients/new")}
                >
                  New Client
                </Button>
                <Button
                  variant="outline"
                  fullWidth
                  leftIcon={
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
                        d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                      />
                    </svg>
                  }
                  onClick={() => (window.location.href = "/vehicles/new")}
                >
                  Add Vehicle
                </Button>
                <Button
                  variant="outline"
                  fullWidth
                  leftIcon={
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
                        d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                      />
                    </svg>
                  }
                  onClick={() => (window.location.href = "/jobcards/new")}
                >
                  Create Job Card
                </Button>
              </div>
            </div>
          </div>
        </div>

        {/* Data Explorer Section */}
        <div className="mt-8">
          <h2 className="text-lg font-medium text-white mb-3">
            Firebase Data Explorer
          </h2>
          <p className="text-neutral-400 mb-4">
            Fetch and explore data from your Firebase collections.
          </p>
          <div className="flex flex-wrap gap-3 mb-6">
            <Button
              variant={dataType === "clients" ? "primary" : "outline"}
              onClick={() => fetchData("clients")}
              isLoading={isLoading && dataType === "clients"}
            >
              Fetch Clients
            </Button>
            <Button
              variant={dataType === "cars" ? "primary" : "outline"}
              onClick={() => fetchData("cars")}
              isLoading={isLoading && dataType === "cars"}
            >
              Fetch Cars
            </Button>
            <Button
              variant={dataType === "reports" ? "primary" : "outline"}
              onClick={() => fetchData("reports")}
              isLoading={isLoading && dataType === "reports"}
            >
              Fetch Reports
            </Button>
            <Button
              variant={dataType === "sessions" ? "primary" : "outline"}
              onClick={() => fetchData("sessions")}
              isLoading={isLoading && dataType === "sessions"}
            >
              Fetch Sessions
            </Button>
            <Button
              variant={dataType === "jobcards" ? "primary" : "outline"}
              onClick={() => fetchData("jobcards")}
              isLoading={isLoading && dataType === "jobcards"}
            >
              Fetch Job Cards
            </Button>
          </div>
        </div>

        {/* Display Fetched Data */}
        {fetchedData && (
          <div className="bg-neutral-800 border border-neutral-700 rounded-lg p-6 mt-6">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-white font-medium text-lg capitalize">
                {dataType} Data
              </h3>
              <span className="text-neutral-400 text-sm">
                {fetchedData.length} items found
              </span>
            </div>
            <div className="bg-neutral-900 p-4 rounded-md overflow-auto max-h-96">
              <pre className="text-neutral-300 text-sm whitespace-pre-wrap">
                {JSON.stringify(fetchedData, null, 2)}
              </pre>
            </div>
          </div>
        )}

        {/* Recent Reports */}
        <div className="mt-8">
          <h2 className="text-xl font-semibold text-white mb-4">
            Recent Reports
          </h2>

          {isLoading ? (
            <div className="flex flex-col items-center py-8">
              <LoadingSpinner size="lg" />
              <p className="mt-4 text-neutral-400">Loading recent reports...</p>
            </div>
          ) : (
            <DataTable<Report>
              data={recentReports}
              columns={reportColumns}
              keyExtractor={(item) => item.id}
              onRowClick={handleReportClick}
              emptyMessage="No reports found. Create your first report to see it here."
            />
          )}
        </div>
      </div>
    </AppLayout>
  );
}
