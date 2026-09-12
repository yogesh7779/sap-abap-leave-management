@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Employee'

define view entity ZI_EMPLOYEE_
  as select from zemployee__table
{
  key employee_id as EmployeeID,
      first_name  as FirstName,
      last_name   as LastName,
      department  as Department,
      email       as Email
}
