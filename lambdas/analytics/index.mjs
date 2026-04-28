/**
 * Analytics Lambda — triggered by DynamoDB Streams
 *
 * Fires whenever a record is written to the UrlShortener table.
 * We only care about CLICK events (INSERT where eventType = CLICK).
 * Everything else (new URL creations, updates) is ignored.
 */
export const handler = async (event) => {
  for (const record of event.Records) {

    // Only process new inserts — ignore MODIFY and REMOVE
    if (record.eventName !== "INSERT") continue;

    const newItem = record.dynamodb?.NewImage;

    // Only process click events, not URL creation records
    if (newItem?.eventType?.S !== "CLICK") continue;

    const clickData = {
      targetId:  newItem.targetId?.S,
      ip:        newItem.ip?.S,
      userAgent: newItem.userAgent?.S,
      createdAt: newItem.createdAt?.S,
      userId:    newItem.userId?.S,
    };

    // Log to CloudWatch — queryable via CloudWatch Insights
    console.log(JSON.stringify({
      type:    "CLICK_EVENT",
      ...clickData,
    }));

    // This is where you'd add:
    // - Increment a counter in a separate analytics table
    // - Push to Kinesis for real-time dashboards
    // - Send to an external analytics service
  }
};
