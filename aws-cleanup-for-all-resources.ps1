param (
    [string]$TemplateFilePath = 'aws-cleanup.yml'
)

# Initialize lists outside the param block
$StateMachineList = Get-SFNStateMachine
$ActivityList = Get-SFNActivity
$ec2InstanceList = Get-EC2Instance | Select-Object -ExpandProperty Instances

function Cleanup-AWS-Resources-If-Exist {
    param (
        [string]$TemplateBody,
        $GetListOfStateMachines,
        $GetListOfActivities,
        $GetListOfEC2Instances
    )

    # Delete all state machines if list is not empty
    if ($GetListOfStateMachines.Count -eq 0) {
        Write-Host "No state machines found."
    } else {
        foreach ($stateMachine in $GetListOfStateMachines) {
            try {
                Write-Host "Deleting state machine [$($stateMachine.StateMachineArn)]..."
                Remove-SFNStateMachine -StateMachineArn $stateMachine.StateMachineArn -ErrorAction Stop
                Write-Host "State machine [$($stateMachine.StateMachineArn)] has been successfully deleted."
            } catch {
                # Handle the case where the state machine does not exist
                Write-Host "Failed to delete state machine [$($stateMachine.StateMachineArn)]."
                continue
            }
        }
    }

    # Delete all activity tasks if list is not empty
    if ($GetListOfActivities.Count -eq 0) {
        Write-Host "No activities found."
    } else {
        foreach ($activity in $GetListOfActivities) {
            try {
                Write-Host "Deleting activity [$($activity.ActivityArn)]..."
                Remove-SFNActivity -ActivityArn $activity.ActivityArn -ErrorAction Stop
                Write-Host "Activity [$($activity.ActivityArn)] has been successfully deleted."
            } catch {
                # Handle the case where the activity does not exist
                Write-Host "Failed to delete activity [$($activity.ActivityArn)]."
                continue
            }
        }
    }

    # Delete all EC2 instances if list is not empty
    if ($GetListOfEC2Instances.Count -eq 0) {
        Write-Host "No EC2 instances found."
    } else {
        foreach ($ec2Instance in $GetListOfEC2Instances) {
            try {
                Write-Host "Deleting EC2 instance [$($ec2Instance.InstanceId)]..."
                Remove-EC2Instance -InstanceId $ec2Instance.InstanceId -ErrorAction Stop
                Write-Host "EC2 instance [$($ec2Instance.InstanceId)] has been successfully deleted."
            } catch {
                # Handle the case where the instance does not exist
                Write-Host "Failed to delete EC2 instance [$($ec2Instance.InstanceId)]."
                continue
            }
        }
    }
}

# Read the template file content as a single string
$TemplateBody = Get-Content -Path $TemplateFilePath -Raw

# Validate the template
Write-Host "Validating AWS Resource Cleanup template..."
try {
    Test-CFNTemplate -TemplateBody $TemplateBody -ErrorAction Stop
    Write-Host "Template validation succeeded."
} catch {
    Write-Host "Template validation failed: $_"
    exit 1
}

# Debug: Print the template body to verify its content
Write-Host "Resource Cleanup TemplateBody content:"
Write-Host $TemplateBody

# Execute the function with provided parameters
Cleanup-AWS-Resources-If-Exist -TemplateBody $TemplateBody -GetListOfStateMachines $StateMachineList -GetListOfActivities $ActivityList -GetListOfEC2Instances $ec2InstanceList

# Verify resource cleanup process
try {
    $stateMachineCleanupStatus = $StateMachineList | % { Get-SFNStateMachine -StateMachineArn $_.StateMachineArn -ErrorAction SilentlyContinue }
    $ActivityCleanupStatus = $ActivityList | % { Get-SFNActivity -ActivityArn $_.ActivityArn -ErrorAction SilentlyContinue }
    $ec2InstanceCleanupStatus = $ec2InstanceList | % { Get-EC2Instance -InstanceId $_.InstanceId -ErrorAction SilentlyContinue }

    if ($stateMachineCleanupStatus.Count -ne 0) {
        Write-Host "State machine still exists in your AWS resource space."
    } elseif ($ActivityCleanupStatus.Count -ne 0) {
        Write-Host "Activity still exists in your AWS resource space."
    } elseif ($ec2InstanceCleanupStatus.Count -ne 0) {
        Write-Host "EC2 instance still exists in your AWS resource space."
    } else {
        Write-Host "AWS resource space is empty."
    }
} catch {
    Write-Host "Failed to verify resource cleanup: $_"
}
