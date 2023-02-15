import { connect, ConsumeMessage } from 'amqplib';
import * as common from 'react-video-call-common';
import { v4 as uuid } from 'uuid';

const serverID = uuid();

export const startReadyConsumer = async () => {
  const connection = await connect(`amqp://rabbitmq`);

  const channel = await connection.createChannel();

  await channel.assertQueue(common.readyQueueName, {
    durable: true,
  });

  // channel.prefetch(10);
  console.log(` [x] Awaiting RPC requests`);

  channel.consume(
    common.readyQueueName,
    async (msg: ConsumeMessage | null) => {
      if (msg == null) {
        console.log(`msg is null.`);
        return;
      }

      try {
        console.log(`worker ${serverID}`);
      } catch (e) {
        console.log(`readyEvent severid= ${serverID} error=` + e);
      } finally {
        channel.ack(msg);
      }
    },
    {
      noAck: false,
    },
  );
};
