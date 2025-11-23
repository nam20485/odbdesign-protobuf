#include "odbdesign/ProtobufApi.h"

#include <grpcpp/create_channel.h>

namespace odbdesign::protobuf
{

    std::unique_ptr<Odb::Lib::Protobuf::ProductModel::Design> DesignServiceBridge::CreateDesign()
    {
        return std::make_unique<Odb::Lib::Protobuf::ProductModel::Design>();
    }

    std::unique_ptr<Odb::Lib::Protobuf::FeaturesFile::FeatureRecord> DesignServiceBridge::CreateFeatureRecord()
    {
        return std::make_unique<Odb::Lib::Protobuf::FeaturesFile::FeatureRecord>();
    }

    std::unique_ptr<Odb::Grpc::OdbDesignService::Stub> DesignServiceBridge::CreateServiceStub(
        const std::shared_ptr<grpc::Channel> &channel)
    {
        return Odb::Grpc::OdbDesignService::NewStub(channel);
    }

    std::string DesignServiceBridge::GetLibraryVersion()
    {
        return std::string{"0.1.0"};
    }

} // namespace odbdesign::protobuf
