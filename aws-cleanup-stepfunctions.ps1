# Cleanup state machines
Get-SFNStateMachineList | % { Remove-SFNStateMachine -StateMachineArn $PSItem.StateMachineArn -WhatIf }

# Clean activity tasks
Get-SFNActivityList | % { Remove-SFNActivity -ActivityArn $PSItem.ActivityArn -WhatIf }
