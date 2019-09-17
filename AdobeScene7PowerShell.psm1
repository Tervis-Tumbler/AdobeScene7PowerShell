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

function Out-AdobeScene7UrlPrettyPrint {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]$URL = "http://images.tervis.com/is/agm/tervis/6_cstm_print?&setAttr.imgWrap={source=@Embed(%27is(tervisRender/6oz_wrap_final%3flayer=1%26src=ir(tervisRender/6_Warp_trans%3f%26obj=group%26decal%26src=is(tervisRender/6oz_base2%3f.BG%26layer=5%26anchor=0,0%26src=is(tervis/prj-aa1f3d62-dd31-411e-bc46-b7c963e77ae0))%26show%26res=300%26req=object%26fmt=png-alpha,rgb)%26fmt=png-alpha,rgb)%27)}&setAttr.maskWrap={source=@Embed(%27http://images.tervis.com/is/image/tervis%3fsrc=(http://images.tervis.com/is/image/tervisRender/6oz_wrap_mask%3f%26layer=1%26mask=is(tervisRender%3f%26src=ir(tervisRender/6_Warp_trans%3f%26obj=group%26decal%26src=is(tervisRender/6oz_base2%3f.BG%26layer=5%26anchor=0,0%26src=is(tervis/prj-aa1f3d62-dd31-411e-bc46-b7c963e77ae0))%26show%26res=300%26req=object%26fmt=png-alpha)%26op_grow=-2)%26scl=1)%26scl=1%26fmt=png8%26quantize=adaptive,off,2,ffffff,00A99C%27)}&imageres=300&fmt=pdf,rgb&.v=72271&`$orderNum=11361062/2"
    )
    process {
        $URLDecoded = $URL -replace "%26","&" -replace "%27","'" -replace "%3f","?" -replace "%7b", "{" -replace "%7d","}"
        $StringBuilder = New-Object -TypeName System.Text.StringBuilder
        $CharactersToBreakAfter = "?"
        $CharactersToBreakBefore = "&"
        $CharactersToIndentOn = "{","("
        $CharactersToUnindentOn = "}",")"
        $IndentionLevel = 0
    
        foreach ($Character in $URLDecoded.ToCharArray()) {
            if ($Character -in $CharactersToBreakAfter) {
                [Void]$StringBuilder.Append("$Character`n")
                [Void]$StringBuilder.Append("    " * $IndentionLevel)
            } elseif ($Character -in $CharactersToBreakBefore) {
                if ($StringBuilder[-1] -notin " ","`n") {
                    [Void]$StringBuilder.Append("`n")
                    [Void]$StringBuilder.Append("    " * $IndentionLevel)    
                }
                [Void]$StringBuilder.Append($Character)
            } elseif ($Character -in $CharactersToIndentOn) {
                [Void]$StringBuilder.Append("$Character`n")
                $IndentionLevel += 1
                [Void]$StringBuilder.Append("    " * $IndentionLevel)
            } elseif ($Character -in $CharactersToUnindentOn) {
                $IndentionLevel -= 1
                [Void]$StringBuilder.Append("`n")
                [Void]$StringBuilder.Append("    " * $IndentionLevel)
                [Void]$StringBuilder.Append("$Character")
            } else {
                [Void]$StringBuilder.Append("$Character")
            }
        }
        $StringBuilder.ToString()
    }
}