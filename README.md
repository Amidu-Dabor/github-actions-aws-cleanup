# AWS Cleanup Workflow

This GitHub Actions workflow automates the cleanup of unused AWS resources, including EC2 instances, Step Functions state machines, and activities, across all specified regions. It ensures efficient resource management and cost optimization by regularly removing idle or unnecessary resources.

---

## Purpose

1. **Automated Resource Cleanup**:
   - Deletes unused EC2 instances, Step Functions state machines, and activities in multiple AWS regions.

2. **Cost Optimization**:
   - Reduces unnecessary costs by terminating idle resources.

3. **Scheduled and On-Demand Execution**:
   - Runs automatically based on a defined schedule or can be triggered manually.

---

## Workflow Trigger

This workflow is triggered by:
- **Manual Execution**: Via the `workflow_dispatch` option.
- **Scheduled Runs**: Executes daily at 10:00 AM UTC, as defined by the cron schedule `0 10 * * *`.

---

## Required Secrets

To run this workflow, add the following secrets in your repository under **Settings > Secrets and variables > Actions**:

- **ANSIBLE_SSH_KEY**: SSH key for connecting to EC2 instances.
- **AWS_ACCESS_KEY_ID**: Access key ID for AWS authentication.
- **AWS_SECRET_ACCESS_KEY**: Secret access key for AWS authentication.

---

## Key Workflow Steps

### 1. Clone Repository
- Uses the `actions/checkout` action to clone the repository containing the cleanup scripts.

### 2. Install Required AWS Tools
- Installs the necessary AWS modules (`AWS.Tools.EC2` and `AWS.Tools.StepFunctions`) for managing resources.

### 3. Authenticate with AWS
- Uses the `aws-actions/configure-aws-credentials` action to assume an IAM role for resource management.

### 4. Cleanup Resources
- Executes the PowerShell script `aws-cleanup-for-all-resources.ps1` to:
  - Terminate EC2 instances.
  - Delete Step Functions state machines and activities.

---

## File Descriptions

### 1. **aws-cleanup.yml**
Defines the workflow steps to:
- Authenticate with AWS.
- Install required AWS tools.
- Execute the resource cleanup script.

### 2. **aws-cleanup-for-all-resources.ps1**
PowerShell script that:
- Retrieves lists of EC2 instances, state machines, and activities in all AWS regions.
- Deletes these resources if they are found to be unused.

### 3. **aws-cleanup-stepfunctions.ps1**
A specialized script focused on cleaning up Step Functions resources, including state machines and activities.

---

## Usage

1. **Set Up the Workflow**:
   - Add the `aws-cleanup.yml` file to your repository under `.github/workflows/`.

2. **Add Secrets**:
   - Add the required secrets (`ANSIBLE_SSH_KEY`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) to your repository settings.

3. **Run the Workflow**:
   - Trigger the workflow manually from the **Actions** tab or wait for the scheduled run.

4. **Monitor Logs**:
   - View detailed logs in the Actions tab to verify the cleanup process.

---

## Security Considerations

1. **IAM Role Permissions**:
   - Ensure the IAM role used by the workflow has permissions to manage EC2 and Step Functions resources.

2. **Secrets Management**:
   - Store sensitive credentials (e.g., AWS keys) securely as GitHub Secrets.

3. **Resource Validation**:
   - Regularly verify that the cleanup process does not remove active or required resources.

---

By using this workflow, you can streamline the management of AWS resources, ensuring cost efficiency and optimized resource utilization.
