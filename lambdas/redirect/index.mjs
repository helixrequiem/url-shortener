import {
  DynamoDBClient,
  GetItemCommand,
  PutItemCommand
} from "@aws-sdk/client-dynamodb";

const client = new DynamoDBClient({});
const TABLE_NAME = process.env.TABLE_NAME;

export const handler = async (event) => {
  const shortId = event.pathParameters?.shortId;

  if (!shortId) {
    return { statusCode: 400, body: JSON.stringify({ error: "Missing shortId" }) };
  }

  // Fetch the original URL
  const result = await client.send(new GetItemCommand({
    TableName: TABLE_NAME,
    Key: { shortId: { S: shortId } },
  }));

  if (!result.Item) {
    return { statusCode: 404, body: JSON.stringify({ error: "Short URL not found" }) };
  }

  // Await the click write — Lambda freezes after return so fire-and-forget doesn't work
  const clickId = `${shortId}#${Date.now()}`;
  await client.send(new PutItemCommand({
    TableName: TABLE_NAME,
    Item: {
      shortId:     { S: clickId },
      originalUrl: { S: result.Item.originalUrl.S },
      eventType:   { S: "CLICK" },
      targetId:    { S: shortId },
      ip:          { S: event.requestContext?.http?.sourceIp || "unknown" },
      userAgent:   { S: event.requestContext?.http?.userAgent || "unknown" },
      createdAt:   { S: new Date().toISOString() },
      userId:      { S: result.Item.userId?.S || "anonymous" },
    },
  }));

  return {
    statusCode: 302,
    headers: { Location: result.Item.originalUrl.S },
    body: "",
  };
};
