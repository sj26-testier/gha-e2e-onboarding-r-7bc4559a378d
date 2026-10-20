$ErrorActionPreference = 'Stop'
$source = 'f21555d419953eb93176b39cd1d57642c05ba4c5'
$expectedRuntime = 'ede11d7cc699707664187c59b37f7155b9adbf9bca2b205a40a5771a6e9c80b1'
$process = Get-CimInstance Win32_Process -Filter "ProcessId=$PID"
$runtime = $null
for ($depth = 0; $depth -lt 5; $depth++) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($process.ParentProcessId)"
    if (-not $process) { break }
    if ($process.Name -eq 'buildkite-gha.exe') {
        $runtime = $process.ExecutablePath
        break
    }
}
if (-not $runtime -or -not [IO.Path]::IsPathFullyQualified($runtime)) { throw 'Executing runtime parent not found' }
$runtimeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $runtime).Hash.ToLowerInvariant()
if ($runtimeHash -ne $expectedRuntime) { throw 'Executing Windows runtime differs from published release' }
$runtimeVersion = (& $runtime --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $runtimeVersion -ne 'buildkite-gha 0.105.3') { throw 'Unexpected executing runtime version' }
$runtimeText = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($runtime))
if (-not $runtimeText.Contains("vcs.revision=$source")) { throw 'Executing runtime lacks expected embedded source revision' }
Write-Output "LAB_RELEASE_RUNTIME: version=$runtimeVersion sha256=$runtimeHash source=$source"

# This is the original synthetic consumer. Never assign JAVA_HOME or bridge it.
if (-not $env:JAVA_HOME -or -not [IO.Path]::IsPathFullyQualified($env:JAVA_HOME)) { throw 'Host-provided JAVA_HOME missing or relative' }
$java = "$env:JAVA_HOME\bin\java.exe"
if (-not (Test-Path -LiteralPath $java -PathType Leaf)) { throw 'JAVA_HOME consumer executable absent' }
$javaOutput = & "$env:JAVA_HOME\bin\java.exe" -version 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw 'Original JAVA_HOME consumer failed' }
Write-Output 'LAB_JAVA_HOME_CONSUMER_PASS: exit=0'
Write-Output $javaOutput.Trim()
$javac = Join-Path $env:JAVA_HOME 'bin\javac.exe'
if (-not (Test-Path -LiteralPath $javac -PathType Leaf)) {
    $existingCompiler = Get-Command javac.exe -ErrorAction SilentlyContinue
    $javac = if ($existingCompiler) { $existingCompiler.Source } else { $null }
}
$compile = @{ state = 'skipped'; reason = 'javac not installed in JAVA_HOME or ordinary PATH' }
if ($javac) {
    $compilerVersion = (& $javac -version 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Installed javac version command failed' }
    $classes = Join-Path $PWD '.lab\java-out'
    New-Item -ItemType Directory -Path $classes -Force | Out-Null
    & $javac -encoding UTF-8 -d $classes '.lab/LabJavaProbe.java'
    if ($LASTEXITCODE -ne 0) { throw 'Installed javac compilation failed' }
    $result = (& "$env:JAVA_HOME\bin\java.exe" -cp $classes LabJavaProbe 13 MiXeD | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $result -ne 'LAB_JAVA_OK:94:MIXED') { throw 'Compiled Java program returned wrong result' }
    $compile = @{ state = 'passed'; executable = $javac; version = $compilerVersion; result = $result }
    Write-Output "LAB_JAVA_COMPILE_PASS: $result"
} else {
    Write-Output 'LAB_JAVA_COMPILE_SKIPPED: javac not installed; no installation attempted'
}
$windows = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$observation = @{
    synthetic = $true
    runtime = @{ version = $runtimeVersion; sha256 = $runtimeHash; source = $source; executable = $runtime }
    java = @{ home = $env:JAVA_HOME; executable = $java; sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $java).Hash.ToLowerInvariant(); version = $javaOutput.Trim(); compile = $compile }
    os = @{ product = $windows.ProductName; build = $windows.CurrentBuild; ubr = $windows.UBR; image_version_hint = $env:ImageVersion }
}
Write-Output ('LAB_RELEASED_PROBE: ' + ($observation | ConvertTo-Json -Depth 6 -Compress))
