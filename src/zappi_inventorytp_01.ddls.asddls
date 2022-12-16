@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Projection View forInventory'
define root view entity ZAPPI_InventoryTP_01
  as projection on ZAPPR_InventoryTP_01
{
  key UUID,
  InventoryID,
  ProductID,
  Quantity,
  QuantityUnit,
  Price,
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
  LocalLastChangedAt
  
}
