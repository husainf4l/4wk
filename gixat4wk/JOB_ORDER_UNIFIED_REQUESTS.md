# Job Orders Unified Request Structure

## Overview

Updated the job order system to use the same request structure as session activities (client notes, inspection, test drive, report) while adding job order-specific fields for enhanced tracking and management.

## Changes Made

### 1. Unified Request Structure

All requests now use a consistent structure across session activities and job orders:

```dart
{
  // Universal request fields
  'id': 'unique_identifier',
  'request': 'The request text/description',
  'argancy': 'low|medium|high|urgent', // Renamed from 'priority'

  // Job order specific fields
  'jobOrderStatus': 'pending|in_progress|completed|cancelled',
  'jobOrderNotes': 'Additional notes for job order context',
  'assignedTo': 'Technician or team member name',
  'estimatedHours': 'Estimated completion time',
  'price': 'Cost in AED',

  // Backward compatibility
  'isDone': true/false, // Computed from jobOrderStatus

  // Source information
  'source': 'session|client_request|inspection_finding|test_drive_observation|manual',
  'sourceStage': 'clientnotes|inspection|testdrive|report|jobcard',
  'timestamp': 'ISO8601 timestamp',
}
```

### 2. Enhanced UI Features

#### Job Orders Screen

- **Enhanced request cards** with urgency indicators
- **Source badges** showing where each request originated (Client Notes, Inspection, etc.)
- **Status indicators** with color coding
- **Job order notes** display for additional context
- **Assignment information** (who's working on it)
- **Time estimates** and pricing information

#### Job Order Request History Screen

- **Detailed request view** with all metadata
- **Interactive status toggle** for marking tasks complete
- **Urgency-based color coding** on borders and badges
- **Source tracking** showing which session stage generated each request
- **Job order specific information** like assignments, estimates, and pricing

### 3. Backend Updates

#### Unified Session Service

- Updated `_createJobOrderFromJobCard()` to use unified structure
- All new job orders will use the consistent request format
- Automatic population of source information

#### Unified Session Activity Controller

- Enhanced `addQuickRequest()` to include source metadata
- Job order fields are pre-initialized for future use

### 4. Benefits

1. **Consistency**: Same request structure across all parts of the app
2. **Traceability**: Can track where each request originated
3. **Enhanced Workflow**: Job order specific fields for better management
4. **Backward Compatibility**: Existing data continues to work
5. **Future-Proof**: Structure supports additional metadata

### 5. Migration Notes

The system handles backward compatibility automatically:

- Old `title` fields are mapped to `request`
- Old `priority` fields are mapped to `argancy`
- Old `notes` fields are mapped to `jobOrderNotes`
- Missing fields get sensible defaults

### 6. Request Sources

Requests can now originate from:

- **Client Notes**: Direct client requests and observations
- **Inspection**: Issues found during vehicle inspection
- **Test Drive**: Problems discovered during test driving
- **Report**: Items from the final report
- **Job Card**: Manual additions or modifications
- **Manual**: Direct additions in job orders

### 7. Status Flow

Job order requests follow this status flow:

1. **pending**: Initially created, waiting to be started
2. **in_progress**: Currently being worked on
3. **completed**: Task finished successfully
4. **cancelled**: Task cancelled or no longer needed

This unified approach ensures better consistency across your 4WK vehicle service management system while maintaining all existing functionality and adding powerful new features for job order management.
