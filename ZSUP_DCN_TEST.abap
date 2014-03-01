*&---------------------------------------------------------------------*
*& Report  ZSUP_DCN_TEST
*&
*&---------------------------------------------------------------------*
*&
*& Test report for showing usage of the ZCL_SUP_DCN class.
*& For more info read:
*& http://scn.sap.com/community/developer-center/mobility-platform/blog/2012/06/11/calling-the-sup-data-change-notification-from-abap
*&---------------------------------------------------------------------*

report  zsup_dcn_test line-size 1023 no standard page heading.

types:
begin of mbotype,
  username type string,
  firstname type string,
  lastname type string,
  fullname type string,
end of mbotype.

data:
   mbocols type mbotype,
   http_status_code type I,
   http_status_message type string,
   response_text type string,
   wa_tnvp type line of tihttpnvp,
   dcn_response type zsup_dcn_response_tab,
   wa_dcnresp type line of zsup_dcn_response_tab,
   sup_dcn type ref to zcl_sup_dcn.


CREATE OBJECT SUP_DCN
  EXPORTING
   PACKAGE  = 'colomer01:1.0'
*   CMD      = 'dcn'
*   SECURITY = 'default'
*   USERNAME = 'supAdmin'
*   PASSWORD = 's3pAdmin'
*   DOMAIN   = 'default'
*   MESSAGES = t_messages
.

mbocols-username = 'jrubi'.
mbocols-firstname = 'Jose'.
mbocols-lastname = 'Rubio'.
mbocols-fullname = 'Jose Rub’'.

sup_dcn->add_message( id = '1' mbo = 'UserData' op = 'upsert' cols = mbocols ).

clear mbocols.
mbocols-username = 'arodriguez'.
mbocols-firstname = 'Antonio'.
mbocols-lastname = 'Rodriguez'.
mbocols-fullname = 'Antonio Rodr’guez'.

* If you omit the ID, the method will generate a UUID automatically
sup_dcn->add_message(  mbo = 'UserData' op = 'upsert' cols = mbocols ).

clear mbocols.
mbocols-username = 'tmaza'.
mbocols-firstname = 'Tomas'.
mbocols-lastname = 'Maza'.
mbocols-fullname = 'Tom‡s Maza'.

*sup_dcn->add_message(  mbo = 'UserData' op = 'fallar' cols = mbocols ).
sup_dcn->add_message(  mbo = 'UserData' op = 'insert' cols = mbocols ).

clear mbocols.
mbocols-username = 'jrubi'. " Set MBO key to delete (logically only)

*sup_dcn->add_message(  mbo = 'UserData_falla' op = 'del' cols = mbocols ).
sup_dcn->add_message(  mbo = 'UserData' op = 'del' cols = mbocols ).



*break-point id z_dcn.
*sup_dcn->prepare( ).


write: / 'Calling server:'.
uline.

CALL METHOD SUP_DCN->CALL_DCN
  EXPORTING
*    HTTP_RFC_DEST           = 'SUPES01'
    HTTP_RFC_DEST           = 'SUPES01_BASIC'
*    HTTP_RFC_DEST           = 'SPL_ECHO'
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

  format color col_heading.
  write: (32) 'recordID',  'success',  'statusMessage'.
  format color col_key.
  loop at dcn_response into wa_dcnresp.
    write: / wa_dcnresp-recordid under 'recordID', wa_dcnresp-success under 'success', wa_dcnresp-statusMessage under 'statusMessage'.
  endloop.


endif.