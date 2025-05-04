"use client";
import { useRef, useState, useEffect } from "react";
import { updateReportFeedback } from "@/services/firebase.service";
import useErrorHandler from "@/hooks/useErrorHandler";
import { useToast } from "@/components/ToastContext";

export default function ClientFeedbackForm({
  sessionId,
}: {
  sessionId: string;
}) {
  const [clientNotes, setClientNotes] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const { error, handleError } = useErrorHandler();
  const { showToast } = useToast();

  // Check localStorage on component mount to see if this form was already submitted
  useEffect(() => {
    const checkSubmissionStatus = () => {
      const submittedForms = localStorage.getItem("submittedFeedbackForms");
      if (submittedForms) {
        const forms = JSON.parse(submittedForms);
        if (forms.includes(sessionId)) {
          setSubmitted(true);
        }
      }
    };

    checkSubmissionStatus();
    // Removed the autofocus code that was here
  }, [sessionId]);

  // Function to save submission status to localStorage
  const saveSubmissionStatus = () => {
    const submittedForms = localStorage.getItem("submittedFeedbackForms");
    let forms = submittedForms ? JSON.parse(submittedForms) : [];

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
          Thank You!
        </h3>
        <p className="text-neutral-300 text-base text-center max-w-md mb-4">
          Your feedback has been received. We appreciate your input and will use
          it to improve our service.
        </p>
        <div className="text-green-400 font-semibold text-lg mt-2">
          ✔️ Submission Complete
        </div>
      </div>
    );
  }

  return (
    <div className="bg-gradient-to-r from-neutral-800 to-neutral-900 rounded-lg p-5 border border-neutral-700/50">
      <div className="mb-6">
        <h3 className="text-white font-medium text-base sm:text-lg mb-2">
          Your Response
        </h3>
        <p className="text-neutral-400 text-sm">
          Take a look at the issues we've found so far. If you remember anything
          else or have any extra notes -- even small things -- just let us know.
          We're here to make sure everything's covered for you.
        </p>
      </div>
      <div className="mb-6">
        <label
          htmlFor="client-notes"
          className="block text-white font-medium text-sm mb-2"
        >
          Additional Notes
        </label>
        <textarea
          id="client-notes"
          ref={textareaRef}
          className="w-full bg-neutral-800 border border-neutral-700 rounded-md px-4 py-3 text-white placeholder-neutral-500 focus:outline-none focus:ring-2 focus:ring-red-500/50 focus:border-red-500"
          rows={4}
          placeholder="Add any additional requests, questions, or feedback here..."
          value={clientNotes}
          onChange={(e) => setClientNotes(e.target.value)}
        ></textarea>
      </div>
      <div className="flex flex-wrap gap-3 justify-end">
        <button
          onClick={async () => {
            try {
              setSubmitting(true);
              await updateReportFeedback(sessionId, clientNotes);
              setSubmitted(true);
              // Save submission status to localStorage
              saveSubmissionStatus();
              showToast("Feedback submitted successfully!", "success");
            } catch (error) {
              handleError(error);
              showToast(
                "Failed to submit feedback. Please try again.",
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
            <>Submit Notes</>
          )}
        </button>
      </div>
    </div>
  );
}
