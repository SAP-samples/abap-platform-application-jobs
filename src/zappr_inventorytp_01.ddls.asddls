@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'CDS View forInventory'
define root view entity ZAPPR_InventoryTP_01
  as select from zapp_inven_01
   association [0..*] to ZAPPI_appl_log as _ApplicationLog     on $projection.LogHandle = _ApplicationLog.Log_handle
{
  key uuid                  as UUID,
      inventory_id          as InventoryID,
      product_id            as ProductID,
      @Semantics.quantity.unitOfMeasure: 'QuantityUnit'
      quantity              as Quantity,
      quantity_unit         as QuantityUnit,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,
      currency_code         as CurrencyCode,
      remark                as Remark,
      not_available         as NotAvailable,
      schedule_job          as ScheduleJob,
      job_count             as JobCount,
      job_name              as JobName,
      log_handle            as LogHandle,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      _ApplicationLog

}
