CloudFormation do

  tags = []
  tags << { Key: 'Environment', Value: Ref(:EnvironmentName) }
  tags << { Key: 'EnvironmentType', Value: Ref(:EnvironmentType) }

  extra_tags.each { |key,value| tags << { Key: key, Value: value } } if defined? extra_tags

  ingress = []
  security_group_rules.each do |rule|
    sg_rule = {
      FromPort: 2049,
      IpProtocol: 'TCP',
      ToPort: 2049,
    }
    if rule['security_group_id']
      sg_rule['SourceSecurityGroupId'] = FnSub(rule['security_group_id'])
    else
      sg_rule['CidrIp'] = FnSub(rule['ip'])
    end
    if rule['desc']
      sg_rule['Description'] = FnSub(rule['desc'])
    end
    ingress << sg_rule
  end if defined?(security_group_rules)

  EC2_SecurityGroup "SecurityGroupEFS" do
    VpcId Ref('VPCId')
    GroupDescription FnJoin(' ', [ Ref(:EnvironmentName), component_name ])
    SecurityGroupIngress ingress if ingress.any?
    SecurityGroupEgress ([
      {
        CidrIp: "0.0.0.0/0",
        Description: "outbound all for ports",
        IpProtocol: -1,
      }
    ])
    Tags tags + [{ Key: 'Name', Value: FnJoin('-', [ Ref(:EnvironmentName), component_name ])}]
  end

  EFS_FileSystem('FileSystem') do
    Encrypted true if (defined?(encrypt)) && encrypt
    KmsKeyId kms_key_alias if (defined?(encrypt)) && encrypt && (defined?(kms_key_alias))

    PerformanceMode performance_mode if defined? performance_mode
    Property('ProvisionedThroughputInMibps', provisioned_throughput) if defined? provisioned_throughput
    Property('ThroughputMode', throughput_mode) if defined? throughput_mode

    FileSystemTags tags + [{ Key: 'Name', Value: FnJoin('-', [ Ref(:EnvironmentName), component_name ])}]
  end

  maximum_availability_zones.times do |az|
    EFS_MountTarget("MountTarget#{az}") do
      FileSystemId Ref('FileSystem')
      SecurityGroups [ Ref("SecurityGroupEFS") ]
      SubnetId FnSelect(az, Ref('SubnetIds'))
    end
  end

  Output('FileSystem', Ref('FileSystem'))

end
