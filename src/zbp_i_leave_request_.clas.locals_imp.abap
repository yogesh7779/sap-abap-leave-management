CLASS lhc_leaverequest DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS calculateLeaveDays FOR DETERMINE ON MODIFY
      keys FOR LeaveRequest~calculateLeaveDays.
    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      keys FOR LeaveRequest~setInitialStatus.
    METHODS validateDates FOR VALIDATE ON SAVE
      keys FOR LeaveRequest~validateDates.
    METHODS approve FOR MODIFY
      keys FOR ACTION LeaveRequest~approve.
    METHODS reject FOR MODIFY
      keys FOR ACTION LeaveRequest~reject.

ENDCLASS.

CLASS lhc_leaverequest IMPLEMENTATION.

 METHOD calculateLeaveDays.

  READ ENTITIES OF zi_leave_request_
    IN LOCAL MODE
    ENTITY LeaveRequest
    FIELDS ( StartDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_leave_requests).

  MODIFY ENTITIES OF zi_leave_request_
    IN LOCAL MODE
    ENTITY LeaveRequest
    UPDATE FIELDS ( NumberOfDays )
    WITH VALUE #(
      FOR ls_request IN lt_leave_requests
      (
        %tky         = ls_request-%tky
        NumberOfDays = ls_request-EndDate - ls_request-StartDate + 1
      )
    ).

ENDMETHOD.

METHOD setInitialStatus.

  MODIFY ENTITIES OF zi_leave_request_
    IN LOCAL MODE
    ENTITY LeaveRequest
    UPDATE FIELDS ( Status )
    WITH VALUE #(
      FOR key IN keys
      (
        %tky   = key-%tky
        Status = 'SUBMITTED'
      )
    ).

ENDMETHOD.

METHOD validateDates.

  READ ENTITIES OF zi_leave_request_
    IN LOCAL MODE
    ENTITY LeaveRequest
    FIELDS ( StartDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_leave_requests).

  LOOP AT lt_leave_requests INTO DATA(ls_request).

    IF ls_request-StartDate > ls_request-EndDate.

      APPEND VALUE #(
        %tky = ls_request-%tky
      ) TO failed-LeaveRequest.

      APPEND VALUE #(
        %tky = ls_request-%tky
        %element-StartDate = if_abap_behv=>mk-on
        %element-EndDate   = if_abap_behv=>mk-on
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text     = 'Start date cannot be after end date' )
      ) TO reported-LeaveRequest.

    ENDIF.

  ENDLOOP.

ENDMETHOD.

  METHOD approve.

  READ ENTITIES OF zi_leave_request_
    IN LOCAL MODE
    ENTITY LeaveRequest
    FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_leave_requests).

  LOOP AT lt_leave_requests INTO DATA(ls_request).

    IF ls_request-Status <> 'SUBMITTED'.

      APPEND VALUE #(
        %tky = ls_request-%tky
      ) TO failed-LeaveRequest.

      APPEND VALUE #(
        %tky = ls_request-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text = 'Only submitted leave requests can be approved' )
      ) TO reported-LeaveRequest.

    ENDIF.

  ENDLOOP.

  DELETE lt_leave_requests
    WHERE Status <> 'SUBMITTED'.

  CHECK lt_leave_requests IS NOT INITIAL.

  MODIFY ENTITIES OF zi_leave_request_
    IN LOCAL MODE
    ENTITY LeaveRequest
    UPDATE FIELDS ( Status )
    WITH VALUE #(
      FOR ls_request_approve IN lt_leave_requests
      (
        %tky   = ls_request_approve-%tky
        Status = 'APPROVED'
      )
    ).

ENDMETHOD.

  METHOD reject.

  READ ENTITIES OF zi_leave_request_
    IN LOCAL MODE
    ENTITY LeaveRequest
    FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_leave_requests).

  LOOP AT lt_leave_requests INTO DATA(ls_request).

    IF ls_request-Status <> 'SUBMITTED'.

      APPEND VALUE #(
        %tky = ls_request-%tky
      ) TO failed-LeaveRequest.

      APPEND VALUE #(
        %tky = ls_request-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text = 'Only submitted leave requests can be rejected' )
      ) TO reported-LeaveRequest.

    ENDIF.

  ENDLOOP.

  DELETE lt_leave_requests
    WHERE Status <> 'SUBMITTED'.

  CHECK lt_leave_requests IS NOT INITIAL.

  MODIFY ENTITIES OF zi_leave_request_
    IN LOCAL MODE
    ENTITY LeaveRequest
    UPDATE FIELDS ( Status )
    WITH VALUE #(
      FOR ls_request_reject IN lt_leave_requests
      (
        %tky   = ls_request_reject-%tky
        Status = 'REJECTED'
      )
    ).

ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

