CLASS zcl_leave_rap_test DEFINITION

  PUBLIC

  FINAL

  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.


CLASS zcl_leave_rap_test IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.


*---------------------------------------------------------------------*
* RAP LEAVE MANAGEMENT TEST PROGRAM
*---------------------------------------------------------------------*
*
* Purpose:
* This class is a simple learning and test program for the
* Leave Request RAP Business Object.
*
* The program demonstrates:
*
* 1. CREATE a Leave Request using EML
* 2. COMMIT the transaction
* 3. READ the created request
* 4. EXECUTE the APPROVE action
* 5. COMMIT the APPROVE action
* 6. Verify the result in the database
* 7. CREATE another Leave Request
* 8. EXECUTE the REJECT action
* 9. Commit and verify the REJECT action
* 10. Try to reject an already rejected request
*     to demonstrate RAP business-rule validation
*
* EML = Entity Manipulation Language
*
* EML allows ABAP code to communicate with a RAP Business Object
* using its behavior definition instead of directly changing the
* database table.
*
*---------------------------------------------------------------------*


*---------------------------------------------------------------------*
* TEST DATA
*---------------------------------------------------------------------*
*
* IMPORTANT:
* These IDs are test/demo IDs.
*
* If you run this class again after these requests already exist,
* change the IDs below to new values.
*
*---------------------------------------------------------------------*

    DATA(lv_approve_request_id) = 'LRTEST009'.
    DATA(lv_reject_request_id)  = 'LRTEST010'.


*---------------------------------------------------------------------*
* PART 1 - CREATE A LEAVE REQUEST FOR APPROVAL
*---------------------------------------------------------------------*
*
* MODIFY ENTITIES
* ----------------
* This is EML.
*
* We are not inserting directly into ZLEAVE_REQ_TABLE.
* Instead, we ask the RAP Business Object to create the entity.
*
* RAP then applies its behavior:
* - Determinations
* - Validations
* - Field controls
* - Other business logic
*
*---------------------------------------------------------------------*

    out->write( '========================================' ).
    out->write( '       RAP LEAVE REQUEST TEST' ).
    out->write( '========================================' ).

    out->write( ' ' ).
    out->write( '1. Creating Leave Request for APPROVE test...' ).


    MODIFY ENTITIES OF zi_leave_request_

      ENTITY LeaveRequest

      CREATE FIELDS (

        RequestID
        EmployeeID
        LeaveType
        StartDate
        EndDate
        Reason

      )

      WITH VALUE #(

        (

          %cid       = 'ApproveRequest'

          RequestID  = lv_approve_request_id
          EmployeeID = 'EMP001'
          LeaveType  = 'ANNUAL'
          StartDate  = '20260915'
          EndDate    = '20260917'
          Reason     = 'Family Function'

        )

      )

      FAILED DATA(lt_create_failed)

      REPORTED DATA(lt_create_reported).


*---------------------------------------------------------------------*
* CHECK CREATE RESULT
*---------------------------------------------------------------------*
*
* FAILED
* ------
* Contains information about failed RAP operations.
*
* REPORTED
* --------
* Contains messages reported by the RAP framework or behavior.
*
*---------------------------------------------------------------------*

    IF lt_create_failed IS NOT INITIAL.

      out->write( 'CREATE failed.' ).
      out->write( lt_create_failed ).

      IF lt_create_reported IS NOT INITIAL.

        out->write( 'CREATE messages:' ).
        out->write( lt_create_reported ).

      ENDIF.

      RETURN.

    ENDIF.


    out->write(
      |CREATE accepted: { lv_approve_request_id }|
    ).


*---------------------------------------------------------------------*
* PART 2 - COMMIT THE CREATE
*---------------------------------------------------------------------*
*
* MODIFY ENTITIES prepares the RAP operation.
*
* COMMIT ENTITIES
* ----------------
* Finalizes the RAP transaction and makes the change persistent.
*
* Think of it as:
*
* MODIFY ENTITIES
*        ↓
* prepare/change RAP BO
*        ↓
* COMMIT ENTITIES
*        ↓
* persist the change
*
*---------------------------------------------------------------------*

    COMMIT ENTITIES

      RESPONSE OF zi_leave_request_

      FAILED DATA(lt_create_commit_failed)

      REPORTED DATA(lt_create_commit_reported).


    IF lt_create_commit_failed IS NOT INITIAL.

      out->write( 'CREATE COMMIT failed.' ).
      out->write( lt_create_commit_failed ).

      IF lt_create_commit_reported IS NOT INITIAL.

        out->write( 'CREATE COMMIT messages:' ).
        out->write( lt_create_commit_reported ).

      ENDIF.

      RETURN.

    ENDIF.


    out->write( 'CREATE COMMIT successful.' ).


*---------------------------------------------------------------------*
* PART 3 - READ THE CREATED REQUEST
*---------------------------------------------------------------------*
*
* READ ENTITIES is EML used for reading data through the RAP
* Business Object.
*
* We use %tky (technical key) later when executing the action.
*
*---------------------------------------------------------------------*

    out->write( ' ' ).
    out->write( '2. Reading created request...' ).


    READ ENTITIES OF zi_leave_request_

      ENTITY LeaveRequest

      FIELDS (

        RequestID
        EmployeeID
        LeaveType
        StartDate
        EndDate
        NumberOfDays
        Reason
        Status

      )

      WITH VALUE #(

        (

          RequestID = lv_approve_request_id

        )

      )

      RESULT DATA(lt_approve_request).


    IF lt_approve_request IS INITIAL.

      out->write( 'Request could not be read.' ).
      RETURN.

    ENDIF.


    out->write( 'Request before APPROVE:' ).
    out->write( lt_approve_request ).


*---------------------------------------------------------------------*
* PART 4 - EXECUTE APPROVE ACTION
*---------------------------------------------------------------------*
*
* EXECUTE approve
* ----------------
*
* This calls the RAP action defined in the Behavior Definition:
*
*     action approve;
*
* The action is implemented in the RAP Behavior Pool.
*
* %tky identifies the exact RAP instance on which the action
* should be executed.
*
*---------------------------------------------------------------------*

    out->write( ' ' ).
    out->write( '3. Executing APPROVE action...' ).


    MODIFY ENTITIES OF zi_leave_request_

      ENTITY LeaveRequest

      EXECUTE approve

      FROM VALUE #(

        FOR ls_request IN lt_approve_request

        (

          %tky = ls_request-%tky

        )

      )

      FAILED DATA(lt_approve_failed)

      REPORTED DATA(lt_approve_reported).


*---------------------------------------------------------------------*
* CHECK APPROVE RESULT
*---------------------------------------------------------------------*

    IF lt_approve_failed IS NOT INITIAL.

      out->write( 'APPROVE action failed.' ).
      out->write( lt_approve_failed ).

      IF lt_approve_reported IS NOT INITIAL.

        out->write( 'APPROVE action messages:' ).
        out->write( lt_approve_reported ).

      ENDIF.

      RETURN.

    ENDIF.


    out->write( 'APPROVE action accepted.' ).


*---------------------------------------------------------------------*
* PART 5 - COMMIT APPROVE ACTION
*---------------------------------------------------------------------*

    COMMIT ENTITIES

      RESPONSE OF zi_leave_request_

      FAILED DATA(lt_approve_commit_failed)

      REPORTED DATA(lt_approve_commit_reported).


    IF lt_approve_commit_failed IS NOT INITIAL.

      out->write( 'APPROVE COMMIT failed.' ).
      out->write( lt_approve_commit_failed ).

      IF lt_approve_commit_reported IS NOT INITIAL.

        out->write( 'APPROVE COMMIT messages:' ).
        out->write( lt_approve_commit_reported ).

      ENDIF.

      RETURN.

    ENDIF.


    out->write( 'APPROVE COMMIT successful.' ).


*---------------------------------------------------------------------*
* PART 6 - VERIFY APPROVED REQUEST IN DATABASE
*---------------------------------------------------------------------*
*
* Here we use ABAP SQL directly against the database table.
*
* Why?
*
* We already know how EML changed the RAP Business Object.
* This SELECT gives us a simple way to verify that the final
* status was persisted in the database.
*
*---------------------------------------------------------------------*

    SELECT SINGLE

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

      WHERE request_id = @lv_approve_request_id

      INTO @DATA(ls_approved_request).


    IF sy-subrc = 0.

      out->write( ' ' ).
      out->write( 'Approved request persisted in database:' ).

      out->write(
        |Request ID    : { ls_approved_request-request_id }|
      ).

      out->write(
        |Employee ID   : { ls_approved_request-employee_id }|
      ).

      out->write(
        |Leave Type    : { ls_approved_request-leave_type }|
      ).

      out->write(
        |Start Date    : { ls_approved_request-start_date }|
      ).

      out->write(
        |End Date      : { ls_approved_request-end_date }|
      ).

      out->write(
        |Number of Days: { ls_approved_request-number_of_days }|
      ).

      out->write(
        |Reason        : { ls_approved_request-reason }|
      ).

      out->write(
        |Status        : { ls_approved_request-status }|
      ).

    ELSE.

      out->write(
        |{ lv_approve_request_id } was not found in database.|
      ).

      RETURN.

    ENDIF.


*---------------------------------------------------------------------*
* PART 7 - CREATE A SECOND REQUEST FOR REJECT TEST
*---------------------------------------------------------------------*
*
* We create a separate request so that the APPROVE and REJECT
* actions can be tested independently.
*
*---------------------------------------------------------------------*

    out->write( ' ' ).
    out->write( '4. Creating Leave Request for REJECT test...' ).


    MODIFY ENTITIES OF zi_leave_request_

      ENTITY LeaveRequest

      CREATE FIELDS (

        RequestID
        EmployeeID
        LeaveType
        StartDate
        EndDate
        Reason

      )

      WITH VALUE #(

        (

          %cid       = 'RejectRequest'

          RequestID  = lv_reject_request_id
          EmployeeID = 'EMP001'
          LeaveType  = 'ANNUAL'
          StartDate  = '20260915'
          EndDate    = '20260917'
          Reason     = 'Personal Work'

        )

      )

      FAILED DATA(lt_reject_create_failed)

      REPORTED DATA(lt_reject_create_reported).


    IF lt_reject_create_failed IS NOT INITIAL.

      out->write( 'REJECT test CREATE failed.' ).
      out->write( lt_reject_create_failed ).

      IF lt_reject_create_reported IS NOT INITIAL.

        out->write( 'REJECT test CREATE messages:' ).
        out->write( lt_reject_create_reported ).

      ENDIF.

      RETURN.

    ENDIF.


    out->write(
      |CREATE accepted: { lv_reject_request_id }|
    ).


*---------------------------------------------------------------------*
* PART 8 - COMMIT SECOND CREATE
*---------------------------------------------------------------------*

    COMMIT ENTITIES

      RESPONSE OF zi_leave_request_

      FAILED DATA(lt_reject_create_commit_failed)

      REPORTED DATA(lt_reject_crte_commit_reported).


    IF lt_reject_create_commit_failed IS NOT INITIAL.

      out->write( 'REJECT test CREATE COMMIT failed.' ).
      out->write( lt_reject_create_commit_failed ).

      IF lt_reject_crte_commit_reported IS NOT INITIAL.

        out->write( 'REJECT test CREATE COMMIT messages:' ).
        out->write( lt_reject_crte_commit_reported ).

      ENDIF.

      RETURN.

    ENDIF.


    out->write( 'REJECT test CREATE COMMIT successful.' ).


*---------------------------------------------------------------------*
* PART 9 - READ SECOND REQUEST
*---------------------------------------------------------------------*

    READ ENTITIES OF zi_leave_request_

      ENTITY LeaveRequest

      FIELDS (

        RequestID
        EmployeeID
        LeaveType
        StartDate
        EndDate
        NumberOfDays
        Reason
        Status

      )

      WITH VALUE #(

        (

          RequestID = lv_reject_request_id

        )

      )

      RESULT DATA(lt_reject_request).


    IF lt_reject_request IS INITIAL.

      out->write(
        |{ lv_reject_request_id } could not be read.|
      ).

      RETURN.

    ENDIF.


    out->write( 'Request before REJECT:' ).
    out->write( lt_reject_request ).


*---------------------------------------------------------------------*
* PART 10 - EXECUTE REJECT ACTION
*---------------------------------------------------------------------*
*
* Behavior Definition contains:
*
*     action reject;
*
* This statement calls that RAP action.
*
*---------------------------------------------------------------------*

    out->write( ' ' ).
    out->write( '5. Executing REJECT action...' ).


    MODIFY ENTITIES OF zi_leave_request_

      ENTITY LeaveRequest

      EXECUTE reject

      FROM VALUE #(

        FOR ls_request IN lt_reject_request

        (

          %tky = ls_request-%tky

        )

      )

      FAILED DATA(lt_reject_failed)

      REPORTED DATA(lt_reject_reported).


    IF lt_reject_failed IS NOT INITIAL.

      out->write( 'REJECT action failed.' ).
      out->write( lt_reject_failed ).

      IF lt_reject_reported IS NOT INITIAL.

        out->write( 'REJECT action messages:' ).
        out->write( lt_reject_reported ).

      ENDIF.

      RETURN.

    ENDIF.


    out->write( 'REJECT action accepted.' ).


*---------------------------------------------------------------------*
* PART 11 - COMMIT REJECT ACTION
*---------------------------------------------------------------------*

    COMMIT ENTITIES

      RESPONSE OF zi_leave_request_

      FAILED DATA(lt_reject_commit_failed)

      REPORTED DATA(lt_reject_commit_reported).


    IF lt_reject_commit_failed IS NOT INITIAL.

      out->write( 'REJECT COMMIT failed.' ).
      out->write( lt_reject_commit_failed ).

      IF lt_reject_commit_reported IS NOT INITIAL.

        out->write( 'REJECT COMMIT messages:' ).
        out->write( lt_reject_commit_reported ).

      ENDIF.

      RETURN.

    ENDIF.


    out->write( 'REJECT COMMIT successful.' ).


*---------------------------------------------------------------------*
* PART 12 - VERIFY REJECTED REQUEST IN DATABASE
*---------------------------------------------------------------------*

    SELECT SINGLE

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

      WHERE request_id = @lv_reject_request_id

      INTO @DATA(ls_rejected_request).


    IF sy-subrc = 0.

      out->write( ' ' ).
      out->write( 'Rejected request persisted in database:' ).

      out->write(
        |Request ID    : { ls_rejected_request-request_id }|
      ).

      out->write(
        |Employee ID   : { ls_rejected_request-employee_id }|
      ).

      out->write(
        |Leave Type    : { ls_rejected_request-leave_type }|
      ).

      out->write(
        |Start Date    : { ls_rejected_request-start_date }|
      ).

      out->write(
        |End Date      : { ls_rejected_request-end_date }|
      ).

      out->write(
        |Number of Days: { ls_rejected_request-number_of_days }|
      ).

      out->write(
        |Reason        : { ls_rejected_request-reason }|
      ).

      out->write(
        |Status        : { ls_rejected_request-status }|
      ).

    ELSE.

      out->write(
        |{ lv_reject_request_id } was not found in database.|
      ).

      RETURN.

    ENDIF.


*---------------------------------------------------------------------*
* PART 13 - NEGATIVE TEST
*---------------------------------------------------------------------*
*
* Current state:
*
*     { lv_reject_request_id } → REJECTED
*
* We deliberately try to reject it again.
*
* According to our RAP business rule:
*
*     Only SUBMITTED requests can be rejected.
*
* Therefore the second reject must fail.
*
* This proves that the business rule is enforced by RAP.
*
*---------------------------------------------------------------------*

    out->write( ' ' ).
    out->write( '6. Negative test: Reject already rejected request...' ).


    READ ENTITIES OF zi_leave_request_

      ENTITY LeaveRequest

      FIELDS (

        RequestID
        Status

      )

      WITH VALUE #(

        (

          RequestID = lv_reject_request_id

        )

      )

      RESULT DATA(lt_reject_again_request).


    IF lt_reject_again_request IS INITIAL.

      out->write(
        |{ lv_reject_request_id } could not be read for negative test.|
      ).

      RETURN.

    ENDIF.


    out->write( 'Current request before second REJECT:' ).
    out->write( lt_reject_again_request ).


*---------------------------------------------------------------------*
* TRY REJECT AGAIN
*---------------------------------------------------------------------*

    MODIFY ENTITIES OF zi_leave_request_

      ENTITY LeaveRequest

      EXECUTE reject

      FROM VALUE #(

        FOR ls_request IN lt_reject_again_request

        (

          %tky = ls_request-%tky

        )

      )

      FAILED DATA(lt_second_reject_failed)

      REPORTED DATA(lt_second_reject_reported).


*---------------------------------------------------------------------*
* EXPECTED RESULT:
*
* The second reject SHOULD fail.
*
*---------------------------------------------------------------------*

    IF lt_second_reject_failed IS NOT INITIAL.

      out->write(
        'SUCCESS: Second REJECT correctly failed.'
      ).

      out->write( lt_second_reject_failed ).


      IF lt_second_reject_reported IS NOT INITIAL.

        out->write(
          'Business rule message:'
        ).

        out->write( lt_second_reject_reported ).

      ENDIF.

    ELSE.

      out->write(
        'ERROR: Second REJECT was incorrectly accepted.'
      ).

    ENDIF.


*---------------------------------------------------------------------*
* FINAL SUMMARY
*---------------------------------------------------------------------*

    out->write( ' ' ).
    out->write( '========================================' ).
    out->write( '             TEST SUMMARY' ).
    out->write( '========================================' ).

    out->write(
      |APPROVE TEST : { lv_approve_request_id } → APPROVED|
    ).

    out->write(
      |REJECT TEST  : { lv_reject_request_id } → REJECTED|
    ).

    out->write(
      'NEGATIVE TEST : REJECTED request could not be rejected again'
    ).

    out->write( '========================================' ).


  ENDMETHOD.

ENDCLASS.
