CLASS zcl_leave_app DEFINITION

  PUBLIC

  FINAL

  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .

  PROTECTED SECTION.

  PRIVATE SECTION.


*---------------------------------------------------------------------*
* 1. LOCAL STRUCTURE FOR EMPLOYEE DATA
*---------------------------------------------------------------------*
*
* A structure groups related fields into one logical record.
*
* One TY_EMPLOYEE represents one employee.
*
*---------------------------------------------------------------------*

    TYPES:

      BEGIN OF ty_employee,

        employee_id TYPE string,
        first_name  TYPE string,
        last_name   TYPE string,
        department  TYPE string,
        email       TYPE string,

      END OF ty_employee.


*---------------------------------------------------------------------*
* 2. INTERNAL TABLE FOR EMPLOYEES
*---------------------------------------------------------------------*
*
* TT_EMPLOYEE represents multiple employee records.
*
* Think:
*
* TY_EMPLOYEE  = one employee
* TT_EMPLOYEE  = many employees
*
*---------------------------------------------------------------------*

    TYPES tt_employee TYPE STANDARD TABLE OF ty_employee
      WITH EMPTY KEY.


*---------------------------------------------------------------------*
* 3. LOCAL STRUCTURE FOR LEAVE REQUEST
*---------------------------------------------------------------------*
*
* One TY_LEAVE_REQUEST represents one leave request.
*
*---------------------------------------------------------------------*

    TYPES:

      BEGIN OF ty_leave_request,

        request_id     TYPE string,
        employee_id    TYPE string,
        leave_type     TYPE string,
        start_date     TYPE d,
        end_date       TYPE d,
        number_of_days TYPE i,
        reason         TYPE string,
        status         TYPE string,

      END OF ty_leave_request.


*---------------------------------------------------------------------*
* 4. INTERNAL TABLE FOR LEAVE REQUESTS
*---------------------------------------------------------------------*

    TYPES tt_leave_request TYPE STANDARD TABLE OF ty_leave_request
      WITH EMPTY KEY.


*---------------------------------------------------------------------*
* 5. VALIDATE EMPLOYEE
*---------------------------------------------------------------------*
*
* Purpose:
* Checks whether the supplied employee ID exists in the employee
* internal table.
*
*---------------------------------------------------------------------*

    METHODS validate_employee

      IMPORTING

        iv_employee_id TYPE string
        it_employees   TYPE tt_employee

      RETURNING

        VALUE(rv_valid) TYPE abap_bool.


*---------------------------------------------------------------------*
* 6. VALIDATE DATES
*---------------------------------------------------------------------*
*
* Business rule:
*
* Start Date must not be later than End Date.
*
*---------------------------------------------------------------------*

    METHODS validate_dates

      IMPORTING

        iv_start_date TYPE d
        iv_end_date   TYPE d

      RETURNING

        VALUE(rv_valid) TYPE abap_bool.


*---------------------------------------------------------------------*
* 7. CALCULATE LEAVE DAYS
*---------------------------------------------------------------------*
*
* Example:
*
* 15 Sep → 17 Sep
*
* 17 - 15 + 1 = 3 days
*
* The +1 is required because both the start date and end date
* are included.
*
*---------------------------------------------------------------------*

    METHODS calculate_leave_days

      IMPORTING

        iv_start_date TYPE d
        iv_end_date   TYPE d

      RETURNING

        VALUE(rv_days) TYPE i.


*---------------------------------------------------------------------*
* 8. VALIDATE LEAVE TYPE
*---------------------------------------------------------------------*
*
* Allowed leave types:
*
* ANNUAL
* SICK
* CASUAL
*
*---------------------------------------------------------------------*

    METHODS validate_leave_type

      IMPORTING

        iv_leave_type TYPE string

      RETURNING

        VALUE(rv_valid) TYPE abap_bool.


ENDCLASS.



CLASS zcl_leave_app IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.


*---------------------------------------------------------------------*
* PART 1 - CREATE SAMPLE EMPLOYEE DATA
*---------------------------------------------------------------------*
*
* APPEND VALUE is used to create a structure and add it to the
* internal table in one statement.
*
* This is an example of modern ABAP syntax.
*
*---------------------------------------------------------------------*

    DATA lt_employees TYPE tt_employee.


    APPEND VALUE #(

      employee_id = 'EMP001'
      first_name  = 'Rahul'
      last_name   = 'Kumar'
      department  = 'IT'
      email       = 'rahul@example.com'

    ) TO lt_employees.


    APPEND VALUE #(

      employee_id = 'EMP002'
      first_name  = 'Priya'
      last_name   = 'Sharma'
      department  = 'Finance'
      email       = 'priya@example.com'

    ) TO lt_employees.


    APPEND VALUE #(

      employee_id = 'EMP003'
      first_name  = 'Arjun'
      last_name   = 'Kumar'
      department  = 'HR'
      email       = 'arjun@example.com'

    ) TO lt_employees.


*---------------------------------------------------------------------*
* PART 2 - SAVE EMPLOYEE DATA INTO DATABASE
*---------------------------------------------------------------------*
*
* The internal table above represents application/prototype data.
*
* The database table ZEMPLOYEE__TABLE represents persistent data.
*
* Therefore we:
*
* Internal Table
*       ↓
* LOOP AT
*       ↓
* Database Structure
*       ↓
* INSERT
*       ↓
* Database
*
*---------------------------------------------------------------------*

    DATA ls_employee_db TYPE zemployee__table.


    LOOP AT lt_employees INTO DATA(ls_employee).


      CLEAR ls_employee_db.


*---------------------------------------------------------------------*
* Copy application structure fields into database structure.
*---------------------------------------------------------------------*

      ls_employee_db-employee_id = ls_employee-employee_id.
      ls_employee_db-first_name  = ls_employee-first_name.
      ls_employee_db-last_name   = ls_employee-last_name.
      ls_employee_db-department  = ls_employee-department.
      ls_employee_db-email       = ls_employee-email.


*---------------------------------------------------------------------*
* CHECK WHETHER EMPLOYEE ALREADY EXISTS
*---------------------------------------------------------------------*
*
* SELECT SINGLE reads at most one matching database record.
*
* SY-SUBRC:
*
* 0     = record found
* <> 0  = record not found
*
*---------------------------------------------------------------------*

      SELECT SINGLE

        FROM zemployee__table

        FIELDS employee_id

        WHERE employee_id = @ls_employee_db-employee_id

        INTO @DATA(lv_existing_employee).


      IF sy-subrc = 0.


        out->write(
          |Employee { lv_existing_employee } already exists.|
        ).


      ELSE.


*---------------------------------------------------------------------*
* INSERT NEW EMPLOYEE
*---------------------------------------------------------------------*

        INSERT zemployee__table FROM @ls_employee_db.


        IF sy-subrc = 0.

          out->write(
            |Employee { ls_employee_db-employee_id } inserted successfully.|
          ).

        ELSE.

          out->write(
            |Employee { ls_employee_db-employee_id } insert failed.|
          ).

        ENDIF.


      ENDIF.


    ENDLOOP.


*---------------------------------------------------------------------*
* PART 3 - READ EMPLOYEES FROM DATABASE
*---------------------------------------------------------------------*
*
* At this point the database is the source of truth.
*
* We therefore read the employee records back from the database.
*
*---------------------------------------------------------------------*

    SELECT

      FROM zemployee__table

      FIELDS

        employee_id,
        first_name,
        last_name,
        department,
        email

      INTO TABLE @DATA(lt_employees_db).


*---------------------------------------------------------------------*
* IMPORTANT TYPE CONVERSION
*---------------------------------------------------------------------*
*
* LT_EMPLOYEES_DB has the database table's row type.
*
* VALIDATE_EMPLOYEE expects TT_EMPLOYEE.
*
* Even though both contain similar fields, they are different ABAP
* types.
*
* Therefore we create a TT_EMPLOYEE table and copy the database
* values into it.
*
*---------------------------------------------------------------------*

    DATA lt_employees_for_validation TYPE tt_employee.


    LOOP AT lt_employees_db INTO DATA(ls_employee_db_read).


      APPEND VALUE #(

        employee_id = ls_employee_db_read-employee_id
        first_name  = ls_employee_db_read-first_name
        last_name   = ls_employee_db_read-last_name
        department  = ls_employee_db_read-department
        email       = ls_employee_db_read-email

      ) TO lt_employees_for_validation.


    ENDLOOP.


*---------------------------------------------------------------------*
* DISPLAY EMPLOYEE DATA
*---------------------------------------------------------------------*

    out->write( ' ' ).
    out->write( '========================================' ).
    out->write( '             EMPLOYEES' ).
    out->write( '========================================' ).

    out->write( lt_employees_db ).


*---------------------------------------------------------------------*
* PART 4 - PREPARE LEAVE REQUEST
*---------------------------------------------------------------------*
*
* Here we create a leave request using normal ABAP variables.
*
*---------------------------------------------------------------------*

    DATA lt_leave_requests TYPE tt_leave_request.

    DATA lv_employee_id    TYPE string.
    DATA lv_leave_type     TYPE string.
    DATA lv_start_date     TYPE d.
    DATA lv_end_date       TYPE d.
    DATA lv_number_of_days TYPE i.


    lv_employee_id = 'EMP001'.

    lv_leave_type = 'ANNUAL'.

    lv_start_date = '20260915'.

    lv_end_date = '20260917'.


*---------------------------------------------------------------------*
* PART 5 - VALIDATE EMPLOYEE
*---------------------------------------------------------------------*
*
* We call our own class method instead of putting all validation
* logic directly inside MAIN.
*
* This is ENCAPSULATION:
*
* MAIN
*   ↓
* validate_employee( )
*   ↓
* validation logic
*
*---------------------------------------------------------------------*

    IF validate_employee(

         iv_employee_id = lv_employee_id

         it_employees = lt_employees_for_validation

       ) = abap_false.


      out->write(
        |Error: Employee { lv_employee_id } not found.|
      ).

      RETURN.


    ENDIF.


    out->write(
      |Employee validation passed: { lv_employee_id }|
    ).


*---------------------------------------------------------------------*
* PART 6 - VALIDATE LEAVE TYPE
*---------------------------------------------------------------------*

    IF validate_leave_type(

         iv_leave_type = lv_leave_type

       ) = abap_false.


      out->write(
        |Error: Invalid leave type { lv_leave_type }.|
      ).

      RETURN.


    ENDIF.


    out->write(
      |Leave type validation passed: { lv_leave_type }|
    ).


*---------------------------------------------------------------------*
* PART 7 - VALIDATE DATES
*---------------------------------------------------------------------*

    IF validate_dates(

         iv_start_date = lv_start_date
         iv_end_date   = lv_end_date

       ) = abap_false.


      out->write(
        'Error: Start date cannot be after end date.'
      ).

      RETURN.


    ENDIF.


    out->write( 'Date validation passed.' ).


*---------------------------------------------------------------------*
* PART 8 - CALCULATE NUMBER OF DAYS
*---------------------------------------------------------------------*
*
* The calculation is moved to a separate method so that MAIN
* focuses on the business flow rather than the calculation itself.
*
*---------------------------------------------------------------------*

    lv_number_of_days = calculate_leave_days(

      iv_start_date = lv_start_date
      iv_end_date   = lv_end_date

    ).


    out->write(
      |Calculated leave days: { lv_number_of_days }|
    ).


*---------------------------------------------------------------------*
* PART 9 - CREATE LEAVE REQUEST IN INTERNAL TABLE
*---------------------------------------------------------------------*
*
* The internal table represents the application-level leave data.
*
* We first prepare the request in memory before saving it to the
* database.
*
*---------------------------------------------------------------------*

    APPEND VALUE #(

      request_id      = 'PROTOTYPE'
      employee_id     = lv_employee_id
      leave_type      = lv_leave_type
      start_date      = lv_start_date
      end_date        = lv_end_date
      number_of_days  = lv_number_of_days
      reason          = 'Family Function'
      status          = 'SUBMITTED'

    ) TO lt_leave_requests.


*---------------------------------------------------------------------*
* DISPLAY PROTOTYPE REQUEST
*---------------------------------------------------------------------*

    out->write( ' ' ).
    out->write( 'Prototype leave request:' ).

    LOOP AT lt_leave_requests INTO DATA(ls_request).

      out->write(
        |Request ID    : { ls_request-request_id }|
      ).

      out->write(
        |Employee ID   : { ls_request-employee_id }|
      ).

      out->write(
        |Leave Type    : { ls_request-leave_type }|
      ).

      out->write(
        |Start Date    : { ls_request-start_date }|
      ).

      out->write(
        |End Date      : { ls_request-end_date }|
      ).

      out->write(
        |Number of Days: { ls_request-number_of_days }|
      ).

      out->write(
        |Reason        : { ls_request-reason }|
      ).

      out->write(
        |Status        : { ls_request-status }|
      ).

    ENDLOOP.


*---------------------------------------------------------------------*
* PART 10 - GENERATE NEXT REQUEST ID
*---------------------------------------------------------------------*
*
* We look at the latest existing request ID in the database.
*
* Example:
*
* LR007
*   ↓
* 7
*   ↓
* +1
*   ↓
* 8
*   ↓
* LR008
*
* This keeps our simple prototype from inserting the same request
* key every time the program is executed.
*
*---------------------------------------------------------------------*


    DATA lv_next_number TYPE i.

    DATA lv_request_id TYPE zleave_req_table-request_id.


*---------------------------------------------------------------------*
* Find the next application request number
*
* Our project uses two kinds of IDs:
*
*   LR001, LR002, LR003, ...
*   LRTEST009, LRTEST010, ...
*
* Only the normal LR### IDs participate in numbering.
* RAP test IDs are intentionally ignored.
*---------------------------------------------------------------------*

    DATA lt_request_ids TYPE TABLE OF zleave_req_table-request_id.

    DATA lv_existing_number TYPE i.


    lv_next_number = 1.


*---------------------------------------------------------------------*
* Read existing request IDs from the database
*---------------------------------------------------------------------*

    SELECT

      FROM zleave_req_table

      FIELDS request_id

      INTO TABLE @lt_request_ids.


*---------------------------------------------------------------------*
* Examine each existing request ID
*---------------------------------------------------------------------*

    LOOP AT lt_request_ids INTO DATA(lv_existing_request_id).


*---------------------------------------------------------------------*
* A normal application request ID must:
*
*   1. Have exactly 5 characters
*   2. Start with LR
*
* Examples accepted:
*
*   LR001
*   LR015
*
* Examples ignored:
*
*   LRTEST009
*   LRTEST010
*
*---------------------------------------------------------------------*

      IF strlen( lv_existing_request_id ) = 5
         AND lv_existing_request_id+0(2) = 'LR'.


*---------------------------------------------------------------------*
* Convert the numeric part:
*
*   LR015
*     ↓
*   015
*     ↓
*   15
*---------------------------------------------------------------------*

        lv_existing_number =
          CONV i( lv_existing_request_id+2(3) ).


*---------------------------------------------------------------------*
* Keep the highest existing number
*---------------------------------------------------------------------*

        IF lv_existing_number >= lv_next_number.

          lv_next_number = lv_existing_number + 1.

        ENDIF.


      ENDIF.


    ENDLOOP.


*---------------------------------------------------------------------*
* Create the new request ID
*
* Example:
*
*   highest existing number = 15
*   next number             = 16
*
*   result                  = LR016
*---------------------------------------------------------------------*

    lv_request_id =
      |LR{ lv_next_number WIDTH = 3 ALIGN = RIGHT PAD = '0' }|.


    out->write(
      |Generated Request ID: { lv_request_id }|
    ).





*---------------------------------------------------------------------*
* Format request number as LR001, LR002, LR003, ...
*---------------------------------------------------------------------*

    lv_request_id =
      |LR{ lv_next_number WIDTH = 3 ALIGN = RIGHT PAD = '0' }|.


    out->write( ' ' ).

    out->write(
      |Generated Request ID: { lv_request_id }|
    ).


*---------------------------------------------------------------------*
* PART 11 - MAP INTERNAL TABLE DATA TO DATABASE STRUCTURE
*---------------------------------------------------------------------*
*
* The prototype request is stored in TT_LEAVE_REQUEST.
*
* The database table has a different row type:
*
* ZLEAVE_REQ_TABLE
*
* Therefore we copy the values to the database structure before
* inserting them.
*
*---------------------------------------------------------------------*

    DATA ls_leave_request_db TYPE zleave_req_table.


    LOOP AT lt_leave_requests INTO DATA(ls_request_to_save).


      CLEAR ls_leave_request_db.


      ls_leave_request_db-request_id =
        lv_request_id.

      ls_leave_request_db-employee_id =
        ls_request_to_save-employee_id.

      ls_leave_request_db-leave_type =
        ls_request_to_save-leave_type.

      ls_leave_request_db-start_date =
        ls_request_to_save-start_date.

      ls_leave_request_db-end_date =
        ls_request_to_save-end_date.

      ls_leave_request_db-number_of_days =
        ls_request_to_save-number_of_days.

      ls_leave_request_db-reason =
        ls_request_to_save-reason.

      ls_leave_request_db-status =
        ls_request_to_save-status.


*---------------------------------------------------------------------*
* PART 12 - INSERT LEAVE REQUEST INTO DATABASE
*---------------------------------------------------------------------*

      INSERT zleave_req_table FROM @ls_leave_request_db.


      IF sy-subrc = 0.

        out->write(
          |Leave request { lv_request_id } inserted successfully.|
        ).

      ELSE.

        out->write(
          |Leave request { lv_request_id } insert failed.|
        ).

        RETURN.

      ENDIF.


    ENDLOOP.


*---------------------------------------------------------------------*
* PART 13 - READ ALL PERSISTED LEAVE REQUESTS
*---------------------------------------------------------------------*
*
* This demonstrates ABAP SQL SELECT against our persistent table.
*
*---------------------------------------------------------------------*

    SELECT

      FROM zleave_req_table

      FIELDS

        request_id,
        employee_id,
        leave_type,
        start_date,
        end_date,
        number_of_days,
        reason,
        status

      ORDER BY request_id

      INTO TABLE @DATA(lt_leave_requests_db).


*---------------------------------------------------------------------*
* PART 14 - DISPLAY PERSISTED LEAVE REQUESTS
*---------------------------------------------------------------------*

    out->write( ' ' ).

    out->write(
      '========================================'
    ).

    out->write(
      '           LEAVE REQUESTS'
    ).

    out->write(
      '========================================'
    ).


    LOOP AT lt_leave_requests_db INTO DATA(ls_request_db).


      out->write(
        '----------------------------------------'
      ).

      out->write(
        |Request ID    : { ls_request_db-request_id }|
      ).

      out->write(
        |Employee ID   : { ls_request_db-employee_id }|
      ).

      out->write(
        |Leave Type    : { ls_request_db-leave_type }|
      ).

      out->write(
        |Start Date    : { ls_request_db-start_date }|
      ).

      out->write(
        |End Date      : { ls_request_db-end_date }|
      ).

      out->write(
        |Days          : { ls_request_db-number_of_days }|
      ).

      out->write(
        |Reason        : { ls_request_db-reason }|
      ).

      out->write(
        |Status        : { ls_request_db-status }|
      ).


    ENDLOOP.


*---------------------------------------------------------------------*
* END OF MAIN PROGRAM
*---------------------------------------------------------------------*

    out->write( ' ' ).

    out->write(
      'Basic ABAP Leave Management demonstration completed.'
    ).


  ENDMETHOD.




  METHOD validate_employee.

*---------------------------------------------------------------------*
* METHOD 1 - VALIDATE EMPLOYEE
*---------------------------------------------------------------------*
*
* LINE_EXISTS checks whether a matching row exists in an internal
* table.
*
* Instead of reading the complete row, we only need TRUE/FALSE.
*
*---------------------------------------------------------------------*


    rv_valid = xsdbool(

      line_exists(
        it_employees[ employee_id = iv_employee_id ]
      )

    ).


  ENDMETHOD.




  METHOD validate_dates.

*---------------------------------------------------------------------*
* METHOD 2 - VALIDATE DATES
*---------------------------------------------------------------------*
*
* The valid condition is:
*
* Start Date <= End Date
*
* XSDBOOL converts that logical condition into ABAP_BOOL.
*
*---------------------------------------------------------------------*


    rv_valid = xsdbool(

      iv_start_date <= iv_end_date

    ).


  ENDMETHOD.





  METHOD calculate_leave_days.

*---------------------------------------------------------------------*
* METHOD 3 - CALCULATE LEAVE DAYS
*---------------------------------------------------------------------*
*
* ABAP allows date subtraction.
*
* Example:
*
* 20260917 - 20260915 = 2
*
* Because both days are included:
*
* 2 + 1 = 3
*
*---------------------------------------------------------------------*


    rv_days =
      iv_end_date - iv_start_date + 1.


  ENDMETHOD.



  METHOD validate_leave_type.


*--------------------------------------------------------------------*
* METHOD 4 - VALIDATE LEAVE TYPE
*---------------------------------------------------------------------*
*
* CASE is useful when one value can have several valid options.
*
* This is the same business rule we initially implemented in the
* procedural prototype.
*
*---------------------------------------------------------------------*


    CASE iv_leave_type.


      WHEN 'ANNUAL'.

        rv_valid = abap_true.


      WHEN 'SICK'.

        rv_valid = abap_true.


      WHEN 'CASUAL'.

        rv_valid = abap_true.


      WHEN OTHERS.

        rv_valid = abap_false.


    ENDCASE.


  ENDMETHOD.


ENDCLASS.
