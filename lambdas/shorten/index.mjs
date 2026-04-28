import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";

const client = new DynamoDBClient({});
const TABLE_NAME = process.env.TABLE_NAME;
const BASE_URL = process.env.BASE_URL;

// Generates a random 6-character alphanumeric ID
// e.g. "xK9mPq"
function generateShortId() {
  const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  return Array.from({ length: 6 }, () =>
    chars[Math.floor(Math.random() * chars.length)]
  ).join("");
}

export const handler = async (event) => {
  const body = JSON.parse(event.body || "{}");
  const { originalUrl, userId = "anonymous" } = body;

  // Basic validation
  if (!originalUrl || !originalUrl.startsWith("http")) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "Invalid URL" }),
    };
  }

  const shortId = generateShortId();
  const createdAt = new Date().toISOString();

  await client.send(new PutItemCommand({
    TableName: TABLE_NAME,
    Item: {
      shortId:     { S: shortId },
      originalUrl: { S: originalUrl },
      userId:      { S: userId },
      createdAt:   { S: createdAt },
      clicks:      { N: "0" },
    },
    // Prevent overwriting if shortId already exists (extremely rare but safe)
    ConditionExpression: "attribute_not_exists(shortId)",
  }));

  return {
    statusCode: 201,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      shortUrl: `${BASE_URL}/${shortId}`,
      shortId,
      originalUrl,
      createdAt,
    }),
  };
};
