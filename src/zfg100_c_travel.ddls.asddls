@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Data definition from ZFG100_R_Travel'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
@Metadata.allowExtensions: true

define root view entity ZFG100_C_Travel
  provider contract transactional_query as projection on ZFG100_R_Travel
{
    key AgencyId,
    key TravelId,
    @Search.defaultSearchElement: true
    Description,
    @Search.defaultSearchElement: true
    @Consumption.valueHelpDefinition: [ { entity: {
  name:    '/DMO/I_Customer_StdVH',
  element: 'CustomerID'
} } ]
    CustomerId,
    BeginDate,
    EndDate,
    @EndUserText.label: 'Duration (days)'
    Duration,
    Status,
    ChangedAt,
    ChangedBy,
    LocChangedAt,
    _TravelItem : redirected to composition child ZFG100_C_TravelItem
}
