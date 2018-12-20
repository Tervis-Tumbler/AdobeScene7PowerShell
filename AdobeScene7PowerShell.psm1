function Get-Scene7URLComponents {
    param (
        $URL
    )

    $URL |
    Add-Member -MemberType ScriptProperty -Name QueryStringParameters -Value {
        $Parameters = $This.Query.TrimStart("?") |
        ConvertFrom-URLEncodedQueryStringParameterString

        $Parameters.psobject.Properties |
        ForEach-Object {
            $ObjectFromJSON = try {$_.value | ConvertFrom-Json} catch {}
            if ($ObjectFromJSON) {
                $Parameters |
                Add-Member -MemberType NoteProperty -Force -Name $_.Name -Value $ObjectFromJSON
            }
        }
        $Parameters
    }

    $URL.Query.TrimStart("?") | ConvertFrom-URLEncodedQueryStringParameterString
    $URL.QueryStringParameters.'setAttr.imgWrap'
}


function Get-AdobeScene7URLSourceEmbedContent {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]$SourceEmbedExpression
    )
    process {
        $Content = $SourceEmbedExpression -replace "^{" `
            -replace "}$" `
            -replace "^source=@Embed\('" `
            -replace "'\)$"
        
        $Token = $Content -split "\(" | Select-Object -First 1
        if ($Token -eq "is") {
            $Content -replace "^is\(" -replace "\)$"
        } else {
            $Content
        }
    }
}

function ConvertTo-Scene7URLEncodedQueryStringParameterString {
    param (
        [Parameter(ValueFromPipeline)]$PipelineInput,
        [Switch]$MakeParameterNamesLowerCase
    )
    process {
        if ($PipelineInput.keys) {
            
            foreach ($Key in $PipelineInput.Keys) {
                if ($Key) {
                    if ($URLEncodedQueryStringParameterString) {
                        $URLEncodedQueryStringParameterString += "&"
                    }
                    
                    $ParameterName = if ($MakeParameterNamesLowerCase) {
                        $Key.ToLower()
                    } else {
                        $Key
                    }
    
                    $URLEncodedQueryStringParameterString += "$ParameterName=$(
                        $PipelineInput[$Key] | 
                        Replace-ContentValue -OldValue "&" -NewValue "%26" |
                        Replace-ContentValue -OldValue "?" -NewValue "%3f"
                    )"    
                }
            }
        }
    }
    end {
        $URLEncodedQueryStringParameterString
    }
}