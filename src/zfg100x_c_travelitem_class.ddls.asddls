extend view entity ZFG100_C_TravelItem with
{
  @Consumption.valueHelpDefinition: [ { entity: {
    name:    '/LRN/437_I_ClassStdVH',
    element: 'ClassId'
  } } ]
  Item.ZZClassZIT
}
