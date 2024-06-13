# Cleanup state machines
Get-SFNStateMachineList | % { Remove-SFNStateMachine -StateMachineArn $PSItem.StateMachineArn }

# Clean activity tasks
Get-SFNActivityList | % { Remove-SFNActivity -ActivityArn $PSItem.ActivityArn }
