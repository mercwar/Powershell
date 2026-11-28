@echo off
title GitHub Repo Node Dir List
setlocal

set "GITHUB_USER=mercwar"
set "API_URL=https://api.github.com/users/%GITHUB_USER%/repos?per_page=100"
set "JSON_FILE=%TEMP%\github_repos_%GITHUB_USER%.json"
set "KEYS_FILE=%TEMP%\github_keys_%GITHUB_USER%.txt"
set "AWK_KEYS=%TEMP%\github_keys_%GITHUB_USER%.awk"
set "AWK_VALS=%TEMP%\github_vals_%GITHUB_USER%.awk"

for /f "delims=" %%G in ('where git 2^>nul') do (
    if exist "%%~dpG..\usr\bin\awk.exe" (
        set "PATH=%%~dpG..\usr\bin;%PATH%"
        goto :found_awk
    )
)
:found_awk

where awk.exe >nul 2>&1
if errorlevel 1 (
    echo [ERROR] awk.exe not found. Install Git for Windows.
    pause
    exit /b 1
)

if exist "1" del /q "1" >nul 2>&1

echo.
echo Fetching repositories for %GITHUB_USER%...
curl -sL -H "User-Agent: BatchNodeDir" -H "Accept: application/vnd.github+json" "%API_URL%" > "%JSON_FILE%"

if not exist "%JSON_FILE%" (
    echo [ERROR] Download failed.
    pause
    exit /b 1
)

:: 1) Build menu keys from the downloaded JSON file
if exist "%AWK_KEYS%" del /q "%AWK_KEYS%" >nul 2>&1
>> "%AWK_KEYS%" echo {
>> "%AWK_KEYS%" echo     gsub(/\r/, "", $0)
>> "%AWK_KEYS%" echo     buf = buf " " $0
>> "%AWK_KEYS%" echo }
>> "%AWK_KEYS%" echo END {
>> "%AWK_KEYS%" echo     start = index(buf, "\"id\"")
>> "%AWK_KEYS%" echo     if (start == 0) exit
>> "%AWK_KEYS%" echo     sub_buf = substr(buf, start)
>> "%AWK_KEYS%" echo     n = split(sub_buf, parts, "\"")
>> "%AWK_KEYS%" echo     for (i = 2; i ^< n; i += 2) {
>> "%AWK_KEYS%" echo         key = parts[i]
>> "%AWK_KEYS%" echo         after = parts[i + 1]
>> "%AWK_KEYS%" echo         if (key == "owner") break
>> "%AWK_KEYS%" echo         if (after ~ /^[ \t]*:/ ^&^& key ~ /^[a-zA-Z0-9_]+$/ ^&^& !seen[key]++) {
>> "%AWK_KEYS%" echo             print key
>> "%AWK_KEYS%" echo         }
>> "%AWK_KEYS%" echo     }
>> "%AWK_KEYS%" echo     cpos = index(sub_buf, "\"created_at\"")
>> "%AWK_KEYS%" echo     if (cpos ^> 0) {
>> "%AWK_KEYS%" echo         rest = substr(sub_buf, cpos)
>> "%AWK_KEYS%" echo         m = split(rest, rparts, "\"")
>> "%AWK_KEYS%" echo         for (j = 2; j ^< m; j += 2) {
>> "%AWK_KEYS%" echo             rkey = rparts[j]
>> "%AWK_KEYS%" echo             rafter = rparts[j + 1]
>> "%AWK_KEYS%" echo             if (rafter ~ /^[ \t]*:/ ^&^& rkey ~ /^[a-zA-Z0-9_]+$/ ^&^& !seen[rkey]++) {
>> "%AWK_KEYS%" echo                 print rkey
>> "%AWK_KEYS%" echo             }
>> "%AWK_KEYS%" echo         }
>> "%AWK_KEYS%" echo     }
>> "%AWK_KEYS%" echo }

awk -f "%AWK_KEYS%" "%JSON_FILE%" > "%KEYS_FILE%"
:: 2) Print clean dir-style columns: <repo_name>  <selected_value>
if exist "%AWK_VALS%" del /q "%AWK_VALS%" >nul 2>&1
>> "%AWK_VALS%" echo {
>> "%AWK_VALS%" echo     gsub(/\r/, "", $0)
>> "%AWK_VALS%" echo     buf = buf " " $0
>> "%AWK_VALS%" echo }
>> "%AWK_VALS%" echo END {
>> "%AWK_VALS%" echo     key = ENVIRON["TARGET_NODE"]
>> "%AWK_VALS%" echo     if (key == "") exit
>> "%AWK_VALS%" echo     n = split(buf, segs, "\"full_name\"")
>> "%AWK_VALS%" echo     count = 0
>> "%AWK_VALS%" echo     pat_obj = "\"" key "\"[ \t]*:[ \t]*\\{[^}]*\\}"
>> "%AWK_VALS%" echo     pat_q   = "\"" key "\"[ \t]*:[ \t]*\"[^\"]*\""
>> "%AWK_VALS%" echo     pat_u   = "\"" key "\"[ \t]*:[ \t]*[^,}\r\n]+"
>> "%AWK_VALS%" echo     for (s = 2; s ^<= n; s++) {
>> "%AWK_VALS%" echo         raw_chunk = segs[s]
>> "%AWK_VALS%" echo         chunk = raw_chunk
>> "%AWK_VALS%" echo         prev = segs[s - 1]
>> "%AWK_VALS%" echo         sub(/.*\},/, "", prev)
>> "%AWK_VALS%" echo         gsub(/"owner"[ \t]*:[ \t]*\{[^}]*\}/, "\"owner\":null", chunk)
>> "%AWK_VALS%" echo         gsub(/"license"[ \t]*:[ \t]*\{[^}]*\}/, "\"license\":null", chunk)
>> "%AWK_VALS%" echo         repo = ""
>> "%AWK_VALS%" echo         if (match(prev, /"name"[ \t]*:[ \t]*"[^"]+"/)) {
>> "%AWK_VALS%" echo             repo = substr(prev, RSTART, RLENGTH)
>> "%AWK_VALS%" echo             sub(/"name"[ \t]*:[ \t]*"/, "", repo)
>> "%AWK_VALS%" echo             gsub(/"/, "", repo)
>> "%AWK_VALS%" echo         }
>> "%AWK_VALS%" echo         src = chunk
>> "%AWK_VALS%" echo         if (key == "id" ^|^| key == "node_id" ^|^| key == "name") src = prev
>> "%AWK_VALS%" echo         val = "-"
>> "%AWK_VALS%" echo         if (key == "full_name") {
>> "%AWK_VALS%" echo             if (match(chunk, /:[ \t]*"[^"]+"/)) {
>> "%AWK_VALS%" echo                 val = substr(chunk, RSTART, RLENGTH)
>> "%AWK_VALS%" echo                 sub(/:[ \t]*"/, "", val)
>> "%AWK_VALS%" echo                 gsub(/"/, "", val)
>> "%AWK_VALS%" echo             }
>> "%AWK_VALS%" echo         } else if (match(raw_chunk, pat_obj)) {
>> "%AWK_VALS%" echo             val = substr(raw_chunk, RSTART, RLENGTH)
>> "%AWK_VALS%" echo             sub("\"" key "\"[ \t]*:[ \t]*", "", val)
>> "%AWK_VALS%" echo         } else if (match(src, pat_q)) {
>> "%AWK_VALS%" echo             val = substr(src, RSTART, RLENGTH)
>> "%AWK_VALS%" echo             sub("\"" key "\"[ \t]*:[ \t]*\"", "", val)
>> "%AWK_VALS%" echo             gsub(/"/, "", val)
>> "%AWK_VALS%" echo         } else if (match(src, pat_u)) {
>> "%AWK_VALS%" echo             val = substr(src, RSTART, RLENGTH)
>> "%AWK_VALS%" echo             sub("\"" key "\"[ \t]*:[ \t]*", "", val)
>> "%AWK_VALS%" echo             gsub(/^[ \t]+^|[ \t]+$/, "", val)
>> "%AWK_VALS%" echo             gsub(/"/, "", val)
>> "%AWK_VALS%" echo             if (val ~ /^\[/) val = "[array]"
>> "%AWK_VALS%" echo         }
>> "%AWK_VALS%" echo         if (val == "null" ^|^| val == "") val = "-"
>> "%AWK_VALS%" echo         if (repo != "") {
>> "%AWK_VALS%" echo             count++
>> "%AWK_VALS%" echo             printf "  %%-30s  %%s\n", repo, val
>> "%AWK_VALS%" echo         }
>> "%AWK_VALS%" echo     }
>> "%AWK_VALS%" echo     printf "\n  %%15d Repo(s)\n", count
>> "%AWK_VALS%" echo }



:menu
cls
set "NODE_COUNT=0"
echo.
echo  Directory of %GITHUB_USER% [%TARGET_NODE%]
echo.
for /f "usebackq delims=" %%K in ("%KEYS_FILE%") do (
    set /a NODE_COUNT+=1
    call :store_key %%NODE_COUNT%% "%%K"
    call echo   [%%NODE_COUNT%%] %%K
)
if "%NODE_COUNT%"=="0" (
    echo   No keys found.
)
echo.
echo   [R] Refresh   [Q] Quit
echo.
set "PICK="
set /p "PICK=Select node: "

if /i "%PICK%"=="Q" goto :cleanup
if /i "%PICK%"=="R" (
    curl -sL -H "User-Agent: BatchNodeDir" -H "Accept: application/vnd.github+json" "%API_URL%" > "%JSON_FILE%"
    awk -f "%AWK_KEYS%" "%JSON_FILE%" > "%KEYS_FILE%"
    goto :menu
)

set "TARGET_NODE="
call set "TARGET_NODE=%%NODE_%PICK%%%"
if not defined TARGET_NODE goto :menu

cls
echo.
echo  Directory of %GITHUB_USER% - %TARGET_NODE%
echo.
awk -f "%AWK_VALS%" "%JSON_FILE%"
echo.
pause
goto :menu

:store_key
set "NODE_%~1=%~2"
goto :eof

:cleanup
if exist "%KEYS_FILE%" del /q "%KEYS_FILE%" >nul 2>&1
if exist "%AWK_KEYS%" del /q "%AWK_KEYS%" >nul 2>&1
if exist "%AWK_VALS%" del /q "%AWK_VALS%" >nul 2>&1
endlocal
exit /b 0
