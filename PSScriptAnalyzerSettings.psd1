@{
    # Use Severity levels to limit the generated diagnostic records
    Severity = @('Error', 'Warning', 'Information')
    
    # Analyze **only** the following rules. Use IncludeRules when you want
    # to invoke only a small subset of the default rules.
    IncludeRules = @(
        'PSAvoidDefaultValueSwitchParameter',
        'PSAvoidDefaultValueForMandatoryParameter',
        'PSAvoidInvokingEmptyMembers',
        'PSAvoidNullOrEmptyHelpMessageAttribute',
        'PSAvoidOverwritingBuiltInCmdlets',
        'PSAvoidShouldContinueWithoutForce',
        'PSAvoidTrailingWhitespace',
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingComputerNameHardcoded',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidUsingUsernameAndPasswordParams',
        'PSAvoidUsingWMICmdlet',
        'PSAvoidUsingWriteHost',
        'PSDSCReturnCorrectTypesForDSCFunctions',
        'PSDSCStandardDSCFunctionsInResource',
        'PSDSCUseIdenticalMandatoryParametersForDSC',
        'PSDSCUseIdenticalParametersForDSC',
        'PSMisleadingBacktick',
        'PSMissingModuleManifestField',
        'PSPlaceCloseBrace',
        'PSPlaceOpenBrace',
        'PSPossibleIncorrectComparisonWithNull',
        'PSPossibleIncorrectUsageOfAssignmentOperator',
        'PSPossibleIncorrectUsageOfRedirectionOperator',
        'PSProvideCommentHelp',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSReviewUnusedParameter',
        'PSShouldProcess',
        'PSUseApprovedVerbs',
        'PSUseBOMForUnicodeEncodedFile',
        'PSUseCmdletCorrectly',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSUseCorrectCasing',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUseIdenticalMandatoryParametersDSC',
        'PSUseIdenticalParametersDSC',
        'PSUseLiteralInitializerForHashtable',
        'PSUseOutputTypeCorrectly',
        'PSUseProcessBlockForPipelineCommand',
        'PSUsePSCredentialType',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseSingularNouns',
        'PSUseSupportsShouldProcess',
        'PSUseToExportFieldsInManifest',
        'PSUseUTF8EncodingForHelpFile',
        'PSUseVerboseMessageInDSCResource'
    )
    
    # Do not analyze the following rules. Use ExcludeRules when you have
    # commented out the IncludeRules settings above and want to include all
    # the default rules except for those you exclude below.
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'  # We use Write-Host for console output in scripts
    )
    
    # You can use rule configuration to configure rules that support it:
    Rules = @{
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }
        
        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore = $false
        }
        
        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            IndentationSize = 4
        }
        
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator = $true
            CheckParameter = $false
        }
        
        PSAlignAssignmentStatement = @{
            Enable = $true
            CheckHashtable = $true
        }
        
        PSUseCorrectCasing = @{
            Enable = $true
        }
    }
}# Auto-updated 20251109_123235
