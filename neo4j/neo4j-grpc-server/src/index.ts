import {
  CreateMatchRequest,
  CreateMatchResponse,
  CreateUserRequest,
  CreateUserResponse,
  grpc,
  Neo4jService,
  UpdateMatchRequest,
  UpdateMatchResponse,
} from 'neo4j-grpc-common';

const createUser = (
  call: grpc.ServerUnaryCall<CreateUserRequest, CreateUserResponse>,
  callback: grpc.sendUnaryData<CreateUserResponse>,
): void => {
  call.request.getUserId();
  const reply = new CreateUserResponse();
  reply.setMessage(`Created user succesfully`);
  callback(null, reply);
};

const createMatch = (
  call: grpc.ServerUnaryCall<CreateMatchRequest, CreateMatchResponse>,
  callback: grpc.sendUnaryData<CreateMatchResponse>,
): void => {
  // call.request.getUserId();
  const reply = new CreateMatchResponse();
  reply.setMessage(`Created match succesfully`);
  callback(null, reply);
};

const updateMatch = (
  call: grpc.ServerUnaryCall<UpdateMatchRequest, UpdateMatchResponse>,
  callback: grpc.sendUnaryData<UpdateMatchResponse>,
): void => {
  // call.request.getUserId();
  const reply = new UpdateMatchResponse();
  reply.setMessage(`Updated match succesfully`);
  callback(null, reply);
};

var server = new grpc.Server();
server.addService(Neo4jService, { createUser, createMatch, updateMatch });

server.bindAsync(
  `0.0.0.0:8080`,
  grpc.ServerCredentials.createInsecure(),
  () => {
    console.log(`starting...`);
    server.start();
  },
);
