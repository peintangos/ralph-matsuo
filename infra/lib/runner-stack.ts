import * as cdk from "aws-cdk-lib";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import * as iam from "aws-cdk-lib/aws-iam";
import { Construct } from "constructs";

export interface RunnerStackProps extends cdk.StackProps {
  /** EC2 instance type. Defaults to t3.medium. */
  instanceType?: string;
  /** Root volume size in GiB. Defaults to 30. */
  volumeSizeGiB?: number;
}

export class RunnerStack extends cdk.Stack {
  public readonly instance: ec2.Instance;

  constructor(scope: Construct, id: string, props?: RunnerStackProps) {
    super(scope, id, props);

    const instanceType = props?.instanceType ?? "t3.medium";
    const volumeSizeGiB = props?.volumeSizeGiB ?? 30;

    // デフォルト VPC を使用
    const vpc = ec2.Vpc.fromLookup(this, "DefaultVpc", { isDefault: true });

    // Security Group: インバウンドルールなし（Session Manager のみ）
    const securityGroup = new ec2.SecurityGroup(this, "RunnerSg", {
      vpc,
      description: "Ralph runner - no inbound rules, Session Manager only",
      allowAllOutbound: true,
    });

    // IAM Role: Session Manager 用
    const role = new iam.Role(this, "RunnerRole", {
      assumedBy: new iam.ServicePrincipal("ec2.amazonaws.com"),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName(
          "AmazonSSMManagedInstanceCore"
        ),
      ],
    });

    // UserData: runner ユーザー作成と必要ツールのインストール
    const userData = ec2.UserData.forLinux();
    userData.addCommands(
      "set -euxo pipefail",

      // runner ユーザー作成
      'adduser --disabled-password --gecos "" runner',
      "usermod -aG sudo runner",
      'echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner',

      // 基本パッケージ
      "apt-get update",
      "apt-get install -y ca-certificates curl gnupg git tmux jq unzip",

      // Node.js 20 (NodeSource)
      "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -",
      "apt-get install -y nodejs",

      // GitHub CLI
      "curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg" +
        " | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg",
      "chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg",
      'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"' +
        " | tee /etc/apt/sources.list.d/github-cli.list > /dev/null",
      "apt-get update",
      "apt-get install -y gh",

      // Claude Code CLI
      "npm install -g @anthropic-ai/claude-code",

      // runner ホームディレクトリの準備
      "mkdir -p /home/runner/actions-runner",
      "chown -R runner:runner /home/runner"
    );

    // Ubuntu 24.04 LTS AMI
    const machineImage = ec2.MachineImage.lookup({
      name: "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*",
      owners: ["099720109477"], // Canonical
    });

    // EC2 インスタンス
    this.instance = new ec2.Instance(this, "Runner", {
      vpc,
      instanceType: new ec2.InstanceType(instanceType),
      machineImage,
      securityGroup,
      role,
      userData,
      vpcSubnets: { subnetType: ec2.SubnetType.PUBLIC },
      blockDevices: [
        {
          deviceName: "/dev/sda1",
          volume: ec2.BlockDeviceVolume.ebs(volumeSizeGiB, {
            volumeType: ec2.EbsDeviceVolumeType.GP3,
          }),
        },
      ],
    });

    // CloudFormation Output
    new cdk.CfnOutput(this, "InstanceId", {
      value: this.instance.instanceId,
      description: "EC2 Instance ID for SSM connection",
    });

    new cdk.CfnOutput(this, "SsmCommand", {
      value: `aws ssm start-session --target ${this.instance.instanceId}`,
      description: "Command to connect via Session Manager",
    });
  }
}
