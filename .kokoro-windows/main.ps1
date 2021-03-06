# Copyright(c) 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

Push-Location
try {
    # Import BuildTools.psm1
    $private:invocation = (Get-Variable MyInvocation -Scope 0).Value
    Set-Location (Join-Path (Split-Path $invocation.MyCommand.Path) ..)
    Import-Module  .\BuildTools.psm1 -DisableNameChecking

    # Import secrets:
    .\.kokoro-windows\Import-Secrets.ps1
    
    # Update all the web.config xml files with project name and other
    # settings from environment variables.
    $modifiedConfigs = Update-Config    

    # The list of all subdirectories.
    $dirs = Get-ChildItem | Where-Object {$_.PSIsContainer} | Select-Object -ExpandProperty Name

    # Find all the runTest scripts.
    $scripts = Get-ChildItem -Path $dirs -Filter *runTest*.ps* -Recurse
    $scripts.VersionInfo.FileName `
        | Sort-Object -Descending -Property {Get-GitTimeStampForScript $_} `
        | Run-TestScripts -TimeoutSeconds 600
} finally {
    Revert-Config $modifiedConfigs
    Pop-Location
}

