@EndUserText.label: 'Flight Travel Item (Projection)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AbapCatalog.extensibility: {
  extensible: true,
  allowNewDatasources: false,
  dataSources: ['Item'],
  elementSuffix: 'ZIT'
}
define view entity ZFG100_C_TravelItem
  as projection on ZFG100_R_TravelItem as Item
{
  key ItemUuid,
      AgencyId,
      TravelId,
      @Consumption.valueHelpDefinition:
              [ { entity: { name:    '/DMO/I_Carrier_StdVH',
                            element: 'AirlineID'
                          }
                }
              ]
      CarrierId,
      @Consumption.valueHelpDefinition:
               [ { entity: { name:    '/DMO/I_Connection_StdVH',
                             element: 'ConnectionID'
                           },
                   additionalBinding:
                        [ { localElement: 'CarrierID',
                                 element: 'CarrierID',
                                   usage: #FILTER_AND_RESULT
                          }
                        ],
                   label: 'Value Help by Connection'
                 },
                 { entity: { name:    '/DMO/I_Flight_StdVH',
                             element: 'ConnectionID'
                           },
                   additionalBinding:
                        [ { localElement: 'CarrierID',
                            element:      'CarrierID',
                            usage:        #FILTER_AND_RESULT
                          },
                          { localElement: 'FlightDate',
                            element:      'FlightDate',
                            usage:         #RESULT
                         }
                       ],
                   label: 'Value Help by Flight',
                   qualifier: 'Secondary Value help'
                 }
               ]
      ConnectionId,
      @Consumption.valueHelpDefinition:
           [ { entity: { name:    '/DMO/I_Flight_StdVH',
                         element: 'FlightDate'
                       },
               additionalBinding:
                    [ { localElement: 'CarrierID',
                        element:      'CarrierID',
                        usage:         #FILTER_AND_RESULT
                      },
                      { localElement: 'ConnectionID',
                        element:      'ConnectionID',
                        usage:        #RESULT
                      }
                    ]
             }
           ]
      FlightDate,
      BookingId,
      PassengerFirstName,
      PassengerLastName,
      ChangedAt,
      ChangedBy,
      LocChangedAt,
      _Travel : redirected to parent ZFG100_C_Travel,
      _Extension
}
