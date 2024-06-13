# Cleanup state machines
Get-SFNStateMachineList | % { Remove-SFNStateMachine -StateMachineArn $PSItem.StateMachineArn -Force }

# Clean activity tasks
Get-SFNActivityList | % { Remove-SFNActivity -ActivityArn $PSItem.ActivityArn -Force }
