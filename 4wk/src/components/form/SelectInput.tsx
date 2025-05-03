"use client";

import React, { forwardRef, SelectHTMLAttributes } from 'react';

interface SelectOption {
  value: string;
  label: string;
}

interface SelectInputProps extends Omit<SelectHTMLAttributes<HTMLSelectElement>, 'size'> {
  label?: string;
  options: SelectOption[];
  error?: string;
  helpText?: string;
  fullWidth?: boolean;
  size?: 'sm' | 'md' | 'lg';
  placeholder?: string;
}

const SelectInput = forwardRef<HTMLSelectElement, SelectInputProps>(
  ({ 
    label, 
    options, 
    error, 
    helpText, 
    className = "", 
    fullWidth = true,
    size = 'md',
    placeholder,
    ...props 
  }, ref) => {
    
    const sizeClasses = {
      sm: 'px-3 py-1.5 text-sm',
      md: 'px-4 py-3',
      lg: 'px-5 py-4 text-lg'
    };
    
    const selectClasses = `${sizeClasses[size]} rounded-md border ${
      error
        ? "border-red-500 focus:ring-red-500"
        : "border-neutral-700 focus:ring-red-500"
    } bg-neutral-900 text-white placeholder-neutral-500 focus:outline-none focus:ring-1 ${
      fullWidth ? "w-full" : ""
    } appearance-none pr-10 ${className}`;

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
        
        <div className="relative">
          <select ref={ref} className={selectClasses} {...props}>
            {placeholder && (
              <option value="" disabled>
                {placeholder}
              </option>
            )}
            {options.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          
          <div className="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none">
            <svg 
              className="w-5 h-5 text-neutral-500" 
              xmlns="http://www.w3.org/2000/svg" 
              viewBox="0 0 20 20" 
              fill="currentColor"
            >
              <path 
                fillRule="evenodd" 
                d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" 
                clipRule="evenodd" 
              />
            </svg>
          </div>
        </div>
        
        {error && <p className="mt-1 text-xs text-red-500">{error}</p>}
        {helpText && !error && (
          <p className="mt-1 text-xs text-neutral-500">{helpText}</p>
        )}
      </div>
    );
  }
);

SelectInput.displayName = "SelectInput";

export default SelectInput;