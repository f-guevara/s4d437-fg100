@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flight Travel (Data Model)'
define root view entity ZFG100_R_Travel
  as select from zfg100_travel
  {
    key agency_id   as AgencyId,
    key travel_id   as TravelId,
        description as Description,
        customer_id as CustomerId,
        begin_date  as BeginDate,
        end_date    as EndDate,
        status      as Status,
        @Semantics.systemDateTime.lastChangedAt: true
        changed_at  as ChangedAt,
        @Semantics.user.lastChangedBy: true
        changed_by  as ChangedBy
  }
