REM Run the ruby script

REM Move to the path this batch file is in.
REM %0 is the name of the batch file.
REM ~dp gives you the drive and path of the specified argument.
REM cd /d %~dp0
echo.>nul & cd /d %0\.. & goto :skip
%0\
cd %0\..
:skip
ruby run_edi_out_proc c:\edi_test\edi_out 3 normal

