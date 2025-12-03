import { randomBytes } from 'node:crypto';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb'; 

const ddbClient = DynamoDBDocumentClient.from(new DynamoDBClient({ region: 'eu-west-1' }));
const fleet = [
     { Name: 'Angel', Color: 'White', Gender: 'Female' },
     { Name: 'Gil', Color: 'White', Gender: 'Male' },
     { Name: 'Rocinante', Color: 'Yellow', Gender: 'Female' }, ];
     
     export async function handler(event, context) {
        const { authorizer } = event.requestContext || {};
        const awsRequestId = context.awsRequestId; 
        
        if (!authorizer) { return errorResponse('Authorization not configured', awsRequestId);

         } const rideId = toUrlString(randomBytes(16)); 
         console.log(`Received event (${rideId}):`, event); 
         
        const username = authorizer.claims?.['cognito:username'];
        const requestBody = JSON.parse(event.body || '{}');
        const pickupLocation = requestBody.PickupLocation;
        const unicorn = findUnicorn(pickupLocation); 
            try { await recordRide(rideId, username, unicorn); 
                return { statusCode: 201, body: JSON.stringify({ RideId: rideId, Unicorn: unicorn, Eta: '30 seconds', Rider: username, }),
                headers: { 'Access-Control-Allow-Origin': '*', }, }; } catch (err) { console.error(err); return errorResponse(err.message, awsRequestId); } }
                
                
                
function findUnicorn(pickupLocation) { 
    const { Latitude, Longitude } = pickupLocation || {};
    console.log(`Finding unicorn for ${Latitude}, ${Longitude}`);
    return fleet[Math.floor(Math.random() * fleet.length)]; } 
    
    
    async function recordRide(rideId, username, unicorn) {
        const params = { TableName: 'Rides', Item: { RideId: rideId, User: username, Unicorn: unicorn, RequestTime: new Date().toISOString(), }, };
        await ddbClient.send(new PutCommand(params)); } function toUrlString(buffer) {
            
        return buffer.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, ''); } 
        
        function errorResponse(errorMessage, awsRequestId) { 
            return { statusCode: 500, body: JSON.stringify({ Error: errorMessage, Reference: awsRequestId, }),
             headers: { 'Access-Control-Allow-Origin': '*', }, }; }