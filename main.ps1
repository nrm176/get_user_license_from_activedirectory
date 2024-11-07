param (
    [string]$UserUPN,
    [string]$File
)

# Import the Azure AD module
Import-Module AzureAD

# Connect to Azure AD
Connect-AzureAD

# Function to get Power BI licenses for a user
function Get-PowerBILicenses {
    param (
        [string]$UserUPN
    )

    # Get the user object
    $user = Get-AzureADUser -ObjectId $UserUPN

    if ($user -eq $null) {
        Write-Output "User not found."
        return
    }

    # Get the assigned licenses
    $licenses = Get-AzureADUserLicenseDetail -ObjectId $user.ObjectId

    # Filter Power BI related licenses
    $powerBILicenses = @()
    foreach ($license in $licenses) {
        foreach ($plan in $license.ServicePlans) {
            if ($plan.ServicePlanName -like "BI_AZURE_*") {
                $powerBILicenses += $plan.ServicePlanName
            }
        }
    }

    if ($powerBILicenses.Count -eq 0) {
        return "$UserUPN, No Power BI licenses found"
    } else {
        # Concatenate user UPN and licenses
        return "$UserUPN, " + ($powerBILicenses -join ", ")
    }
}

# Main script logic
if ($UserUPN -and $File) {
    Write-Output "Please provide either -UserUPN or -File, but not both."
    exit
}

if ($UserUPN) {
    $result = Get-PowerBILicenses -UserUPN $UserUPN
    Write-Output $result
} elseif ($File) {
    if (-not (Test-Path $File)) {
        Write-Output "File not found: $File"
        exit
    }

    $userUPNs = Import-Csv -Path $File | Select-Object -ExpandProperty UserUPN
    $results = @()

    foreach ($upn in $userUPNs) {
        $result = Get-PowerBILicenses -UserUPN $upn
        $results += $result
    }

    $outputFile = "PowerBILicensesResults.csv"
    $results | Out-File -FilePath $outputFile
    Write-Output "Results saved to $outputFile"
} else {
    Write-Output "Please provide either -UserUPN or -File."
}
