#pragma once

#include <memory>
#include <string>

#include <grpcpp/channel.h>

#include "design.pb.h"
#include "featuresfile.pb.h"
#include "grpc/service.grpc.pb.h"

#if defined(_WIN32)
#if defined(ODBDESIGN_PROTOBUF_NATIVE_BUILD)
#define ODBDESIGN_PROTOBUF_API __declspec(dllexport)
#else
#define ODBDESIGN_PROTOBUF_API __declspec(dllimport)
#endif
#elif defined(__GNUC__)
#define ODBDESIGN_PROTOBUF_API __attribute__((visibility("default")))
#else
#define ODBDESIGN_PROTOBUF_API
#endif

namespace odbdesign::protobuf
{

    class ODBDESIGN_PROTOBUF_API DesignServiceBridge
    {
    public:
        static std::unique_ptr<Odb::Lib::Protobuf::ProductModel::Design> CreateDesign();

        static std::unique_ptr<Odb::Lib::Protobuf::FeaturesFile::FeatureRecord> CreateFeatureRecord();

        static std::unique_ptr<Odb::Grpc::OdbDesignService::Stub> CreateServiceStub(
            const std::shared_ptr<grpc::Channel> &channel);

        static std::string GetLibraryVersion();
    };

} // namespace odbdesign::protobuf
