param (
    [string]$TemplateFilePath = '.github/workflows/aws-cleanup.yml'
)

# Initialize lists outside the param block
$StateMachineList = aws stepfunctions list-state-machines --region us-east-1 | ConvertFrom-Json
$ActivityList = aws stepfunctions list-activities --region us-east-1 | ConvertFrom-Json
$ec2InstanceList = aws ec2 describe-instances --region us-east-1 | ConvertFrom-Json

# Get all regions
$RegionList = (aws ec2 describe-regions | ConvertFrom-Json).Regions

function Cleanup-AWS-Resources-If-Exist {
    param (
        [string]$TemplateBody,
        $GetListOfStateMachines,
        $GetListOfActivities,
        $GetListOfEC2Instances,
        $GetRegionList
    )

    foreach ($Region in $GetRegionList.RegionName) {
        # Get lists of state machines, activities, and EC2 instances for the current region
        $StateMachineList = aws stepfunctions list-state-machines --region $Region | ConvertFrom-Json
        $ActivityList = aws stepfunctions list-activities --region $Region | ConvertFrom-Json
        $ec2InstanceList = aws ec2 describe-instances --region $Region | ConvertFrom-Json

        # Delete all state machines if list is not empty
        if ($StateMachineList.stateMachines.Count -eq 0 -or $ActivityList.activities.Count -eq 0) {
            Write-Host "No state machines/activities found in region [$Region]."
        } else {
            foreach ($stateMachine in $StateMachineList.stateMachines) {
                try {
                    Write-Host "Deleting state machine [$($stateMachine.stateMachineArn)] in region [$Region]..."
                    aws stepfunctions delete-state-machine --state-machine-arn $stateMachine.stateMachineArn --region $Region
                    Write-Host "State machine [$($stateMachine.stateMachineArn)] has been successfully deleted in region [$Region]."
                } catch {
                    Write-Host "Failed to delete state machine [$($stateMachine.stateMachineArn)] in region [$Region]."
                    continue
                }
            }

            foreach ($activity in $ActivityList.activities) {
                try {
                    Write-Host "Deleting activity [$($activity.activityArn)] in region [$Region]..."
                    aws stepfunctions delete-activity --activity-arn $activity.activityArn --region $Region
                    Write-Host "Activity [$($activity.activityArn)] has been successfully deleted in region [$Region]."
                } catch {
                    Write-Host "Failed to delete activity [$($activity.activityArn)] in region [$Region]."
                    continue
                }
            }
        }

        # Delete all EC2 instances if list is not empty
        if ($ec2InstanceList.Reservations.Count -eq 0) {
            Write-Host "No EC2 instances found in region [$Region]."
        } else {
            foreach ($reservation in $ec2InstanceList.Reservations) {
                foreach ($ec2Instance in $reservation.Instances) {
                    try {
                        Write-Host "Deleting EC2 instance [$($ec2Instance.InstanceId)] in region [$Region]..."
                        aws ec2 terminate-instances --instance-ids $ec2Instance.InstanceId --region $Region
                        Write-Host "EC2 instance [$($ec2Instance.InstanceId)] has been successfully deleted in region [$Region]."
                    } catch {
                        Write-Host "Failed to delete EC2 instance [$($ec2Instance.InstanceId)] in region [$Region]."
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
    foreach ($Region in $RegionList.RegionName) {
        $stateMachineCleanupStatus = aws stepfunctions list-state-machines --region $Region | ConvertFrom-Json
        $ActivityCleanupStatus = aws stepfunctions list-activities --region $Region | ConvertFrom-Json
        $ec2InstanceCleanupStatus = aws ec2 describe-instances --region $Region | ConvertFrom-Json

        if ($stateMachineCleanupStatus.stateMachines.Count -ne 0) {
            Write-Host "State machines still exist in region [$Region]."
        } elseif ($ActivityCleanupStatus.activities.Count -ne 0) {
            Write-Host "Activities still exist in region [$Region]."
        } elseif ($ec2InstanceCleanupStatus.Reservations.Count -ne 0) {
            Write-Host "EC2 instances still exist in region [$Region]."
        } else {
            Write-Host "AWS resource space is empty in region [$Region]."
        }
    }
} catch {
    Write-Host "Failed to verify resource cleanup: $_"
}
