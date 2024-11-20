/******************************************************************************    
* AzureAPI - Class for invoking MS Teams API
*            No.  Date(dd-mm-yyy) Author            Description
*           ----  ---------   --------------------  -----------------------------
* @version   1.0  23-05-2023   Rex David            [CCN-EVE-3056-DV] Virtual Meeting Integration (POC: Microsoft Teams Link)
******************************************************************************/

public class AzureAPI {
    
    public static Session__c getMeetingUrl(Session__c session){

        HttpRequest req = new HttpRequest();
        Http http = new Http();
        //Setup the Endpoint and append the name of the file
        req.setTimeout(60000);
        req.setEndpoint('callout:MS_Azure_OnlineMeetings/'+session.MS_Teams_Id__c);
        req.setMethod('GET');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept','*/*');
        req.setHeader('Accept-Encoding','gzip, deflate, br');
        HTTPResponse res = http.send(req);
        JSONParser parser = JSON.createParser(res.getBody());
        String webLink;
        String meetingId = '';
        String startDateTime = '';
        String endDateTime = '';
        webLink = 'MSTeamsNotSetup';

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME){
                if (parser.getText() == 'joinWebUrl'){
                    parser.nextToken();
                    webLink = parser.getText();
                    System.debug('joinWebUrl= ' + webLink);
                }
                if (parser.getText() == 'joinMeetingId'){
                    parser.nextToken();
                    meetingId = parser.getText();
                    System.debug('meetingId= ' + meetingId);
                }
                if (parser.getText() == 'startDateTime'){
                    parser.nextToken();
                    startDateTime = parser.getText();
                    System.debug('startDateTime= ' + startDateTime);
                }
                if (parser.getText() == 'endDateTime'){
                    parser.nextToken();
                    endDateTime = parser.getText();
                    System.debug('endDateTime= ' + endDateTime);
                }
            }
        }
        return session;
    }

    public static Session__c processMeetingUrl(String action, Session__c session){

        // action POST, PATCH
        String subject = session.Name;
        if(action == 'PATCH' && session.MS_Teams_Id__c == NULL){
            throw new AzureAPIException('Session MS_Teams_Id__c Id is blank.');
        }

        HttpRequest req = new HttpRequest();

        Http http = new Http();

        //Setup the Endpoint and append the name of the file
        req.setTimeout(60000);
        req.setEndpoint((action == 'POST') ? 'callout:MS_Azure_OnlineMeetings' : (action == 'PATCH' && session.MS_Teams_Id__c != NULL) ? 'callout:MS_Azure_OnlineMeetings/'+session.MS_Teams_Id__c : '');
        req.setMethod(action);
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept','*/*');
        req.setHeader('Accept-Encoding','gzip, deflate, br');
        req.setBody(generateRequest(action,session));  
        HTTPResponse res = http.send(req);
        /* Parse Response */

        System.debug('res.getBody() '+res.getBody());

        JSONParser parser = JSON.createParser(res.getBody());
        String webLink;
        String meetingId = '';
        String passcode = '';
        String conferenceId = '';
        String tollNumber = '';
        String dialinUrl = '';
        String id = '';
        webLink = 'MSTeamsNotSetup';

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME){  
                if (parser.getText() == 'joinWebUrl'){
                    parser.nextToken();
                    webLink = parser.getText();
                    System.debug('joinWebUrl= ' + webLink);
                }
                if (parser.getText() == 'joinMeetingId'){
                    parser.nextToken();
                    meetingId = parser.getText();
                    System.debug('meetingId= ' + meetingId);
                }
                if (parser.getText() == 'passcode'){
                    parser.nextToken();
                    passcode = parser.getText();
                    System.debug('passcode= ' + passcode);
                }
                if (parser.getText() == 'conferenceId'){
                    parser.nextToken();
                    conferenceId = parser.getText();
                    System.debug('conferenceId= ' + conferenceId);
                }
                if (parser.getText() == 'tollNumber'){
                    parser.nextToken();
                    tollNumber = parser.getText();
                    System.debug('tollNumber= ' + tollNumber);
                }
                if (parser.getText() == 'dialinUrl'){
                    parser.nextToken();
                    dialinUrl = parser.getText();
                    System.debug('dialinUrl= ' + dialinUrl);
                }
                if (parser.getText() == 'id'){
                    parser.nextToken();
                    if(id == '') {
                        id = parser.getText();
                        System.debug('id= ' + id);
                    }
                }
            }
        }

        session.Meeting_Info__c = processMeetingBody(session,webLink,meetingId,passcode,conferenceId,tollNumber,dialinUrl);//'Join Meeting Id: '+ meetingId + '<br/>' + 'Passcode: '+ passcode + '<br/>' + 'Conference Id: '+ conferenceId + '<br/>' + 'Toll Number: ' + tollNumber + '<br/>' + 'Dial In Url: '+dialinUrl;
        session.Meeting_URL__c = webLink;
        session.MS_Teams_Id__c = id;
        return session;

    }

    public static String generateRequest(String action, Session__c session){

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
            gen.writeStringField('subject', session.Name);
            if(session.Time_Zone__c != NULL && session.Start_Date_Time__c != NULL && session.End_Date_Time__c != NULL){
                gen.writeStringField('startDateTime', getUTCDateTime(session.Time_Zone__c,session.Start_Date_Time__c));
                gen.writeStringField('endDateTime', getUTCDateTime(session.Time_Zone__c,session.End_Date_Time__c));
            }
            if(action == 'POST'){
                gen.writeFieldName('joinMeetingIdSettings');
                gen.writeStartObject();
                    gen.writeObjectField('isPasscodeRequired', true); 
                gen.writeEndObject();    
            }
        gen.writeEndObject();

        String pretty = gen.getAsString();
        return pretty;
    }

    public static String getUTCDateTime(String timeZone, DateTime dateTimeToProcess){
        
        Map<String, Org_timezone_difference__mdt> TZDiffMeta = new Map<String, Org_timezone_difference__mdt>();
        TZDiffMeta = Org_timezone_difference__mdt.getAll();

        Datetime formattedDateTime;

        Decimal difference = TZDiffMeta.get(timeZone).Hour_Difference__c*-60;
        formattedDateTime = dateTimeToProcess.addMinutes(Integer.valueOf(difference));   
        String formatted = formattedDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX'); 
        return formatted;
    }

    public static String processMeetingBody(Session__c session, String webLink, String meetingId, String passcode, String conferenceId, String tollNumber, String dialinUrl){
        String currSessionMeetingInfo = session.Meeting_Info__c;
        Boolean hasTeamsLink = (session.Meeting_Info__c != NULL && (session.Meeting_Info__c.containsIgnoreCase('Meeting ID') || session.Meeting_Info__c.containsIgnoreCase('Microsoft Teams meeting'))) ? true : false;
        
        String base = System.Label.MS_Teams_Body;
        base = base.replace('[MEETURL]',webLink);
        base = base.replace('[MEETID]',meetingId);
        base = base.replace('[MEETCODE]',passcode);
        base = base.replace('[MEETCONF]',conferenceId);
        base = base.replace('[MEETTOLL]',tollNumber);
        base = base.replace('[MEETDIAL]',dialinUrl);
        
        if(!hasTeamsLink) //If Session doesn't have Meeting Info
        base = (currSessionMeetingInfo != NULL) ? currSessionMeetingInfo + '<br/> --- <br/>' + base : '' + base;
        else{
            //base = base;
            if(currSessionMeetingInfo.contains('\n --- \n')){ //Contains Splitter
                String existingLink = currSessionMeetingInfo.substringAfter('<br/> --- <br/>');
                base = currSessionMeetingInfo.replace(existingLink,base);
            }
            else if(currSessionMeetingInfo.contains('---')){
                String existingLink = currSessionMeetingInfo.substringAfter('---');
                base = currSessionMeetingInfo.replace(existingLink,base);
            }
        }
        return base;

    }

    public class AzureAPIException extends Exception{}

}