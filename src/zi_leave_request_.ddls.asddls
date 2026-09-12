@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Leave Request'
@Metadata.allowExtensions: true

define root view entity ZI_LEAVE_REQUEST_
  as select from zleave_req_table as LeaveRequest

  association [1..1] to ZI_EMPLOYEE_ as _Employee
    on $projection.EmployeeID = _Employee.EmployeeID
{
  key LeaveRequest.request_id     as RequestID,
      LeaveRequest.employee_id    as EmployeeID,
      LeaveRequest.leave_type     as LeaveType,
      LeaveRequest.start_date     as StartDate,
      LeaveRequest.end_date       as EndDate,
      LeaveRequest.number_of_days as NumberOfDays,
      LeaveRequest.reason         as Reason,
      LeaveRequest.status         as Status,

      _Employee
}
