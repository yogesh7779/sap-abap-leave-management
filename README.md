# SAP ABAP Cloud – Employee Leave Management

A beginner-friendly SAP ABAP Cloud learning project that demonstrates how fundamental ABAP programming concepts can be extended into a simple end-to-end business application using **ABAP SQL, CDS, RAP, OData V4, and SAP Fiori Elements**.

This project was built as a practical application of concepts learned through SAP's **Learning Basic ABAP Programming** course.

> **Note:** This is a learning and portfolio project, not a production-ready enterprise HR solution. The goal was to understand how different SAP development concepts work together in a complete application.

---

## 📌 Project at a Glance

| Area | Implementation |
|---|---|
| Platform | SAP BTP ABAP Environment |
| Language | ABAP |
| Database | ABAP Database Tables |
| Data Modeling | Core Data Services (CDS) |
| Business Logic | RESTful Application Programming Model (RAP) |
| API | OData V4 |
| User Interface | SAP Fiori Elements |
| Development Tool | Eclipse with ABAP Development Tools (ADT) |
| Version Control | Git + GitHub |
| Repository Integration | abapGit |

---

## 🎯 Project Overview

The application models a simple **Employee Leave Management** process.

Employee master data is stored in one database table, while leave requests are stored separately. A leave request is validated, the number of leave days is calculated automatically, and the request receives an initial status of `SUBMITTED`.

A submitted request can then be:

- **Approved** → `APPROVED`
- **Rejected** → `REJECTED`

Business rules prevent invalid state changes, such as approving an already rejected request or rejecting an already approved request.

### Application Flow

```text
Employee Master Data
        |
        v
Create Leave Request
        |
        v
Validate Employee / Leave Data / Dates
        |
        v
Calculate Number of Days
        |
        v
Initial Status = SUBMITTED
        |
        v
     SUBMITTED
       /    \
      /      \
 APPROVE    REJECT
    |          |
    v          v
APPROVED    REJECTED
```

---

## 🏗️ Application Architecture

The project follows a simple layered architecture:

```text
+--------------------------------------+
|          SAP Fiori Elements          |
|          User Interface              |
+------------------+-------------------+
                   |
                   v
+--------------------------------------+
|              OData V4               |
|       Service Definition/Binding     |
+------------------+-------------------+
                   |
                   v
+--------------------------------------+
|               RAP                    |
| Behavior Definition + Implementation |
| Validations + Determinations         |
| Approve / Reject Actions             |
+------------------+-------------------+
                   |
                   v
+--------------------------------------+
|               CDS                    |
|      Employee + Leave Request        |
|             Data Model               |
+------------------+-------------------+
                   |
                   v
+--------------------------------------+
|          Database Tables             |
| Employee Master + Leave Requests     |
+--------------------------------------+
```

---

## 🗂️ SAP Development Objects

The main objects created for the project are:

| Object | Type | Purpose |
|---|---|---|
| `ZEMPLOYEE__TABLE` | Database Table | Stores employee master data |
| `ZLEAVE_REQ_TABLE` | Database Table | Stores leave request data |
| `ZI_EMPLOYEE_` | CDS View Entity | Exposes employee master data |
| `ZI_LEAVE_REQUEST_` | CDS Root View Entity | Exposes leave request data |
| `ZI_LEAVE_REQUEST_` | Behavior Definition | Defines RAP business behavior |
| `ZBP_I_LEAVE_REQUEST_` | Behavior Implementation | Implements RAP business logic |
| `ZC_LEAVE_REQUEST_MDE` | Metadata Extension | Defines Fiori Elements UI annotations |
| `ZUI_LEAVE_MANAGEMENT` | Service Definition | Defines the data exposed by the service |
| `ZUI_LEAVE_MANAGEMENT_O4` | Service Binding | Exposes the application through OData V4 |
| `ZCL_LEAVE_APP` | ABAP Class | Demonstrates ABAP programming and database operations |
| `ZCL_LEAVE_RAP_TEST` | ABAP Class | Tests RAP create and action scenarios |

---

## 👨‍💻 ABAP Programming

The initial application logic was developed in:

`ZCL_LEAVE_APP`

This class was used to practice fundamental ABAP concepts before moving into the RAP-based application.

### Concepts demonstrated

- ABAP classes and methods
- Structures and local types
- Internal tables
- `APPEND VALUE`
- `LOOP AT`
- Conditional statements
- Method-based validation
- Data transformation
- ABAP SQL
- Database `INSERT`
- Database `SELECT`
- `SELECT SINGLE`
- Date calculations
- String templates
- `sy-subrc`
- Database persistence

The employee data is initially prepared in ABAP and then persisted into the employee database table.

The application also reads persisted employee data back from the database for validation and processing.

---

## 🗄️ Database Design

Two database tables are used.

### Employee Master Data

`ZEMPLOYEE__TABLE`

Stores:

- Employee ID
- First Name
- Last Name
- Department
- Email

Example data:

```text
EMP001   Rahul   Kumar    IT
EMP002   Priya   Sharma   Finance
EMP003   Arjun   Kumar    HR
```

### Leave Request Data

`ZLEAVE_REQ_TABLE`

Stores:

- Request ID
- Employee ID
- Leave Type
- Start Date
- End Date
- Number of Days
- Reason
- Status

Example:

```text
Request ID      : LR001
Employee ID     : EMP001
Leave Type      : ANNUAL
Start Date      : 2026-09-15
End Date        : 2026-09-17
Number of Days  : 3
Reason          : Family Function
Status          : SUBMITTED
```

Separating employee master data and leave request data demonstrates the difference between master data and transactional data.

---

## 🔎 Validation

The application contains basic business validations.

### Employee Validation

Before processing a leave request, the employee ID is checked against the persisted employee data.

```text
Employee exists?
      |
   +--+--+
   |     |
  YES    NO
   |     |
Continue Error
```

### Leave Type Validation

The leave type is validated before the request continues.

### Date Validation

The start date cannot be later than the end date.

Valid:

```text
Start Date : 2026-09-15
End Date   : 2026-09-17
```

Invalid:

```text
Start Date : 2026-09-20
End Date   : 2026-09-17
```

The RAP validation returns an error such as:

```text
Start date cannot be after end date
```

This prevents invalid leave requests from being saved.

---

## 📅 Automatic Leave Day Calculation

The application calculates the number of leave days automatically from the start and end dates.

The calculation is inclusive:

```text
Number of Days = End Date - Start Date + 1
```

For example:

```text
15 Sep 2026 → 17 Sep 2026

17 - 15 + 1 = 3 days
```

This logic is implemented as a RAP determination called:

`calculateLeaveDays`

The user does not need to manually enter the number of days.

---

## ⚙️ RAP Business Behavior

The project uses the **RESTful Application Programming Model (RAP)** to define and implement business behavior.

The behavior definition contains:

```text
CREATE
UPDATE
DELETE
```

as well as the custom actions:

```text
APPROVE
REJECT
```

The following fields are protected from inappropriate changes:

```text
RequestID
NumberOfDays
Status
```

The RAP behavior implementation is:

`ZBP_I_LEAVE_REQUEST_`

---

## 🔄 RAP Determinations

Two determinations were implemented.

### `calculateLeaveDays`

Triggered during creation when the start and end dates are available.

It automatically derives:

```text
NumberOfDays
```

from the date range.

### `setInitialStatus`

When a new leave request is created, its initial status is automatically set to:

```text
SUBMITTED
```

This demonstrates how RAP can automatically derive and populate business values.

---

## ✅ RAP Validation

The `validateDates` RAP validation checks the date range before saving.

The rule is:

```text
StartDate <= EndDate
```

When the rule is violated, the request fails validation and an error message is returned.

This demonstrates how RAP validations can protect the business object from invalid data.

---

## 👍 Approve and Reject Actions

Two custom RAP actions were implemented:

```text
approve
reject
```

### Approve

A leave request can only be approved when:

```text
Status = SUBMITTED
```

Successful transition:

```text
SUBMITTED → APPROVED
```

Trying to approve an already processed request is prevented.

### Reject

A leave request can only be rejected when:

```text
Status = SUBMITTED
```

Successful transition:

```text
SUBMITTED → REJECTED
```

Trying to reject an already processed request is prevented.

### State Transition

```text
                 +-------------+
                 |  SUBMITTED  |
                 +------+------+
                        |
             +----------+----------+
             |                     |
          APPROVE                REJECT
             |                     |
             v                     v
      +-------------+       +-------------+
      |  APPROVED   |       |  REJECTED   |
      +-------------+       +-------------+
```

The application also contains negative tests to verify that invalid transitions are blocked.

For example:

```text
REJECTED
    |
 REJECT again
    |
    v
Business Rule Error
```

---

## 🧪 RAP Testing

The class:

`ZCL_LEAVE_RAP_TEST`

was created to test the RAP business object.

The test class demonstrates the use of **Entity Manipulation Language (EML)**.

### Test scenarios

#### 1. Create

A leave request is created using RAP:

```text
CREATE
   |
   v
COMMIT
```

#### 2. Approve

The created request is read and the `approve` action is executed:

```text
SUBMITTED
    |
  APPROVE
    |
    v
APPROVED
```

#### 3. Reject

A separate submitted request is read and the `reject` action is executed:

```text
SUBMITTED
    |
  REJECT
    |
    v
REJECTED
```

#### 4. Negative Test

The project also verifies that a rejected request cannot be rejected again:

```text
REJECTED
    |
 REJECT again
    |
    v
Business Rule Error
```

This allowed the business rules to be tested rather than only checking successful scenarios.

---

## 🔗 CDS Data Model

The application uses **Core Data Services (CDS)** for data modeling.

### Employee CDS

`ZI_EMPLOYEE_`

Provides employee data from:

```text
ZEMPLOYEE__TABLE
```

### Leave Request CDS

`ZI_LEAVE_REQUEST_`

Provides leave request data from:

```text
ZLEAVE_REQ_TABLE
```

The leave request CDS also contains an association to the employee CDS entity.

Conceptually:

```text
Employee
   |
   | EmployeeID
   |
   v
Leave Request
```

This enables navigation from a leave request to its related employee.

---

## 🌐 OData V4 Service

The RAP business object is exposed through an OData V4 service.

### Service Definition

`ZUI_LEAVE_MANAGEMENT`

The service definition specifies the data that should be exposed to consumers.

### Service Binding

`ZUI_LEAVE_MANAGEMENT_O4`

The service binding exposes the application through:

```text
OData V4
```

The service exposes the main entities:

```text
Employee
LeaveRequest
```

The service was tested using the generated service testing interface.

---

## 🖥️ SAP Fiori Elements

The OData V4 service is consumed through a **SAP Fiori Elements** application.

The application displays leave requests in a list with fields such as:

- Request ID
- Employee ID
- Leave Type
- Start Date
- End Date
- Number of Days
- Status

The application also provides a detail page for an individual leave request.

The UI behavior and presentation were enhanced using:

`ZC_LEAVE_REQUEST_MDE`

which contains UI annotations for the Fiori Elements application.

---

## 🎨 UI Features

The Fiori Elements application includes:

- Leave request list view
- Leave request detail page
- Employee ID filtering
- Status filtering
- Leave Type filtering
- Start Date filtering
- Approve action
- Reject action
- Delete operation
- Navigation from list to object details

The UI is generated from the service metadata and annotations rather than being built as a traditional custom frontend.

---

## 🔄 End-to-End Flow

The complete application can be viewed as:

```text
ABAP Programming
      |
      v
Database Tables
      |
      v
CDS Data Model
      |
      v
RAP Behavior
      |
      +--> Determinations
      |
      +--> Validations
      |
      +--> Approve / Reject Actions
      |
      v
OData V4 Service
      |
      v
SAP Fiori Elements
      |
      v
User interacts with Leave Requests
```

---

## 🧰 Technology Stack

- SAP BTP ABAP Environment
- ABAP Cloud
- ABAP
- ABAP SQL
- Core Data Services (CDS)
- RESTful Application Programming Model (RAP)
- Entity Manipulation Language (EML)
- OData V4
- SAP Fiori Elements
- Eclipse IDE
- ABAP Development Tools (ADT)
- abapGit
- Git
- GitHub

---

## 📁 Repository Structure

The ABAP development objects are serialized into Git-compatible files using abapGit.

```text
sap-abap-leave-management/
│
├── README.md
├── .abapgit.xml
│
└── src/
    ├── ABAP Classes
    ├── CDS Definitions
    ├── Behavior Definitions
    ├── Behavior Implementations
    ├── Metadata Extensions
    ├── Database Table Definitions
    └── Service Definitions / Bindings
```

The `src` folder contains the serialized SAP development objects from the ABAP package.

---

## 🎓 What I Learned

This project helped me move from individual ABAP exercises toward understanding how different SAP development technologies fit together.

### ABAP Programming

I practiced:

- Structures
- Internal tables
- Loops
- Conditions
- Methods
- Data types
- String templates
- Database operations

### ABAP SQL

I practiced:

- `SELECT`
- `SELECT SINGLE`
- `INSERT`
- `WHERE`
- `ORDER BY`
- `sy-subrc`
- Reading database data into internal tables and structures

### CDS

I learned how CDS view entities can be used to create a reusable data model above database tables.

### RAP

I learned how RAP separates:

```text
Data Model
+
Business Behavior
```

and how behavior can contain:

```text
Determinations
Validations
Actions
```

### EML

I practiced using EML to:

```text
CREATE
READ
MODIFY
COMMIT
```

RAP business objects.

### OData and Fiori Elements

I learned how a RAP business object can be exposed as an OData V4 service and consumed by a Fiori Elements application.

### Git and abapGit

I also learned how SAP development objects can be serialized using abapGit and maintained in a GitHub repository.

---

## 🚧 Project Scope

This project intentionally focuses on learning and demonstrating ABAP concepts.

It is **not a production-ready enterprise leave management system**.

The project currently does not implement features such as:

- Leave balance management
- Weekend and public holiday calculations
- Multi-level approval workflows
- Email notifications
- Enterprise HR integration
- Advanced authorization management
- Audit history
- Production monitoring

These could be explored as future enhancements.

---

## 🚀 Possible Future Enhancements

Some possible extensions are:

1. Leave balance management
2. Multiple leave types with different rules
3. Weekend and public holiday handling
4. Role-based authorization
5. Multi-level approval workflow
6. Employee self-service
7. Email or notification integration
8. Additional Fiori Elements UI improvements

---

## 📸 Application Preview

The project includes a SAP Fiori Elements interface for managing leave requests.

The application supports:

```text
List View
    ↓
Select Leave Request
    ↓
Detail View
    ↓
Approve / Reject / Delete
```

Screenshots of the application and SAP development environment can be added here to provide a visual overview of the project.

---

## 👤 Author

### Yogeshwaran Mohan

Computer Science Graduate | SAP ABAP / SAP BTP Learner

This project was created as part of my practical learning journey with SAP ABAP and SAP BTP.

---

## ⭐ Project Summary

This project represents my practical learning journey from **basic ABAP programming to a small end-to-end SAP ABAP Cloud application**.

```text
ABAP Fundamentals
       ↓
ABAP SQL
       ↓
Database Persistence
       ↓
CDS
       ↓
RAP
       ↓
Determinations
       ↓
Validations
       ↓
Business Actions
       ↓
OData V4
       ↓
SAP Fiori Elements
       ↓
Git + GitHub
```

The objective was to understand how these technologies work together by building a simple Employee Leave Management application.
