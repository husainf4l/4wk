"use client";

import React, { InputHTMLAttributes, forwardRef } from 'react';

interface FormInputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helpText?: string;
  fullWidth?: boolean;
}

const FormInput = forwardRef<HTMLInputElement, FormInputProps>(
  ({ label, error, helpText, className = "", fullWidth = true, ...props }, ref) => {
    const inputClasses = `px-4 py-3 rounded-md border ${
      error
        ? "border-red-500 focus:ring-red-500"
        : "border-neutral-700 focus:ring-red-500"
    } bg-neutral-900 text-white placeholder-neutral-500 focus:outline-none focus:ring-1 ${
      fullWidth ? "w-full" : ""
    } ${className}`;

    return (
      <div className={fullWidth ? "w-full" : ""}>
        {label && (
          <label
            htmlFor={props.id}
            className="block text-sm text-neutral-400 font-medium mb-1"
          >
            {label}
          </label>
        )}
        
        <input ref={ref} className={inputClasses} {...props} />
        
        {error && <p className="mt-1 text-xs text-red-500">{error}</p>}
        {helpText && !error && (
          <p className="mt-1 text-xs text-neutral-500">{helpText}</p>
        )}
      </div>
    );
  }
);

FormInput.displayName = "FormInput";

export default FormInput;