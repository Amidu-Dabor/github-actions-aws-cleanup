param (
    [string]$TemplateFilePath = '.github/workflows/aws-cleanup.yml'
)

# Initialize lists outside the param block
$StateMachineList = Get-SFNStateMachineList
# aws stepfunctions list-state-machines | ConvertFrom-Json
$ActivityList = Get-SFNActivityList
# aws stepfunctions list-activities | ConvertFrom-Json
$ec2InstanceList = (Get-EC2Instance).Instances
# aws ec2 describe-instances | ConvertFrom-Json

# Get all regions and filter out those that match "us-east" or "us-west"
$RegionList = Get-AWSRegion
# (aws ec2 describe-regions | ConvertFrom-Json).Regions | Where-Object { $_.RegionName -notmatch 'us-east|us-west' }

function Cleanup-AWS-Resources-If-Exist {
    param (
        [string]$TemplateBody,
        $GetListOfStateMachines,
        $GetListOfActivities,
        $GetListOfEC2Instances,
        $GetRegionList
    )

    foreach ($Region in $GetRegionList.Region) {
        # Delete all state machines if list is not empty
        if ($GetListOfStateMachines.stateMachines.Count -eq 0 -or $GetListOfActivities.Count -eq 0) {
            Write-Host "No state machines/activities found."
        } else {
            try {
                Write-Host "Deleting state machine [$($stateMachine.stateMachineArn)]..."
                Remove-SFNStateMachine -StateMachineArn $_.StateMachineArn -Region $Region
                # aws stepfunctions delete-state-machine --state-machine-arn $stateMachine.stateMachineArn --region $Region
                Write-Host "State machine [$($stateMachine.stateMachineArn)] has been successfully deleted."

                Write-Host "Deleting activity [$($activity.activityArn)]..."
                Remove-SFNActivity -ActivityArn $_.ActivityArn -Region $Region
                # aws stepfunctions delete-activity --activity-arn $activity.activityArn --region $Region
                Write-Host "Activity [$($activity.activityArn)] has been successfully deleted."
            } catch {
                # Handle the case where the state machine does not exist
                Write-Host "Failed to delete state machine [$($stateMachine.stateMachineArn)]."
                continue
            }
        }

        # Delete all EC2 instances if list is not empty
        if ($GetListOfEC2Instances.Reservations.Count -eq 0) {
            Write-Host "No EC2 instances found."
        } else {
            foreach ($reservation in $GetListOfEC2Instances.Reservations) {
                foreach ($ec2Instance in $reservation.Instances) {
                    try {
                        Write-Host "Deleting EC2 instance [$($ec2Instance.InstanceId)]..."
                        Remove-EC2Instance -InstanceId $_.InstanceId -Region $Region
                        # aws ec2 terminate-instances --instance-ids $ec2Instance.InstanceId --region $Region
                        Write-Host "EC2 instance [$($ec2Instance.InstanceId)] has been successfully deleted."
                    } catch {
                        # Handle the case where the instance does not exist
                        Write-Host "Failed to delete EC2 instance [$($ec2Instance.InstanceId)]."
                        continue
                    }
                }
            }
        }
    }  
}

# Read the template file content as a single string
$TemplateBody = Get-Content -Path $TemplateFilePath -Raw

# Validate the template
Write-Host "Validating AWS Resource Cleanup template..."
try {
    aws cloudformation validate-template --template-body $TemplateBody
    Write-Host "Template validation succeeded."
} catch {
    Write-Host "Template validation failed: $_"
    exit 1
}

# Debug: Print the template body to verify its content
Write-Host "Resource Cleanup TemplateBody content:"
Write-Host $TemplateBody

# Execute the function with provided parameters
Cleanup-AWS-Resources-If-Exist -TemplateBody $TemplateBody -GetListOfStateMachines $StateMachineList -GetListOfActivities $ActivityList -GetListOfEC2Instances $ec2InstanceList -GetRegionList $RegionList

# Verify resource cleanup process
try {
    $stateMachineCleanupStatus = aws stepfunctions list-state-machines | ConvertFrom-Json
    $ActivityCleanupStatus = aws stepfunctions list-activities | ConvertFrom-Json
    $ec2InstanceCleanupStatus = aws ec2 describe-instances | ConvertFrom-Json

    if ($stateMachineCleanupStatus.stateMachines.Count -ne 0) {
        Write-Host "State machine still exists in your AWS resource space."
    } elseif ($ActivityCleanupStatus.activities.Count -ne 0) {
        Write-Host "Activity still exists in your AWS resource space."
    } elseif ($ec2InstanceCleanupStatus.Reservations.Count -ne 0) {
        Write-Host "EC2 instance still exists in your AWS resource space."
    } else {
        Write-Host "AWS resource space is empty."
    }
} catch {
    Write-Host "Failed to verify resource cleanup: $_"
}
