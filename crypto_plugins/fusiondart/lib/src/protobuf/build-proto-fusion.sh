#!/bin/bash

# This script will build the dart files based on fusion.proto.  Navigate to the protobuf directory where the fusion.proto is and run this, then copy the needed files to lib.

# The path to your .proto file. Adjust this if necessary.
PROTO_FILE="fusion.proto"

# Run the protoc command.
protoc --dart_out=grpc:. $PROTO_FILE

# After this, You should manually copy any needed dart files that were generated to the lib folder.
