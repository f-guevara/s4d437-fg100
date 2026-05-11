@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AbapCatalog.extensibility: {
  extensible: true,
  allowNewDatasources: false,
  dataSources: ['Item'],
  elementSuffix: 'ZIT'
}
@EndUserText.label: 'Extension Include for Travel Items'
define view entity ZFG100_E_TravelItem
  as select from zfg100_tritem as Item
{
  key item_uuid as ItemUuid
}
