*&---------------------------------------------------------------------*
*& Report  Z_DCN_SEND_BOOKINGS
*&
*&---------------------------------------------------------------------*
*&
*& Test report for showing usage of the ZCL_SUP_DCN class.
*& For more info read:
*& http://scn.sap.com/community/developer-center/mobility-platform/blog/2012/06/11/calling-the-sup-data-change-notification-from-abap
*&
*&---------------------------------------------------------------------*

REPORT  Z_DCN_SEND_BOOKINGS line-size 1023 no standard page heading.

data:
  http_status_code type I,
  http_status_message type string,
  response_text type string,
  wa_tnvp type line of tihttpnvp,
  dcn_response type zsup_dcn_response_tab,
  wa_dcnresp type line of zsup_dcn_response_tab,
  sup_dcn type ref to zcl_sup_dcn,
  t_bookings type table of BAPISBODAT,
  msgidx type i,
  idxstr type string,
  nlines type i.

*data wa_booking type BAPISBODAT.
field-symbols <fs_booking> type BAPISBODAT.

parameters:
  airline like BAPISBOKEY-AIRLINEID,
  t_agency like BAPISBODAT-AGENCYNUM,
  c_number like BAPISCUKEY-CUSTOMERID,
  max_rows like BAPISFLAUX-BAPIMAXROW.

select-options fl_date for <fs_booking>-flightdate.
select-options bk_date for <fs_booking>-bookdate.


CALL FUNCTION 'BAPI_FLBOOKING_GETLIST'
  EXPORTING
    AIRLINE            = airline
    TRAVEL_AGENCY      = t_agency
    CUSTOMER_NUMBER    = c_number
    MAX_ROWS           = max_rows
  TABLES
    FLIGHT_DATE_RANGE  = fl_date
    BOOKING_DATE_RANGE = bk_date
*   EXTENSION_IN       =
    BOOKING_LIST       = t_bookings
*   EXTENSION_OUT      =
*   RETURN             =
  .

*break-point id z_dcn.

CREATE OBJECT SUP_DCN
  EXPORTING
*    PACKAGE = 'flightbooking:1.0'
    PACKAGE  = 'sp:1.0'
*   CMD      = 'dcn'
*   SECURITY = 'default'
*   USERNAME = 'supAdmin'
*   PASSWORD = 's3pAdmin'
*   DOMAIN   = 'default'
*   MESSAGES = t_messages.
.

loop at t_bookings assigning <fs_booking>.
  add 1 to msgidx.
  idxstr = msgidx.
  sup_dcn->add_message( id = idxstr op = 'upsert' mbo = 'Bookings' cols = <fs_booking> ).
*  sup_dcn->add_message(  op = 'upsert' mbo = 'Bookings' cols = <fs_booking> ).
endloop.

*break-point id z_dcn.


  write: / 'Calling DCN server:'.
  uline.

  CALL METHOD SUP_DCN->CALL_DCN
    EXPORTING
*     HTTP_RFC_DEST           = 'SMPTUTORIALS'
*     HTTP_RFC_DEST           = 'SMPTUTORIALS_BASIC'
      HTTP_RFC_DEST           = 'SUPES01_BASIC'
*     HTTP_RFC_DEST           = 'SPL_ECHO'
      DCN_HTTP_AUTH           = 'X'  "Set this to true if you're using the HttpAuthDCNServlet
    IMPORTING
      HTTP_STATUS_CODE        = http_status_code
      HTTP_STATUS_MESSAGE     = http_status_message
      RESPONSE_TEXT           = response_text
      DCN_RESPONSE            = dcn_response
    EXCEPTIONS
      ERROR_IN_HTTP_SEND_CALL = 1.

  if sy-subrc ne 0.

    write 'Error en la llamada al DCN'.

  else.
*  break-point id z_dcn.

* Display results:
    format color col_heading.
    write: / 'Form Fields:'.
    format color col_key.
    loop at sup_dcn->form_fields into wa_tnvp.
      write: / wa_tnvp-name, wa_tnvp-value.
    endloop.
    uline.

    format color col_normal.
    write: / 'HTTP code', http_status_code.
    write: / 'HTTP message', http_status_message.
    write: / 'Response body:'.
    write response_text.
    uline.

    if http_status_code eq 200.
      nlines = lines( dcn_response ).
      write: / nlines, ' lines sent to SUP successfully.'.
      uline.
    endif.

    format color col_heading.
    write: (32) 'recordID',  'success',  'statusMessage'.
    format color col_key.
    loop at dcn_response into wa_dcnresp.
      write: / wa_dcnresp-recordid under 'recordID', wa_dcnresp-success under 'success', wa_dcnresp-statusMessage under 'statusMessage'.
    endloop.


  endif.