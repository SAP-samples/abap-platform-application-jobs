@EndUserText.label: 'RAP Generator - Application Log'
@ObjectModel.query.implementedBy: 'ABAP:ZAPP_CL_SHOW_APPL_LOG'
//@Search.searchable: true

@UI: {
    headerInfo: {
    typeName: 'AppLogEntry',
    typeNamePlural: 'AppLogEntries'},

    presentationVariant: [{
    maxItems: 20,
//    qualifier: 'pVariant',
    visualizations: [{type: #AS_LINEITEM}]
    }]



    }

define custom entity ZAPPI_appl_log 
{
      //      @Search.defaultSearchElement: true
      //      @Search.fuzzinessThreshold: 0.90
      //      @EndUserText.label : 'Log Item Number'
//      @UI.lineItem    : [ {
//      position        : 5 ,
//      importance      : #HIGH,
//      label           : 'Log handle'  } ]
//      @UI.identification: [ {
//      position        : 5 ,
//      importance      : #HIGH ,
//      label           : 'Log handle' } ]


  key Log_handle      : balloghndl;
      @UI.lineItem    : [ {
      position        : 10 ,
      importance      : #HIGH,
      label           : 'Log item number'  } ]
      @UI.identification: [ {
      position        : 10 ,
      importance      : #HIGH,
      label           : 'Log item number'  } ]
      @EndUserText.label: 'Logitemnumber'
      @UI.selectionField: [ { position: 20 } ]
  key Log_item_number : balmnr;

      @UI.lineItem    : [ {
          position    : 10 ,
          importance  : #HIGH,
          criticality : 'criticality',
          label       : 'Severity'  } ]

      severity        : symsgty;
      category        : abap.char(1);
      criticality     : abap.int1;
      @UI.lineItem    : [ {
      position        : 90 ,
      importance      : #HIGH,
      label           : 'Detail level'  } ]
      @UI.identification: [ {
      position        : 90 ,
      importance      : #HIGH,
      label           : 'Detail level'  } ]
      detail_level    : ballevel;
      timestamp       : abap.utclong;
      @UI.lineItem    : [ {
      position        : 100 ,
      importance      : #HIGH,
      label           : 'Message text'  } ]
      @UI.identification: [ {
      position        : 100 ,
      importance      : #HIGH,
      label           : 'Message text'  } ]
      message_text    : abap.sstring( 512 );

}
  
