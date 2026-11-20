<#
sm-python-server
edc-migration-job
diff-migration-job
jetty
dna-platform
msg-consumer
papermill_microservice
clickhouse-data-manager
datastage
jupyter-server
dbac-gateway-backend
clinical-model-web
jupyterhub
db-migration
mockingbird
#>


# ── Step 1: Parameters ────────────────────────────────────────
$repo    = "db-migration"
$tag     = "pr-36215-arm64"          # or use digest below
$aws_profile = "nphase"
$region  = "us-east-1"

# Force UTF-8 so the AWS CLI (Python) can output Unicode chars like ≫
$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8


# ── Step 2: Build filter → file ───────────────────────────────
$filterJson = '{"ecrImageRepositoryName":[{"comparison":"EQUALS","value":"' + $repo + '"}],"ecrImageTags":[{"comparison":"EQUALS","value":"' + $tag + '"}]}'
$filterJson | Out-File -Encoding ascii filter.json
Write-Host "Filter:" $filterJson

# ── Step 3: Paginate — collect every page into $allFindings ────
$allFindings = [System.Collections.Generic.List[object]]::new()
$nextToken   = $null
$page        = 0

#Turn OFF the CLI’s own auto-pagination or it fights your loop. The cleanest way is to set the environment variable for this session so each call returns exactly one page:
$env:AWS_PAGER = ""              # stop any pager blocking output
aws configure set cli_pagination off --profile $aws_profile   # one page per call

do {
    $page++

   $pageFile = "page_$page.json"
    if ($nextToken) {
        aws inspector2 list-findings `
            --filter-criteria file://filter.json `
            --max-results 100 --next-token $nextToken `
            --profile $aws_profile --region $region `
            --output json | Out-File -Encoding utf8 $pageFile
    } else {
        aws inspector2 list-findings `
            --filter-criteria file://filter.json `
            --max-results 100 `
            --profile $aws_profile --region $region `
            --output json | Out-File -Encoding utf8 $pageFile
    }

     try {
        $parsed = Get-Content $pageFile -Raw -Encoding utf8 | ConvertFrom-Json
    } catch {
        Write-Warning "Page $page failed to parse: $_"
        break   # or: continue, but at least you'll know
    }

    if ($parsed.findings) { $allFindings.AddRange($parsed.findings) }

    $nextToken = $parsed.nextToken
    Write-Host ("Page {0}: +{1}  (total {2})" -f $page, $parsed.findings.Count, $allFindings.Count)

} while ($nextToken)

Write-Host "`nTotal findings pulled:" $allFindings.Count

# ── Step 4: Shape fields ──────────────────────────────────────
$shaped = $allFindings | ForEach-Object {
    [PSCustomObject]@{
        Title       = $_.title
        Severity    = $_.severity
        VulnId      = $_.packageVulnerabilityDetails.vulnerabilityId
        Description = $_.description
        Layer       = $_.resources[0].details.awsEcrContainerImage.imageHash
        Package     = $_.packageVulnerabilityDetails.vulnerablePackages[0].name
        FilePath    = $_.packageVulnerabilityDetails.vulnerablePackages[0].filePath
    }
}

# ── Step 5: Deduplicate ───────────────────────────────────────
$deduped = $shaped | Sort-Object Title, VulnId -Unique
Write-Host "After dedup:" $deduped.Count

# ── Step 6: Export (recommended for 9k rows) ──────────────────
$deduped | Export-Csv -NoTypeInformation "$repo-$tag-vulns.csv"
Write-Host "Saved to $repo-$tag-vulns.csv"

# ── Step 7: Quick severity summary ────────────────────────────
$deduped | Group-Object Severity | Sort-Object Count -Descending |
    Select-Object Name, Count | Format-Table -AutoSize


Remove-Item "page_*.json"
