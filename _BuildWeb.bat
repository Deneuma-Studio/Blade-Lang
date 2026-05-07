cd emsdk
call emsdk activate 4.0.20
cd ..
scons platform=web target=template_debug disable_exceptions=false
::  threads=no
pause