@echo off
dcc32 dll\AgeKey.dpr
brcc32 -l0409 exe\AgeKey.rc -foexe\AgeKey.res
dcc32 exe\AgeKey.dpr
copy exe\AgeKey.exe AgeKey.exe
rem upx --best AgeKey.exe
pause
