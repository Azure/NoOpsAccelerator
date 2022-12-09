#Requires -Version 7

param (
    [Parameter(Mandatory = $false)]
    [array] $moduleFolderPaths = ((Get-ChildItem $repoRootPath -Recurse -Directory -Force).FullName | Where-Object {
        (Get-ChildItem $_ -File -Depth 0 -Include @('deploy.json', 'deploy.bicep') -Force).Count -gt 0
        }),

    [Parameter(Mandatory = $false)]
    [string] $repoRootPath = (Get-Item $PSScriptRoot).Parent.Parent.Parent.FullName,

    # Dedicated Tokens configuration hashtable containing the tokens and token prefix and suffix.
    [Parameter(Mandatory = $false)]
    [hashtable] $tokenConfiguration = @{}
)

Write-Verbose ("repoRootPath: $repoRootPath") -Verbose
Write-Verbose ("moduleFolderPaths: $($moduleFolderPaths.count)") -Verbose

$script:RGdeployment = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
$script:Subscriptiondeployment = 'https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#'
$script:MGdeployment = 'https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#'
$script:Tenantdeployment = 'https://schema.management.azure.com/schemas/2019-08-01/tenantDeploymentTemplate.json#'
$script:moduleFolderPaths = $moduleFolderPaths

# For runtime purposes, we cache the compiled template in a hashtable that uses a formatted relative module path as a key
$script:convertedTemplates = @{}

# Shared exception messages
$script:bicepTemplateCompilationFailedException = "Unable to compile the deploy.bicep template's content. This can happen if there is an error in the template. Please check if you can run the command ``az bicep build --file {0} --stdout | ConvertFrom-Json -AsHashtable``." # -f $templateFilePath
$script:jsonTemplateLoadFailedException = "Unable to load the deploy.json template's content. This can happen if there is an error in the template. Please check if you can run the command `Get-Content {0} -Raw | ConvertFrom-Json -AsHashtable`." # -f $templateFilePath
$script:templateNotFoundException = 'No template file found in folder [{0}]' # -f $moduleFolderPath

# Import any helper function used in this test script
Import-Module (Join-Path $PSScriptRoot 'helper' 'helper.psm1') -Force

Describe 'File/folder tests' -Tag Modules {

    Context 'General module folder tests' {

        $moduleFolderTestCases = [System.Collections.ArrayList] @()
        foreach ($moduleFolderPath in $moduleFolderPaths) {
            $moduleFolderTestCases += @{
                moduleFolderName = $moduleFolderPath.Replace('\', '/').Split('/platforms/')[1]
                moduleFolderPath = $moduleFolderPath
                isTopLevelModule = $moduleFolderPath.Replace('\', '/').Split('/platforms/')[1].Split('/').Count -eq 2 # <provider>/<resourceType>
            }
        }

        if (Test-Path (Join-Path $repoRootPath '.github')) {
            It '[<moduleFolderName>] Module should have a GitHub workflow' -TestCases ($moduleFolderTestCases | Where-Object { $_.isTopLevelModule }) {

                param(
                    [string] $moduleFolderName,
                    [string] $moduleFolderPath
                )

                $workflowsFolderName = Join-Path $repoRootPath '.github' 'workflows'
                $workflowFileName = '{0}.yml' -f $moduleFolderName.Replace('\', '/').Replace('/', '.').ToLower()
                $workflowPath = Join-Path $workflowsFolderName $workflowFileName
                Test-Path $workflowPath | Should -Be $true -Because "path [$workflowPath] should exist."
            }
        }        

        It '[<moduleFolderName>] Module should contain a [deploy.json/deploy.bicep] file' -TestCases $moduleFolderTestCases {

            param( [string] $moduleFolderPath )

            $hasARM = (Test-Path (Join-Path -Path $moduleFolderPath 'deploy.json'))
            $hasBicep = (Test-Path (Join-Path -Path $moduleFolderPath 'deploy.bicep'))
            ($hasARM -or $hasBicep) | Should -Be $true
        }

        It '[<moduleFolderName>] Module should contain a [readme.md] file' -TestCases $moduleFolderTestCases {

            param( [string] $moduleFolderPath )
            (Test-Path (Join-Path -Path $moduleFolderPath 'readme.md')) | Should -Be $true
        }

        It '[<moduleFolderName>] Module should contain a [parameters] folder' -TestCases ($moduleFolderTestCases | Where-Object { $_.isTopLevelModule }) {

            param( [string] $moduleFolderPath )
            Test-Path (Join-Path -Path $moduleFolderPath 'parameters') | Should -Be $true
        }

        It '[<moduleFolderName>] Module should contain a [tests] folder' -TestCases ($moduleFolderTestCases | Where-Object { $_.isTopLevelModule }) {

            param( [string] $moduleFolderPath )
            Test-Path (Join-Path -Path $moduleFolderPath 'tests') | Should -Be $true
        }
    }

    Context 'parameters folder' {

        $parametersFolderTestCases = [System.Collections.ArrayList]@()
        foreach ($moduleFolderPath in $moduleFolderPaths) {
            if (Test-Path (Join-Path $moduleFolderPath 'parameters')) {
                $folderTestCases += @{
                    moduleFolderName = $moduleFolderPath.Replace('\', '/').Split('/platforms/')[1]
                    moduleFolderPath = $moduleFolderPath
                }
            }
        }

        It '[<moduleFolderName>] folder should contain one or more parameter files' -TestCases $parametersFolderTestCases {

            param(
                [string] $moduleFolderName,
                [string] $moduleFolderPath
            )

            $moduleTestFilePaths = Get-ModuleTestFileList -ModulePath $moduleFolderPath | ForEach-Object { Join-Path $moduleFolderPath $_ }
            $moduleTestFilePaths.Count | Should -BeGreaterThan 0
        }

        $parametersFolderFilesTestCases = [System.Collections.ArrayList] @()
        foreach ($moduleFolderPath in $moduleFolderPaths) {
            $parametersFolderPath = Join-Path $moduleFolderPath 'parameters'
            if (Test-Path $parametersFolderPath) {
                foreach ($parametersFilePath in (Get-ModuleTestFileList -ModulePath $moduleFolderPath | ForEach-Object { Join-Path $moduleFolderPath $_ })) {
                    $parametersFolderFilesTestCases += @{
                        moduleFolderName = $moduleFolderPath.Replace('\', '/').Split('/platforms/')[1]
                        parametersFilePath     = $parametersFilePath
                    }
                }
            }
        }

        It '[<moduleFolderName>] JSON files in the parameters folder should be valid json' -TestCases $parametersFolderFilesTestCases {

            param(
                [string] $moduleFolderName,
                [string] $parametersFilePath
            )
            if ((Split-Path $parametersFilePath -Extension) -eq '.json') {
                { (Get-Content $parametersFilePath) | ConvertFrom-Json } | Should -Not -Throw
            }
            else {
                Set-ItResult -Skipped -Because 'the module has no JSON parameter files.'
            }
        }
    }


    Context 'tests folder' {

        $folderTestCases = [System.Collections.ArrayList]@()
        foreach ($moduleFolderPath in $moduleFolderPaths) {
            if (Test-Path (Join-Path $moduleFolderPath 'tests')) {
                $folderTestCases += @{
                    moduleFolderName = $moduleFolderPath.Replace('\', '/').Split('/platforms/')[1]
                    moduleFolderPath = $moduleFolderPath
                }
            }
        }

        It '[<moduleFolderName>] folder should contain one or more test files' -TestCases $folderTestCases {

            param(
                [string] $moduleFolderName,
                [string] $moduleFolderPath
            )

            $moduleTestFilePaths = Get-ModuleTestFileList -ModulePath $moduleFolderPath | ForEach-Object { Join-Path $moduleFolderPath $_ }
            $moduleTestFilePaths.Count | Should -BeGreaterThan 0
        }

        $testFolderFilesTestCases = [System.Collections.ArrayList] @()
        foreach ($moduleFolderPath in $moduleFolderPaths) {
            $testFolderPath = Join-Path $moduleFolderPath '.test'
            if (Test-Path $testFolderPath) {
                foreach ($testFilePath in (Get-ModuleTestFileList -ModulePath $moduleFolderPath | ForEach-Object { Join-Path $moduleFolderPath $_ })) {
                    $testFolderFilesTestCases += @{
                        moduleFolderName = $moduleFolderPath.Replace('\', '/').Split('/platforms/')[1]
                        testFilePath     = $testFilePath
                    }
                }
            }
        }

        It '[<moduleFolderName>] parameter folder should contain a [deploy.test.json/deploy.test.bicep] file' -TestCases $testFolderFilesTestCases {

            param( [string] $moduleFolderPath )

            $hasARM = (Test-Path (Join-Path -Path $moduleFolderPath 'deploy.test.json'))
            $hasBicep = (Test-Path (Join-Path -Path $moduleFolderPath 'deploy.test.bicep'))
            ($hasARM -or $hasBicep) | Should -Be $true
        }

        It '[<moduleFolderName>] parameter folder should contain a [testRunner.bicep] file' -TestCases $testFolderFilesTestCases {

            param( [string] $moduleFolderPath )

            $hasBicep = (Test-Path (Join-Path -Path $moduleFolderPath 'testRunner.bicep'))
            ($hasBicep) | Should -Be $true
        }
    }
}
<# Describe 'Readme tests' -Tag Readme {

    Context 'Readme content tests' {

        $readmeFolderTestCases = [System.Collections.ArrayList] @()
        foreach ($moduleFolderPath in $moduleFolderPaths) {

            # For runtime purposes, we cache the compiled template in a hashtable that uses a formatted relative module path as a key
            $moduleFolderPathKey = $moduleFolderPath.Replace('\', '/').Split('/platforms/')[1].Trim('/').Replace('/', '-')
            if (-not ($convertedTemplates.Keys -contains $moduleFolderPathKey)) {
                if (Test-Path (Join-Path $moduleFolderPath 'deploy.bicep')) {
                    $templateFilePath = Join-Path $moduleFolderPath 'deploy.bicep'
                    $templateContent = az bicep build --file $templateFilePath --stdout | ConvertFrom-Json -AsHashtable

                    if (-not $templateContent) {
                        throw ($bicepTemplateCompilationFailedException -f $templateFilePath)
                    }
                }
                elseIf (Test-Path (Join-Path $moduleFolderPath 'deploy.json')) {
                    $templateFilePath = Join-Path $moduleFolderPath 'deploy.json'
                    $templateContent = Get-Content $templateFilePath -Raw | ConvertFrom-Json -AsHashtable

                    if (-not $templateContent) {
                        throw ($jsonTemplateLoadFailedException -f $templateFilePath)
                    }
                }
                else {
                    throw ($templateNotFoundException -f $moduleFolderPath)
                }
                $convertedTemplates[$moduleFolderPathKey] = @{
                    templateFilePath = $templateFilePath
                    templateContent  = $templateContent
                }
            }
            else {
                $templateContent = $convertedTemplates[$moduleFolderPathKey].templateContent
                $templateFilePath = $convertedTemplates[$moduleFolderPathKey].templateFilePath
            }

            $resourceTypeIdentifier = $moduleFolderPath.Replace('\', '/').Split('/platforms/')[1]

            $readmeFolderTestCases += @{
                moduleFolderName       = $resourceTypeIdentifier
                moduleFolderPath       = $moduleFolderPath
                templateContent        = $templateContent
                templateFilePath       = $templateFilePath
                readMeFilePath         = Join-Path -Path $moduleFolderPath 'readme.md'
                readMeContent          = Get-Content (Join-Path -Path $moduleFolderPath 'readme.md')
                isTopLevelModule       = $resourceTypeIdentifier.Split('/').Count -eq 2 # <provider>/<resourceType>
                resourceTypeIdentifier = $resourceTypeIdentifier
                templateReferences     = (Get-CrossReferencedModuleList)[$resourceTypeIdentifier]
            }
        }

        It '[<moduleFolderName>] Readme.md file should not be empty' -TestCases $readmeFolderTestCases {

            param(
                [string] $moduleFolderName,
                [object[]] $readMeContent
            )
            $readMeContent | Should -Not -Be $null
        }

        It '[<moduleFolderName>] Readme.md file should contain these sections in order: Overview, Architecture, Pre-requisites, Parameters, Cleanup, Deployment examples' -TestCases $readmeFolderTestCases {

            param(
                [string] $moduleFolderName,
                [object[]] $readMeContent,
                [boolean] $isTopLevelModule
            )

            $expectedHeadersInOrder = @('Overview', 'Architecture', 'Pre-requisites', 'Parameters', 'Cleanup')

            if ($isTopLevelModule) {
                # Only top-level modules have parameter files and hence deployment examples
                $expectedHeadersInOrder += 'Deployment examples'
            }

            $actualHeadersInOrder = $readMeContent | Where-Object { $_ -like '#*' } | ForEach-Object { ($_ -replace '#', '').TrimStart() }

            $filteredActuals = $actualHeadersInOrder | Where-Object { $expectedHeadersInOrder -contains $_ }

            $missingHeaders = $expectedHeadersInOrder | Where-Object { $actualHeadersInOrder -notcontains $_ }
            $missingHeaders.Count | Should -Be 0 -Because ('the list of missing headers [{0}] should be empty' -f ($missingHeaders -join ','))

            $filteredActuals | Should -Be $expectedHeadersInOrder -Because 'the headers should exist in the expected order'
        }

        It '[<moduleFolderName>] Parameters section should contain a table for each existing parameter category in the following order: Required, Type, Allowed Values, Description' -TestCases $readmeFolderTestCases {

            param(
                [string] $moduleFolderName,
                [hashtable] $templateContent,
                [object[]] $readMeContent
            )

            $expectColumnsInOrder = @('Required Parameters', 'Type', 'Allowed Values', 'Description')

            ## Get all descriptions
            $descriptions = $templateContent.parameters.Values.metadata.description

            ## Get the module parameter categories
            $expectedParamCategories = $descriptions | ForEach-Object { $_.Split('.')[0] } | Select-Object -Unique # Get categories in template
            $expectedParamCategoriesInOrder = $expectColumnsInOrder | Where-Object { $_ -in $expectedParamCategories } # add required ones in order
            $expectedParamCategoriesInOrder += $expectedParamCategories | Where-Object { $_ -notin $expectColumnsInOrder } # add non-required ones after

            $actualParamCategories = $readMeContent | Select-String -Pattern '^\*\*(.+) parameters\*\*$' -AllMatches | ForEach-Object { $_.Matches.Groups[1].Value } # get actual in readme

            $actualParamCategories | Should -Be $expectedParamCategoriesInOrder
        }

        It '[<moduleFolderName>] parameter tables should provide columns in the following order: Parameter Name, Type, Default Value, Allowed Values, Description. Each column should be present unless empty for all the rows.' -TestCases $readmeFolderTestCases {

            param(
                [string] $moduleFolderName,
                [hashtable] $templateContent,
                [object[]] $readMeContent
            )

            ## Get all descriptions
            $descriptions = $templateContent.parameters.Values.metadata.description

            ## Get the module parameter categories
            $paramCategories = $descriptions | ForEach-Object { $_.Split('.')[0] } | Select-Object -Unique

            foreach ($paramCategory in $paramCategories) {

                # Filter to relevant items
                [array] $categoryParameters = $templateContent.parameters.Values | Where-Object { $_.metadata.description -like "$paramCategory. *" } | Sort-Object -Property 'Name' -Culture 'en-US'

                # Check properties for later reference
                $shouldHaveDefault = $categoryParameters.defaultValue.count -gt 0
                $shouldHaveAllowed = $categoryParameters.allowedValues.count -gt 0

                $expectedColumnsInOrder = @('Parameter Name', 'Type')
                if ($shouldHaveDefault) { $expectedColumnsInOrder += @('Default Value') }
                if ($shouldHaveAllowed) { $expectedColumnsInOrder += @('Allowed Values') }
                $expectedColumnsInOrder += @('Description')

                $readMeCategoryIndex = $readMeContent | Select-String -Pattern "^\*\*$paramCategory parameters\*\*$" | ForEach-Object { $_.LineNumber }

                $tableStartIndex = $readMeCategoryIndex
                while ($readMeContent[$tableStartIndex] -notlike '*|*' -and -not ($tableStartIndex -ge $readMeContent.count)) {
                    $tableStartIndex++
                }

                $readmeCategoryColumns = ($readMeContent[$tableStartIndex] -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { -not [String]::IsNullOrEmpty($_) }
                $readmeCategoryColumns | Should -Be $expectedColumnsInOrder
            }
        }            
    }
} #>

<# Describe 'Parameter file tests' -Tag 'Parameter' {

    Context 'Deployment test file tests' {

        $deploymentTestFileTestCases = @()

        foreach ($moduleFolderPath in $moduleFolderPaths) {
            if (Test-Path (Join-Path $moduleFolderPath 'tests')) {
                $testFilePaths = Get-ModuleTestFileList -ModulePath $moduleFolderPath | ForEach-Object { Join-Path $moduleFolderPath $_ }
                foreach ($testFilePath in $testFilePaths) {
                    $testFileContent = Get-Content $testFilePath

                    if ((Split-Path $testFilePath -Extension) -eq '.bicep') {
                        # Skip any classic parameter files
                        $contentHashtable = $testFileContent | ConvertFrom-Json -Depth 99
                        $isParameterFile = $contentHashtable.'$schema' -like '*deploymentParameters*'
                        if ($isParameterFile) {
                            continue
                        }
                    }

                    $deploymentTestFileTestCases += @{
                        testFilePath     = $testFilePath
                        testFileContent  = $testFileContent
                        moduleFolderName = $moduleFolderPath.Replace('\', '/').Split('/platforms/')[1]
                    }
                }
            }
        }

        It "[<moduleFolderName>] Bicep test deployment files should invoke test like [module testDeployment '../.*deploy.bicep' = {]" -TestCases ($deploymentTestFileTestCases | Where-Object { (Split-Path $_.testFilePath -Extension) -eq '.bicep' }) {

            param(
                [object[]] $testFileContent
            )

            $testIndex = ($testFileContent | Select-String ("^module testDeployment '..\/.*testRunner.bicep' = {$") | ForEach-Object { $_.LineNumber - 1 })[0]

            $testIndex -ne -1 | Should -Be $true -Because 'the module test invocation should be in the expected format to allow identification.'
        }

        It '[<moduleFolderName>] Bicep test deployment name should contain [-test-]' -TestCases ($deploymentTestFileTestCases | Where-Object { (Split-Path $_.testFilePath -Extension) -eq '.bicep' }) {

            param(
                [object[]] $testFileContent
            )

            $expectedNameFormat = ($testFileContent | Out-String) -match '\s*name:.+-test-.+\s*'

            $expectedNameFormat | Should -Be $true -Because 'the handle ''-test-'' should be part of the module test invocation''s resource name to allow identification.'
        } 
    }    
} #>