# Create a List of State Machines
[string]$StateMachineList = Get-SFNStateMachineList | % { Get-SFNStateMachine -StateMachineArn $_.StateMachineArn } -ErrorAction SilentlyContinue
# Create a List of Activity Tasks
[string]$ActivityList = Get-SFNActivityList | % { Get-SFNActivity -ActivityArn $_.ActivityArn }
# Create a list of EC2 instances
[string]$ec2InstanceList = (Get-EC2Instance).Instances | % { GetEC2Instance -InstanceId $_.InstanceId }

param (
  # Cleanup Template
  [string]$TemplateFilePath = 'aws-cleanup.yml'
)

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
        exit 1
    } else {
        foreach ($stateMachine in $GetListOfStateMachines) {
            try {
                Write-Host "Deleting state machines..."
                $stateMachineIsRemoved = Remove-SFNStateMachine -StateMachineArn $stateMachine.StateMachineArn -ErrorAction Stop
                if ($stateMachineIsRemoved) {
                    Write-Host "State machines have been successfully deleted."
                }
            } catch {
                # Handle the case where the state machine does not exist
                continue
            }
        }
    }

    # Delete all activity tasks if list is not empty
    if ($GetListOfActivities.Count -eq 0) {
        Write-Host "No activities found."
        exit 1
    } else {
        foreach ($activity in $GetListOfActivities) {
            try {
                Write-Host "Deleting activities..."
                $activityIsRemoved = Remove-SFNActivity -ActivityArn $activity.ActivityArn -ErrorAction Stop
                if ($activityIsRemoved) {
                    Write-Host "Activities have been successfully deleted."
                }
            } catch {
                # Handle the case where the activity does not exist
                continue
            }
        }
    }

    # Delete all EC2 instances if list is not empty
    if ($GetListOfEC2Instances.Count -eq 0) {
        Write-Host "No EC2 instances found."
        exit 1
    } else {
        foreach ($ec2Instance in $GetListOfEC2Instances) {
            try {
                Write-Host "Deleting EC2 instances..."
                $ec2InstanceIsRemoved = Remove-EC2Instance -InstanceId $ec2Instance.InstanceId -ErrorAction Stop
                if ($ec2InstanceIsRemoved) {
                    Write-Host "EC2 instances have been successfully deleted."
                }
            } catch {
                # Handle the case where the activity does not exist
                continue
            }
        }
    }
}

# Read the template file content as a single string
$TemplateBody = Get-Content -Path $TemplateFilePath -Raw

# Validate the template
Write-Host "Validating AWS Resouce Cleanup template..."
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
    $stateMachineCleanupStatus = Remove-SFNStateMachine -StateMachineArn $stateMachine.StateMachineArn -ErrorAction Stop
    $ActivityCleanupStatus = Remove-SFNActivity -ActivityArn $activity.ActivityArn -ErrorAction Stop
    $ec2InstanceCleanupStatus = Remove-EC2Instance -InstanceId $ec2Instance.InstanceId -ErrorAction Stop
    if ($stateMachineCleanupStatus -ne $null) {
        Write-Host "State machine still exists in your AWS resouce space."
    } elseif ($ActivityCleanupStatus -ne $null) {
        Write-Host "Activity still exists in your AWS resouce space."
    } elseif ($ec2InstanceCleanupStatus -ne $null) {
        Write-Host "EC2 instance still exists in your AWS resouce space."
    } else {
        Write-Host "AWS resource space is empty."
    }
} catch {
    Write-Host "Failed to very resource cleanup."
}
