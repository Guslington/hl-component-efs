CfhighlanderTemplate do

  DependsOn 'vpc@2.0.0'

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', isGlobal: true
    ComponentParam 'StackOctet', '10', isGlobal: true
    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'

    maximum_availability_zones.times do |az|
      ComponentParam "SubnetPersistence#{az}"
    end

  end
end
