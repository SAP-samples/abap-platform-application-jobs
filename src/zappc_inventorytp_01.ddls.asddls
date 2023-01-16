@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View forInventory'
@ObjectModel.semanticKey: [ 'InventoryID' ]
@Search.searchable: true
define root view entity ZAPPC_InventoryTP_01
  as projection on ZAPPR_InventoryTP_01
{
  key UUID,
  @Search.defaultSearchElement: true
  @Search.fuzzinessThreshold: 0.90 
  InventoryID,
  ProductID,
  @Semantics.quantity.unitOfMeasure: 'QuantityUnit'
  Quantity,
  @Semantics.unitOfMeasure: true
  @Consumption.valueHelpDefinition: [ {
    entity: {
      name: 'I_UnitOfMeasure', 
      element: 'UnitOfMeasure'
    }
  } ]
  QuantityUnit,
  @Semantics.amount.currencyCode: 'CurrencyCode'
  Price,
  @Consumption.valueHelpDefinition: [ {
    entity: {
      name: 'I_Currency', 
      element: 'Currency'
    }
  } ]
  CurrencyCode,
  Remark,
  NotAvailable,
  ScheduleJob,
  JobCount,
  JobName,
  LogHandle,
  CreatedBy,
  CreatedAt,
  LastChangedBy,
  LastChangedAt,
  LocalLastChangedAt,
             @EndUserText.label: 'Job Status'
           @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZAPP_CL_GEN_GET_JOB_STATUS'
  virtual  JobStatus            : abap.char( 1 ),
           @EndUserText.label: 'Generation'
           @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZAPP_CL_GEN_GET_JOB_STATUS'
  virtual  JobStatusText        : abap.char( 20 ),
           @EndUserText.label: 'Criticality'
           @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZAPP_CL_GEN_GET_JOB_STATUS'
  virtual  JobStatusCriticality : abap.int1,
  _ApplicationLog
  
}
