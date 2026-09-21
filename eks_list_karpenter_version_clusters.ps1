$region  = "us-east-1"
$profile = "nphase"
$ns      = "kube-system"
$env:KUBECONFIG="C:\Users\aubre\.kube\nphase.yaml"
#$env:KUBECONFIG ="C:\Users\aubre\.kube\pfizer.yaml"

$clusters = aws eks list-clusters --region $region --profile $profile --query "clusters[]" --output text

"{0,-45} {1,-12} {2,-14} {3}" -f "CLUSTER","MODE","KARPENTER","VERDICT"
"{0,-45} {1,-12} {2,-14} {3}" -f "-------","----","---------","-------"

foreach ($c in $clusters -split "\s+") {
    if ([string]::IsNullOrWhiteSpace($c)) { continue }

    # Auto Mode?
    $enabled = aws eks describe-cluster --name $c --region $region --profile $profile `
        --query "cluster.computeConfig.enabled" --output text
    $mode = if ($enabled -eq "True") { "Auto Mode" } else { "Standard" }

    if ($mode -eq "Auto Mode") {
        "{0,-45} {1,-12} {2,-14} {3}" -f $c,$mode,"(AWS-managed)","AWS handles"
        continue
    }

    # Read Karpenter version from kube-system using current context
   # $img =  kubectl --context "arn:aws:eks:us-east-1:381491891968:cluster/$c" -n kube-system  get deployment karpenter   -o jsonpath="{.spec.template.spec.containers[0].image}"
    $img =  kubectl --context "arn:aws:eks:us-east-1:746159825267:cluster/$c" -n kube-system  get deployment karpenter   -o jsonpath="{.spec.template.spec.containers[0].image}"



    if ([string]::IsNullOrWhiteSpace($img)) {
        "{0,-45} {1,-12} {2,-14} {3}" -f $c,$mode,"not found","no karpenter / check access"
        continue
    }

    $ver = ($img -split ":")[1] -replace '^v','' 
    $ver = ($ver -split "@")[0]
    $verdict = "REVIEW"
    try {
        $v = [version]$ver
        if     ($v -le [version]"1.2.999") { $verdict = "OK (<=1.2)" }
        elseif ($v -ge [version]"1.7.0")   { $verdict = "OK (>=1.7)" }
        elseif ($v.Major -eq 1 -and $v.Minor -eq 3) { $verdict = if ($v -ge [version]"1.3.6") {"OK"} else {"UPGRADE ->1.3.6"} }
        elseif ($v.Major -eq 1 -and $v.Minor -eq 4) { $verdict = if ($v -ge [version]"1.4.2") {"OK"} else {"UPGRADE ->1.4.2"} }
        elseif ($v.Major -eq 1 -and $v.Minor -eq 5) { $verdict = if ($v -ge [version]"1.5.6") {"OK"} else {"UPGRADE ->1.5.6"} }
        elseif ($v.Major -eq 1 -and $v.Minor -eq 6) { $verdict = if ($v -ge [version]"1.6.5") {"OK"} else {"UPGRADE ->1.6.5"} }
    } catch { $verdict = "REVIEW (parse)" }

    "{0,-45} {1,-12} {2,-14} {3}" -f $c,$mode,$ver,$verdict
}