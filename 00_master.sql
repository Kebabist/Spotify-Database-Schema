-- Master Runner (SQLCMD mode)
-- Run this file first in SSMS with SQLCMD mode enabled,
-- or run the section files individually in numbered order.

:setvar path "C:\Users\FFear\OneDrive\Desktop\40120453_Jafari Hombari"

:r $(path)\01_schema.sql
:r $(path)\02_sample_data.sql
:r $(path)\03_security.sql
:r $(path)\04_transactions.sql
:r $(path)\05_functions_and_procedures.sql
:r $(path)\06_triggers.sql
:r $(path)\07_import_export_xml.sql
:r $(path)\08_reporting.sql