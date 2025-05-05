"use client";
import { useState } from "react";
import { updateReportFeedback } from "@/services/firebase.service";
import useErrorHandler from "@/hooks/useErrorHandler";
import { useToast } from "@/components/ToastContext";

export default function ClientFeedbackForm({
  sessionId,
}: {
  sessionId: string;
}) {
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const { handleError } = useErrorHandler();
  const { showToast } = useToast();

  // Check localStorage on component mount to see if this form was already submitted
  const saveSubmissionStatus = () => {
    const submittedForms = localStorage.getItem("submittedFeedbackForms");
    const forms = submittedForms ? JSON.parse(submittedForms) : [];

    if (!forms.includes(sessionId)) {
      forms.push(sessionId);
      localStorage.setItem("submittedFeedbackForms", JSON.stringify(forms));
    }
  };

  if (submitted) {
    return (
      <div className="flex flex-col items-center justify-center py-12">
        <div className="w-20 h-20 rounded-full bg-green-700/20 flex items-center justify-center mb-6 shadow-lg">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-12 w-12 text-green-500"
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
        <h3 className="text-white text-2xl font-bold mb-2 text-center">
          Marked as Seen
        </h3>
        <p className="text-neutral-300 text-base text-center max-w-md mb-4">
          This report has been marked as seen.
        </p>
      </div>
    );
  }

  return (
    <div className="">
      <div className="flex justify-center">
        <button
          onClick={async () => {
            try {
              setSubmitting(true);
              await updateReportFeedback(sessionId, "Mark as seen");
              setSubmitted(true);
              // Save submission status to localStorage
              saveSubmissionStatus();
              showToast("Report marked as seen!", "success");
            } catch (error) {
              handleError(error);
              showToast(
                "Failed to mark report as seen. Please try again.",
                "error"
              );
            } finally {
              setSubmitting(false);
            }
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
            <>Mark as Seen</>
          )}
        </button>
      </div>
    </div>
  );
}
