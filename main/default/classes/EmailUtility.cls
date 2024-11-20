/*
* @filename        : EmailUtility
* @created         : 14.DEC.2020
* @author          : JL
* @description     : EmailUtility - Utility Class for sending email.
*/  
public with sharing class EmailUtility {
    public static String COMM_STATUS_SENT = 'Sent';
    public static String COMM_STATUS_DRAFT = 'Draft';
    public static String COMM_STATUS_OUTBOX = 'Outbox';
    public static String COMM_STATUS_FAILED = 'Failed';
    public static String COMM_FREQUENCY_REALTIME = 'Real-time';
    public static String COMM_FREQUENCY_SCHEDULED = 'Scheduled';
    public static String PARTICIPANT_STATUS_SENT = 'Sent';
    public static boolean isSetToAddress=false;
    public static Email_Settings__c settings {get;set;}
    public static Integer currentOrgEmailCalls {get;set;}
    public static Integer currentTransactionEmailCalls {get;set;}
    //variable to use for test class; work around for org email sending limit and transaction limit
    public static boolean isTest {
        get{ 
            if(isTest!=null){
                return isTest;
            }
            else{
                return false;
            }
        }
        set;
    }

    private without sharing class ElevatedContext{
        public Map<String,System.OrgLimit> limitsMap = OrgLimits.getMap();
        public System.OrgLimit apiRequestsLimit = limitsMap.get('SingleEmail');
    }
        
    //wrapper class for email message used for future methods
    public class singleMailMessageWrapper{
        public boolean setSaveAsActivity = false;
        public String setSubject {get;set;}
        public String setHtmlBody {get;set;}
        public String setWhatId {get;set;}
        public String setTargetObjectId {get;set;}
        public String setTemplateId {get;set;}
        public List<String> setToAddresses {get;set;}
        public List<String> setCcAddresses {get;set;}
        public List<String> setBccAddresses {get;set;}
        public String setPlainTextBody {get;set;}
        // added 5/22/2021
        public String setOrgWideEmailAddressId {get;set;}
    }
    
    /*
    * @filename        : executeSendEmail
    * @created         : 05.JAN.2021
    * @author          : JL
    * @description     : This is the actual method for sending email.
    *                       returns Map<String, Object> consists of the following key string values:
    *                       1. 'hasError' - boolean; flag if there is an error;
    *                       2. 'messages' - List<String>; contains a list of error messages;
    *                       3. 'resultMap' - Map<String, Object>; contains the map of communication id and email sending response (Messaging.SendEmailResult) 
    */
    public static Map<String, Object> executeSendEmail(List<Messaging.SingleEmailMessage> emailMessages){
        Map<String, Object> response = new Map<String, Object>();
        Messaging.SendEmailResult [] results = null;
        Boolean hasError = false;
        List<String> messages = new List<String>();
        Map<String, Object> resultMap = new Map<String, Object>();

        System.debug('*****[executeSendEmail]settings-->'+settings);
        if(settings==null){
           settings = Email_Settings__c.getOrgDefaults();
        }
        //check if email sending in settings is active/enabled
        if(settings.isActive__c){
            //check limits
            if(!isTest){
                //check organization send email limit
                currentOrgEmailCalls = new ElevatedContext().apiRequestsLimit.getValue() + emailMessages.size();
                //check transaction limit
                currentTransactionEmailCalls = Limits.getEmailInvocations()+1;
            }
            else{
                currentOrgEmailCalls = currentOrgEmailCalls + emailMessages.size();
                //check transaction limit
                currentTransactionEmailCalls = currentTransactionEmailCalls+1;
            }
            System.debug('*****[executeSendEmail]currentOrgEmailCalls-->'+currentOrgEmailCalls);
            System.debug('*****[executeSendEmail]currentTransactionEmailCalls-->'+currentTransactionEmailCalls);

            if(currentOrgEmailCalls<= new ElevatedContext().apiRequestsLimit.getLimit()){
                if( currentTransactionEmailCalls<= Limits.getLimitEmailInvocations()){
                    try{
                        /* emailMessages[0].setHtmlBody('');
                        emailMessages[0].setPlainTextBody('body test'); */
                        results = Messaging.sendEmail(emailMessages, false);
                        
                        /**if(results[0].isSuccess()) {
                        // Alter query such that only desired record is fetched.
                            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                            message.ToAddresses = new String[] {'angelo@ulapp.com'};
                            message.setPlainTextBody('body test');
                            
                            Messaging.SingleEmailMessage[] messages1 = new List <Messaging.SingleEmailMessage> {message};
                            Messaging.SendEmailResult[] results1 = Messaging.sendEmail(messages1);
                        }**/
                    }

                    catch(EmailException e){
                        hasError = true;
                        System.debug('TRY-CATCH-EmailException-->'+e);
                        messages.add(e.getDmlMessage(0));
                    }
                    if(results.size()>0){
                        //mapping Comms record to email result
                        for(integer i=0;i<emailMessages.size();i++){
                            Messaging.SingleEmailMessage emailMessage = emailMessages[i];
                            Messaging.SendEmailResult result = results[i];
                            resultMap.put(emailMessage.getWhatId(), result);
                            /*   
                            if(!result.isSuccess()){
                                for(Messaging.SendEmailError err : result.getErrors()) {
                                    System.debug('The following error has occurred.');                    
                                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                    System.debug('fields that affected this error: ' + err.getFields());
                                }
        
                            }
                            */
                        }
                    }
                    
                    System.debug('*****[executeSendEmail]hasError-->'+hasError);
                    System.debug('*****[executeSendEmail]messages-->'+messages);
                    System.debug('*****[executeSendEmail]resultMap-->'+resultMap);
                    response.put('hasError', hasError);
                    response.put('messages', messages);
                    response.put('resultMap', resultMap);
                }
                else{
                    //transaction error handling
                    hasError = true;
                    response.put('hasError', hasError);
                    messages.add(settings.Email_Transaction_Limit_Error_Message__c);
                    response.put('messages', messages);
                }
            }
            else{
                //org wide daily limit error handling
                hasError = true;
                response.put('hasError', hasError);
                messages.add(settings.Email_Sent_Daily_Limit_Error_Message__c);
                response.put('messages', messages);
                
            }
            /*
            System.debug('*****[executeSendEmail]Limit Name: ' + new ElevatedContext().apiRequestsLimit.getName());
            System.debug('*****[executeSendEmail]Usage Value: ' + new ElevatedContext().apiRequestsLimit.getValue());
            System.debug('*****[executeSendEmail]Maximum Limit: ' + new ElevatedContext().apiRequestsLimit.getLimit());
            */
        }
        else{
            //settings disabled error handling
            hasError = true;
            response.put('hasError', hasError);
            messages.add(settings.Email_Disabled_Error_Message__c);
            response.put('messages', messages);
        }
        
        return response;
    }
    
    /*
    * @filename        : sendEmailMessageFuture
    * @created         : 14.DEC.2020
    * @author          : JL
    * @description     : This method sends a list of wrapped Email Message asynchronously
    */
    @future
    public static void sendEmailMessageFuture(String emailWrapper){
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email;
        if(emailWrapper != null){
            for(singleMailMessageWrapper eWrapper : (List<singleMailMessageWrapper>) JSON.deserialize(emailWrapper,List<singleMailMessageWrapper>.class)){
                email = new Messaging.SingleEmailMessage();
                email.setSaveAsActivity(eWrapper.setSaveAsActivity);
                email.setSubject(eWrapper.setSubject);
                email.setPlainTextBody(eWrapper.setPlainTextBody);//<!--START - ADDED BY JLAURIO 20191129 JCC5862 BUG FIX (JCC-6098) -->
                email.setHtmlBody(eWrapper.setHtmlBody);
                email.setWhatId(eWrapper.setWhatId);
                //email.settargetObjectId(eWrapper.settargetObjectId);
                email.setTemplateId(eWrapper.setTemplateId);
                email.setToAddresses(eWrapper.setToAddresses);
                email.setCcAddresses(eWrapper.setCcAddresses);
                
                emails.add(email);
            }
            
            System.debug('sendEmailMessage future');
            Messaging.SendEmailResult[] sendEmailResults = null;
            //LIMIT processing to follow
            if(emails.size()>0){
                System.debug('emails: ' + emails);
                Map<String, Object> result = executeSendEmail(emails);
            }
        }
    }

    /*
    * @filename        : sendCommunicationEmailMessageFuture
    * @created         : 29.DEC.2020
    * @author          : JL
    * @description     : This method sends, asynchronously, a list of wrapped Email Message from Communication__c object 
    */
    /* @future
    public static void sendCommunicationEmailMessageFuture(String emailWrapper){
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email;
        if(emailWrapper != null){
            for(singleMailMessageWrapper eWrapper : (List<singleMailMessageWrapper>) JSON.deserialize(emailWrapper,List<singleMailMessageWrapper>.class)){
                email = new Messaging.SingleEmailMessage();
                email.setSaveAsActivity(eWrapper.setSaveAsActivity);
                email.setSubject(eWrapper.setSubject);
                email.setPlainTextBody(eWrapper.setPlainTextBody);//<!--START - ADDED BY JLAURIO 20191129 JCC5862 BUG FIX (JCC-6098) -->
                email.setHtmlBody(eWrapper.setHtmlBody);
                email.setWhatId(eWrapper.setWhatId);
                //email.settargetObjectId(eWrapper.settargetObjectId);
                email.setTemplateId(eWrapper.setTemplateId);
                email.setToAddresses(eWrapper.setToAddresses);
                email.setCcAddresses(eWrapper.setCcAddresses);
                // added 5/22/2021
                email.setOrgWideEmailAddressId(eWrapper.setOrgWideEmailAddressId);
                emails.add(email);
            }
            
            System.debug('sendEmailMessage future');
            Map<String, Object> sendingResponse = null;
            if(emails.size()>0){
                System.debug('emails: ' + emails);
                sendingResponse = executeSendEmail(emails);
            }
            
            if(sendingResponse!=null && sendingResponse.containsKey('hasError')){
                Boolean hasError = (Boolean)sendingResponse.get('hasError');
                Set<Id> successIds = new Set<Id>();
                Map<String, Object> failedResults = new Map<String, Object>();
                if(!hasError){
                    Map<String, Object> resultMap =(Map<String, Object>)sendingResponse.get('resultMap');
                    
                    for(String whatId : resultMap.keySet()){
                       Messaging.SendEmailResult result = (Messaging.SendEmailResult)resultMap.get(whatId);
                        if(result.isSuccess()){
                            successIds.add(whatId);
                        }
                        else{
                            failedResults.put(whatId, result);
                        }
                    }
                }
                else{
                    //overall sending failed
                    //error occured
                }
                //post-sending processing
                if(successIds.size()>0){
                    Map<String, Object> successDMLResults = updateSuccessComms(successIds, null, 0);
                }
                if(failedResults.size()>0){
                    Map<String, Object> failedDMLResults = updateFailedComms(failedResults, 0);
                }
            }
        }
    } */
    
    /*
    * @filename        : sendEmailMessage
    * @created         : 14.DEC.2020
    * @author          : JL
    * @description     : This generic method sends a list of Messaging.SingleEmailMessage real time using Messaging.sendEmail()
    */
    public static Messaging.SendEmailResult[] sendEmailMessage(List<Messaging.SingleEmailMessage> emailObjects){
        Messaging.SendEmailResult [] result = null;
        result = Messaging.sendEmail(emailObjects);         
        return result;
    }
    
    /*
    * @filename        : sendEmailMessage_SingleEmailMessage
    * @created         : 29.DEC.2020
    * @author          : JL
    * @description     : This is an override method sendEmailMessage() which send emails using executeSendEmail() and returns Map<String, Object> 
    */
    public static Map<String, Object> sendEmailMessage_SingleEmailMessage(List<Messaging.SingleEmailMessage> emailObjects){
        Map<String, Object> response = new Map<String, Object>();
        response = EmailUtility.executeSendEmail(emailObjects);
        return response;
    }
    
    /*
    * @filename        : sendEmailMessage_EmailWrapper
    * @created         : 29.DEC.2020
    * @author          : JL
    * @description     : This method sends emails using executeSendEmail() from a list of wrapped Email Message real time
    */
    public static Map<String, Object> sendEmailMessage_EmailWrapper(String emailWrapper){
        Map<String, Object> response = new Map<String, Object>();
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email;
        if(emailWrapper != null){
            for(singleMailMessageWrapper eWrapper : (List<singleMailMessageWrapper>) JSON.deserialize(emailWrapper,List<singleMailMessageWrapper>.class)){
                email = new Messaging.SingleEmailMessage();
                if(eWrapper.setWhatId!=null){
                    email.setSaveAsActivity(false);
                    email.setWhatId(eWrapper.setWhatId);
                }
                email.settargetObjectId(eWrapper.settargetObjectId);
                
                
                if(eWrapper.setTemplateId!=null){
                    email.setTemplateId(eWrapper.setTemplateId);
                }
                if(eWrapper.setSubject!=null){
                    email.setSubject(eWrapper.setSubject);
                }
                if(eWrapper.setHtmlBody!=null){
                    email.setHtmlBody(eWrapper.setHtmlBody);
                }
                
                email.setToAddresses(eWrapper.setToAddresses);
                email.setCcAddresses(eWrapper.setCcAddresses);
                email.setBccAddresses(eWrapper.setBccAddresses);
                
                emails.add(email);
            }
            
            System.debug('sendEmailMessage future');
            Messaging.SendEmailResult[] sendEmailResults = null;
            //LIMIT processing to follow
            if(emails.size()>0){
                System.debug('emails: ' + emails);
                response = EmailUtility.executeSendEmail(emails);
            }
        }
        
        return response;
    }
    
    @InvocableMethod(label='Send Calendar Invites v1.0' description='Send calendar invites to Session Participants' category='Participant__c')
    public static void sendConfirmationCalendarInvite(List<ID> ids) {
        System.debug('*****[sendConfirmationCalendarInvite]ids-->'+ids);
        if(!ids.isEmpty()){
            List<Messaging.SingleEmailMessage> invites = new List<Messaging.SingleEmailMessage>();
            for(Session_Participant__c sessionParticipant : [SELECT Id, Name, Status__c,
                                                                        Participant__c,
                                                                            Participant__r.Member_Contact__c,
                                                                            Participant__r.Member_Contact__r.FirstName,
                                                                            Participant__r.Member_Contact__r.LastName,
                                                                            Participant__r.Member_Contact__r.Email,
                                                                        Event__c,
                                                                            Event__r.Location__c,
                                                                            Event__r.Location__r.Name,
                                                                            Event__r.Email_Sender_Id__c,
                                                                            Event__r.Email_Sender_Name__c,
                                                                        Session__c,
                                                                            Session__r.Name, 
                                                                            Session__r.Description__c, 
                                                                            Session__r.Subtitle__c, 
                                                                            Session__r.Start_Date_Time__c, 
                                                                            Session__r.End_Date_Time__c, 
                                                                            Session__r.Meeting_URL__c, 
                                                                            Session__r.Time_Zone__c
                                                                    FROM Session_Participant__c 
                                                                    WHERE Participant__c IN: ids])
            {
                
                System.debug('*****[sendConfirmationCalendarInvite]sessionParticipant-->'+sessionParticipant);
                String senderName =  'MC Integration User';//FROM default workflow user's email address setup;//need to updated everytime Process Automation Settings(/setup/WorkflowSettings/home) is updated
                String senderEmail =  'alexander@ulapp.co';//FROM default workflow user's email address setup;//need to updated everytime Process Automation Settings(/setup/WorkflowSettings/home) is updated
                String subject = '';
                if(sessionParticipant.Session__r.Name!=null){
                    subject = sessionParticipant.Session__r.Name;
                }
                System.debug('*****[sendConfirmationCalendarInvite]subject-->'+subject);
                String title = '';
                if(sessionParticipant.Session__r.Name!=null){
                    title = sessionParticipant.Session__r.Name;
                    
                    if(sessionParticipant.Session__r.Subtitle__c!=null){
                        title +=' - '+ sessionParticipant.Session__r.Subtitle__c;
                    }
                }
                System.debug('*****[sendConfirmationCalendarInvite]title-->'+title);
                String location = '';
                if(sessionParticipant.Event__r.Location__r.Name!=null){
                    location = sessionParticipant.Event__r.Location__r.Name;
                }
                System.debug('*****[sendConfirmationCalendarInvite]location-->'+location);
                Datetime startDateTime = null;
                if(sessionParticipant.Session__r.Start_Date_Time__c!=null){
                    startDateTime = sessionParticipant.Session__r.Start_Date_Time__c;
                }
                System.debug('*****[sendConfirmationCalendarInvite]startDateTime-->'+startDateTime);
                Datetime endDateTime = null;
                if(sessionParticipant.Session__r.End_Date_Time__c!=null){
                    endDateTime = sessionParticipant.Session__r.End_Date_Time__c;
                }
                System.debug('*****[sendConfirmationCalendarInvite]endDateTime-->'+endDateTime);
                String description = '';
                if(sessionParticipant.Session__r.Name!=null){
                    description = 'Session Description: '+ sessionParticipant.Session__r.Description__c;
                    
                    if(sessionParticipant.Session__r.Meeting_URL__c!=null){
                        description +=' \n Virtual Meeting Link: '+ sessionParticipant.Session__r.Meeting_URL__c;
                    }
                }
                System.debug('*****[sendConfirmationCalendarInvite]description-->'+description);
                List<String> toList = new List<String>();
                if(sessionParticipant.Participant__r.Member_Contact__r.Email!=null){
                   toList.add(sessionParticipant.Participant__r.Member_Contact__r.Email);
                }

                Messaging.SingleEmailMessage invite = EmailUtility.buildCalendarInvite(toList,
                                                            senderEmail,
                                                            senderName,
                                                            subject,//'SAMPLE CALENDAR INVITE SUBJECT',
                                                            title,//'MEETING INVITE TITLE',
                                                            location,//'MEETING LOCATION',
                                                            startDateTime,
                                                            endDateTime,
                                                            datetime.now(),
                                                            description,
                                                            datetime.now());
                invites.add(invite);
            }
            if(!invites.isEmpty()){
                Messaging.SendEmailResult[] result = EmailUtility.sendEmailMessage(invites);// CalendarInvites.sendinvite(invites);
            }
        }
    }
    
    /*
    * @filename        : buildEmailMessage
    * @created         : 29.DEC.2020
    * @author          : JL
    * @description     : This generic method creates an instance of Messaging.SingleEmailMessage
    */
    public static Messaging.SingleEmailMessage buildEmailMessage(SObject whatObj, 
                                                                 String targetObjectId,
                                                                 String templateId,
                                                                 String subject,
                                                                 String htmlBody,
                                                                 List<String> toAddresses,
                                                                 List<String> ccAddresses,
                                                                 List<String> bccAddresses)
    {
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setsaveAsActivity(false); 
        if(whatObj!=null){
            emailMessage.setWhatId(whatObj.Id);
        }
        
        if(targetObjectId!=null){
            emailMessage.settargetObjectId(targetObjectId);  
        }
        if(templateId!=null){
            emailMessage.setTemplateId(templateId); 
        }
        if(subject!=null){
            emailMessage.setSubject(subject);
        }
        if(htmlBody!=null){
            emailMessage.setHtmlBody(htmlBody);
        }
        if(!toAddresses.isEmpty()){
            emailMessage.setToAddresses(toAddresses);
        }
        if(!ccAddresses.isEmpty()){
            emailMessage.setCcAddresses(ccAddresses);
        }
        if(!bccAddresses.isEmpty()){
            emailMessage.setBccAddresses(bccAddresses);
        }
        return emailMessage;
    }
    
    /*
    * @filename        : buildCommunicationEmailMessage
    * @created         : 14.DEC.2020
    * @author          : JL
    * @description     : This method creates an instance of Messaging.SingleEmailMessage
    */
    public static Map<String, Object> buildCommunicationEmailMessage(Communication__c whatObj, 
                                                                    Map<Id, List<Communication_Recipient__c>> recipientsPerCommsMap,
                                                                    String orgWideEmailId)
    {
        Map<String, Object> response = new Map<String, Object>();
        Boolean hasError = false;
        List<String> messages = new List<String>();
        EmailTemplate template = null;
        
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        List<String> emailToAddresses = new List<String>();
        List<String> emailCCAddresses = new List<String>();
        List<String> emailBCCAddresses = new List<String>();
        emailMessage.setsaveAsActivity(false); 
        
        if(settings==null){
           settings = Email_Settings__c.getOrgDefaults();
        }       
        /*
        if(settings.Default_Org_Wide_Email_Id__c != null){
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: settings.Default_Org_Wide_Email_Id__c];
            if ( owea.size() > 0 ) {
                emailMessage.setOrgWideEmailAddressId(owea[0].id);
            }
        }
        */
        if(orgWideEmailId!=null){
            emailMessage.setOrgWideEmailAddressId(orgWideEmailId);
        }
        
        if(whatObj!=null){
            emailMessage.setWhatId(whatObj.Id);
            
            if(whatObj.OwnerId!=null){
                emailMessage.settargetObjectId(whatObj.OwnerId);  
            }
            if(whatObj.Email_Template_Id__c!=null){
                emailMessage.setTemplateId(whatObj.Email_Template_Id__c); 
            }
            if(whatObj.Subject__c!=null){
                emailMessage.setSubject(whatObj.Subject__c);
            }
            if(whatObj.Body__c!=null){
                emailMessage.setHtmlBody(whatObj.Body__c);
            }
            if(!recipientsPerCommsMap.isEmpty()&&recipientsPerCommsMap.containsKey(whatObj.Id)){
                for(Communication_Recipient__c recipient: recipientsPerCommsMap.get(whatObj.Id)){
                    if(recipient.Journey_Participant__c!=null && recipient.Journey_Participant__r.Contact__c!=null){
                        emailToAddresses.add(recipient.Journey_Participant__r.Contact__r.Email);
                    }
                }
                system.debug('[buildEmailMessage]emailToAddresses-->'+emailToAddresses);
                
                if(emailToAddresses.size() <= settings.Max_Email_To_Number__c){
                    emailMessage.setToAddresses(emailToAddresses);
                }
                else{
                    hasError = true;
                    messages.add(settings.Email_To_Limit_Error_Message__c);
                }
            }
            
            if(whatObj.Email_Recipient_CC__c!=null && String.isNotEmpty(whatObj.Email_Recipient_CC__c)) {
                emailCCAddresses.addAll(whatObj.Email_Recipient_CC__c.replace(' ','').split(','));
                system.debug('[buildEmailMessage]emailCCAddresses-->'+emailCCAddresses);
                
                if(emailCCAddresses.size() <= settings.Max_Email_CC_BCC_Number__c){
                    emailMessage.setCcAddresses(emailCCAddresses);
                }
                else{
                    hasError = true;
                    messages.add(settings.Email_CC_Limit_Error_Message__c);
                }
            }
            
            if(whatObj.Email_Recipient_BCC__c!=null && String.isNotEmpty(whatObj.Email_Recipient_BCC__c)) {
                emailBCCAddresses.addAll(whatObj.Email_Recipient_BCC__c.replace(' ','').split(','));
                system.debug('[buildEmailMessage]emailBCCAddresses-->'+emailBCCAddresses);
                
                if(emailBCCAddresses.size() <= settings.Max_Email_CC_BCC_Number__c){
                    emailMessage.setBccAddresses(emailBCCAddresses);
                }
                else{
                    hasError = true;
                    messages.add(settings.Email_BCC_Limit_Error_Message__c);
                }
            }
        }
        else{
            hasError = true;
            messages.add('Communications record error.');
        }
        response.put('hasError', hasError);
        response.put('messages', messages);
        if(!hasError){
            response.put('emailMessage', emailMessage);
        }
        
        return response;
    }
    
    /*
    * @filename        : wrapEmailMessage
    * @created         : 05.JAN.2021
    * @author          : JL
    * @description     : This method creates an instance of singleMailMessageWrapper
    */
    public static singleMailMessageWrapper wrapEmailMessage(String whatId, 
                                                             String targetObjectId,
                                                             String templateId,
                                                             String subject,
                                                             String htmlBody,
                                                             List<String> toAddresses,
                                                             List<String> ccAddresses,
                                                             List<String> bccAddresses)
    {
        singleMailMessageWrapper emailMessage = new singleMailMessageWrapper();
        if(whatId!=null){
            emailMessage.setWhatId = whatId;
        }
        if(targetObjectId!=null){
            emailMessage.settargetObjectId = targetObjectId;  
        }
        if(templateId!=null){
            emailMessage.setTemplateId = templateId; 
        }
        if(subject!=null){
            emailMessage.setSubject = subject;
        }
        if(htmlBody!=null){
            emailMessage.setHtmlBody = htmlBody;
        }
        if(!toAddresses.isEmpty()){
            emailMessage.setToAddresses = toAddresses;
        }
        if(!ccAddresses.isEmpty()){
            emailMessage.setCcAddresses = ccAddresses;
        }
        if(!bccAddresses.isEmpty()){
            emailMessage.setBccAddresses = bccAddresses;
        }
        return emailMessage;                                                                
    }
    
    /*
    * @filename        : wrapCommunicationEmailMessage
    * @created         : 05.JAN.2021
    * @author          : JL
    * @description     : This method creates an instance of singleMailMessageWrapper from Communication__c object and Communication_Recipient__c;
    *                       returns Map<String, Object> consists of the following key string values:
    *                       1. 'hasError' - boolean; flag if there is an error;
    *                       2. 'messages' - List<String>; contains a list of error messages;
    *                       3. 'emailMessage' - singleMailMessageWrapper; contains wrapped Communication__c record
    */
    public static Map<String, Object> wrapCommunicationEmailMessage(Communication__c whatObj, 
                                                                 Map<Id, List<Communication_Recipient__c>> recipientsPerCommsMap)
    {
        Map<String, Object> response = new Map<String, Object>();
        Boolean hasError = false;
        List<String> messages = new List<String>();
        EmailTemplate template = null;
        
        singleMailMessageWrapper emailMessage = new singleMailMessageWrapper();
        List<String> emailToAddresses = new List<String>();
        List<String> emailCCAddresses = new List<String>();
        List<String> emailBCCAddresses = new List<String>();
        emailMessage.setSaveAsActivity = false;
        
        if(settings==null){
           settings = Email_Settings__c.getOrgDefaults();
        }
            
        if(whatObj!=null){
            emailMessage.setWhatId = whatObj.Id;
            
            // added 5/22/2021
            if(whatObj.Organization_Wide_Email_Id__c!=null){
                emailMessage.setOrgWideEmailAddressId = whatObj.Organization_Wide_Email_Id__c;
            }

            if(whatObj.OwnerId!=null){
                emailMessage.settargetObjectId = whatObj.OwnerId;    
            }
            
            if(whatObj.Email_Template_Id__c!=null){
                emailMessage.setTemplateId = whatObj.Email_Template_Id__c; 
            }
            if(whatObj.Subject__c!=null){
                emailMessage.setSubject = whatObj.Subject__c;
            }
            if(whatObj.Body__c!=null){
                emailMessage.setHtmlBody = whatObj.Body__c;
            }
            if(!recipientsPerCommsMap.isEmpty()&&recipientsPerCommsMap.containsKey(whatObj.Id)){
                for(Communication_Recipient__c recipient: recipientsPerCommsMap.get(whatObj.Id)){
                    if(recipient.Journey_Participant__c!=null && recipient.Journey_Participant__r.Contact__c != null){ 
                        emailToAddresses.add(recipient.Journey_Participant__r.Contact__r.Email);
                    }
                    // added additional check for recipient's direct relationship to contact - (Task # - 01003) JLabnao
                    else if(recipient.Contact__c != null || recipient.Email__c != null){
                        String emailAddress = recipient.Contact__r.Email != null ? recipient.Contact__r.Email : recipient.Email__c;
                        System.debug('Email Address >>> ' + emailAddress);
                        emailToAddresses.add(emailAddress);
                    }
                }
                
                if(emailToAddresses.size() <= settings.Max_Email_To_Number__c){
                    emailMessage.setToAddresses = emailToAddresses;
                }
                else{
                    hasError = true;
                    messages.add(settings.Email_To_Limit_Error_Message__c);
                }
            }
            
            if(whatObj.Email_Recipient_CC__c!=null && String.isNotEmpty(whatObj.Email_Recipient_CC__c)) {
                emailCCAddresses.addAll(whatObj.Email_Recipient_CC__c.replace(' ','').split(','));
                system.debug('[buildEmailMessage]emailCCAddresses-->'+emailCCAddresses);
                
                if(emailCCAddresses.size() <= settings.Max_Email_CC_BCC_Number__c){
                    emailMessage.setCcAddresses = emailCCAddresses;
                }
                else{
                    hasError = true;
                    messages.add(settings.Email_CC_Limit_Error_Message__c);
                }
            }
            
            if(whatObj.Email_Recipient_BCC__c!=null && String.isNotEmpty(whatObj.Email_Recipient_BCC__c)) {
                emailBCCAddresses.addAll(whatObj.Email_Recipient_BCC__c.replace(' ','').split(','));
                system.debug('[buildEmailMessage]emailBCCAddresses-->'+emailBCCAddresses);
                
                if(emailBCCAddresses.size() <= settings.Max_Email_CC_BCC_Number__c){
                    emailMessage.setBccAddresses = emailBCCAddresses;
                }
                else{
                    hasError = true;
                    messages.add(settings.Email_BCC_Limit_Error_Message__c);
                }
            }
            response.put('hasError', hasError);
            response.put('messages', messages);
            if(!hasError){
                response.put('emailMessage', emailMessage);
            }
        }
        
        return response;                                                            
    }
    
    /*
    * @filename        : buildCalendarInvite
    * @created         : 19.JAN.2021
    * @author          : JL
    * @description     : This method creates an instance of singleMailMessageWrapper from parameters which calls createCalendarICS for building invite file
    */
    public static Messaging.SingleEmailMessage buildCalendarInvite(List<string> emailsList, 
                                                                    string Organiser, 
                                                                    string name, 
                                                                    string subject, 
                                                                    string title, 
                                                                    string location, 
                                                                    dateTime startDate, 
                                                                    dateTime endDate, 
                                                                    dateTime createdDate, 
                                                                    string description, 
                                                                    dateTime lastmodifiedDate){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setToAddresses(emailsList);
        mail.setSubject(subject);      
        mail.setPlainTextBody(description);     
        mail.setHtmlBody(description);     
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();   
        attach.filename = 'reminder.ics'; 
        attach.ContentType = 'text/calendar';     
        attach.inline = true;     
        attach.body = createCalendarICS(emailsList, Organiser, name, subject, 
                                        title, location, 
                                        startDate, endDate, 
                                        createdDate, description, 
                                        lastmodifiedDate );   
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {attach}); 

        return mail;
    }
    
    /*
    * @filename        : createCalendarICS
    * @created         : 19.JAN.2021
    * @author          : JL
    * @description     : This method is for building calndar invite file
    */
    public static Blob createCalendarICS(List<String> emailsList, 
                              string Organiser, 
                              string name, 
                              string subject,
                              string title, 
                              string location, 
                              dateTime startDate, 
                              dateTime endDate, 
                              dateTime createdDate, 
                              string description, 
                              dateTime lastmodifiedDat) {
        String txtInvite = '';
        string startdateTime;
        string enddateTIme;
        string createdDateTime;
        string lastmodifiedDatTime;
 
        startdateTime = startDate.formatGMT('yyyyMMdd\'T\'HHmmss\'Z\'');
        enddateTIme = endDate.formatGMT('yyyyMMdd\'T\'HHmmss\'Z\'');
        createdDateTime = createdDate.formatGMT('yyyyMMdd\'T\'hhmmss\'Z\'');
        lastmodifiedDatTime = lastmodifiedDat.formatGMT('yyyyMMdd\'T\'hhmmss\'Z\'');
 
        txtInvite += 'BEGIN:VCALENDAR\n';
        txtInvite += 'PRODID:-//Microsoft Corporation//Outlook 16.0 MIMEDIR//EN\n';
        txtInvite += 'VERSION:2.0\n';
        txtInvite += 'CALSCALE:GREGORIAN\n';
        txtInvite += 'METHOD:REQUEST\n';
        txtInvite += 'REPLAY:ACCEPTED\n';
        txtInvite += 'BEGIN:VEVENT\n';
        txtInvite += 'ATTENDEE\n';
        txtInvite += 'CN=' + subject + '\n';
        for (String email: emailsList) {
            txtInvite += 'ATTENDEE:' + email + '\n';
        }
        txtInvite += 'X-MS-OLK-FORCEINSPECTOROPEN:TRUE\n';
        //txtInvite += 'X-WR-RELCALID:{0000002E-9CDF-9CE8-AD4C-66FC0A5A25F7}\n';
        txtInvite += 'CLASS:PUBLIC\n';
        txtInvite += 'CREATED:' + createdDateTime+'\n';
        txtInvite += 'DTEND:' + enddateTIme+'\n';
        txtInvite += 'DTSTART:' + startdateTime+'\n';
        txtInvite += 'LAST-MODIFIED:' + lastmodifiedDatTime+'\n';
        txtInvite += 'ORGANIZER;CN=' + name + ':mailto:' + Organiser + '\n';
        txtInvite += 'RSVP=TRUE\n';
        txtInvite += 'ROLE=REQ-PARTICIPANT\n';
        txtInvite += 'PARTSTAT=NEEDS-ACTION\n';
        txtInvite += 'CN=' + subject + ':mailto:' + Organiser + '\n';
        txtInvite += 'LOCATION:'+ location +'\n';
        txtInvite += 'PRIORITY:5\n';
        txtInvite += 'SEQUENCE:0\n';
        txtInvite += 'SUMMARY:'+title+'\n';//THIS IS SUMMARY TEXT
        txtInvite += 'STATUS:NEEDS-ACTION\n';
        txtInvite += 'LANGUAGE=en-us:'+title+'\n';
        txtInvite += 'TRANSP:OPAQUE\n';
        //txtInvite += 'UID:4036587160834EA4AE7848CBD028D1D200000000000000000000000000000000\n';
        txtInvite += 'X-ALT-DESC;FMTTYPE=text/html:';
                txtInvite += '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2//EN">';
                txtInvite += '\n<HTML>';
                txtInvite += '\n<HEAD>';
                txtInvite += '\n<META NAME="Generator" CONTENT="MS Exchange Server version 08.00.0681.000">';
                txtInvite += '\n<TITLE>This is a title in the HEAD</TITLE>';
                txtInvite += '\n</HEAD>';
                txtInvite += '\n<BODY>';
                txtInvite += '\n<p>Hello <b>Bold</b> New World</p><p>'+description+'</p><!-- Converted from text/plain format -->';
                txtInvite += '\n</BODY>';
                txtInvite += '\n</HTML>\n';
        txtInvite += 'X-MICROSOFT-CDO-BUSYSTATUS:BUSY\n';
        txtInvite += 'X-MICROSOFT-CDO-IMPORTANCE:1\n';
        txtInvite += 'BEGIN:VALARM\n';
        txtInvite += 'TRIGGER:-PT15M\n';
        txtInvite += 'ACTION:DISPLAY\n';
        txtInvite += 'STATUS:CONFIRMED\n';
        txtInvite += 'DESCRIPTION:'+description+'\n';//Reminder
        txtInvite += 'END:VALARM\n';
        txtInvite += 'END:VEVENT\n';
        txtInvite += 'END:VCALENDAR';
        return Blob.valueOf(txtInvite);
    }
    
    /*
    * @filename        : updateSuccessComms
    * @created         : 05.JAN.2021
    * @author          : JL
    * @description     : This method processes successfully-sent-Communication__c records
    *                       returns Map<String, Object> consists of the following key string values:
    *                       1. 'hasError' - boolean; flag if there is an error;
    *                       2. 'messages' - List<String>; contains a list of error messages;
    */
    public static Map<String, Object> updateSuccessComms(Set<Id> commsIds, List<Communication_Recipient__c> recipientsList, Integer counter){
        Map<String, Object> response = new Map<String, Object>();
        Boolean hasError = false;
        List<String> messages = new List<String>();
        List<Communication__c> updatedComms = new List<Communication__c>();
        List<Communication_Recipient__c> updatedRecipients = new List<Communication_Recipient__c>();
        
        DateTime sentDateTime = datetime.now();

        for(Communication__c comms : [SELECT Id, Status__c, Status_Detail__c,
                                        Email_Date_and_Time__c,
                                        (SELECT Id, Date_Sent__c FROM CC_Communication_Recipients__r)
                                        FROM Communication__c 
                                        WHERE Id IN: commsIds])
        {
            comms.Active__c = false;
            comms.Status__c = COMM_STATUS_SENT;//'Sent';
            String previousStatusDetail = '';
            if(comms.Status_Detail__c!=null){
                previousStatusDetail = comms.Status_Detail__c;
            }
            String newStatusDetail = sentDateTime.format() +': Email Sent: Chunk '+ counter +'\n'+previousStatusDetail;
            comms.Status_Detail__c = newStatusDetail; //CCN-1122 Xen Reyes Jan. 15, 2022
            comms.Email_Date_and_Time__c = sentDateTime;
            updatedComms.add(comms);
            if(comms.CC_Communication_Recipients__r.size()>0){
                for(Communication_Recipient__c recipient: comms.CC_Communication_Recipients__r){
                    Communication_Recipient__c updatedRecipient = recipient;
                    updatedRecipient.Date_Sent__c = sentDateTime.date();
                    updatedRecipients.add(updatedRecipient);
                }
            }
        }
        
        try{
            if(updatedComms.size()>0){
                update updatedComms;
            }
            if(updatedRecipients.size()>0){
                update updatedRecipients;
            }

            hasError = false;
        }
        catch(Exception e){
            hasError = true;
            messages.add(e.getMessage());
        }
        response.put('hasError', hasError);
        response.put('messages', messages);
        
        return response;
    }
    
    /*
    * @filename        : updateFailedComms
    * @created         : 05.JAN.2021
    * @author          : JL
    * @description     : This method processes Communication__c records that failed in email sending
    *                       returns Map<String, Object> consists of the following key string values:
    *                       1. 'hasError' - boolean; flag if there is an error;
    *                       2. 'messages' - List<String>; contains a list of error messages;
    */
    public static Map<String, Object> updateFailedComms(Map<String, Object> resultMap, Integer counter){
        Map<String, Object> response = new Map<String, Object>();
        Boolean hasError = false;
        List<String> messages = new List<String>();
        List<Communication__c> updatedComms = new List<Communication__c>();
        List<Communication_Recipient__c> updatedRecipients = new List<Communication_Recipient__c>();
        
        DateTime failedDateTime = datetime.now();

        for(Communication__c comms : [SELECT Id, Status__c, Status_Detail__c,
                                        Email_Date_and_Time__c
                                        FROM Communication__c 
                                        WHERE Id IN: resultMap.keySet()])
        {
            String sendEmailErrorMessage = '';
            for(Messaging.SendEmailError err : ((Messaging.SendEmailResult)resultMap.get(comms.Id)).getErrors()) {
                sendEmailErrorMessage = err.getStatusCode() + ': ' + err.getMessage() + '\n' + sendEmailErrorMessage;
            }
            comms.Status__c = COMM_STATUS_FAILED;//'Failed';
            String previousStatusDetail = '';
            if(comms.Status_Detail__c!=null){
                previousStatusDetail = comms.Status_Detail__c;
            }
            String statusDetail = failedDateTime.format() +': Email Sending Failed. Chunk ' + counter +  '\n Error/s: ' +sendEmailErrorMessage+ '\n' +previousStatusDetail;
            comms.Status_Detail__c = statusDetail; //CCN-1122 Xen Reyes Jan. 15, 2022
            updatedComms.add(comms);
            hasError = false;
        }
        
        try{
            if(updatedComms.size()>0){
                update updatedComms;
            }           
        }
        catch(Exception e){
            hasError = true;
            messages.add(e.getMessage());
        }
        response.put('hasError', hasError);
        response.put('messages', messages);
        
        return response;
    }
    
    /*
    * @filename        : getCreatableFieldsSOQL
    * @created         : 05.JAN.2021
    * @author          : JL
    * @description     : getCreatableFieldsSOQL Returns a dynamic SOQL statement for the whole object, includes only creatable fields
    * @returns         : String
    */
    public static String getCreatableFieldsSOQL(String objectAPIName, String whereClause){
        String selects = '';
        String objName = String.escapeSingleQuotes(objectAPIName);
        //if (whereClause == null || whereClause == ''){ return null; }
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objName.toLowerCase('en')).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();
        
        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                
                if (fd.isCreateable()){ // field is creatable
                    selectFields.add(fd.getName());
                }               
            }
        }
        
        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + ',';
            }
            if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}
            
        }
        String returnString = '';
        if(String.isNotBlank(whereClause)){
            returnString = 'SELECT ' + selects + ' FROM ' + objName + ' WHERE ' + whereClause;
        }
        else{
            returnString = 'SELECT ' + selects + ' FROM ' + objName;
        }
        return returnString;
        
    }
    /*
    * @filename        : buildCommunicationEmailList
    * @created         : 04.MAR.2021
    * @author          : JLabn
    * @description     : This method creates a List of Responses that contains the SingleEmailMessage intended for 1 Communication Recipient.
    *                       Returns List<Map<String, Object>>, the element of this List consists of the following key string values:
    *                       1. 'hasError' - boolean; flag if there is an error;
    *                       2. 'messages' - List<String>; contains a list of error messages;
    *                       3. 'emailMessage' - Messaging.SingleEmailMessage; contains wrapped Communication__c record for a single Recipient.
    * @revision         : Fixed 'too many soql' -- getEmailTemplateAttachments and getContentDocuments
    */
    public static List<Map<String, Object>> buildCommunicationEmailList(Communication__c whatObj, 
                                                                        List<Communication_Recipient__c> commsRecipients,
                                                                        String orgWideEmailId)
    {
        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        List<String> contentDocFiles = new List<String>();

        if(whatObj.Email_Template_Id__c!=null){
            emailAttachments = getEmailTemplateAttachments(whatObj.Email_Template_Id__c);

            if(whatObj.Email_Template_Id__c!=null) {
                contentDocFiles = getContentDocuments(whatObj.Email_Template_Id__c, whatObj.Id);
            }
        }

        //CCN-1004 Xen Reyes January 25, 2022
        //Get CC & BCC Communication Recipient
        List<Communication_Recipient__c> commsRecipientsCCBCC = [SELECT Id, Contact__r.Email,Send_as__c FROM Communication_Recipient__c
                                                                                      WHERE Send_as__c IN ('CC','BCC')
                                                                                      AND CC_Communication__c =: whatObj.Id];

        for(Communication_Recipient__c commsRecipient : commsRecipients){
            Map<String, Object> response = new Map<String, Object>();
            Boolean hasError = false;
            Boolean hasTemplate = false;
            List<String> messages = new List<String>();
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            // emailToAddresses is a list of contact ids
            List<String> emailToAddresses = new List<String>();
            List<String> emailCCAddresses = new List<String>();
            List<String> emailBCCAddresses = new List<String>();

            //CCN-1004 Xen Reyes January 25, 2022
            //Get all CC & BCC email addresses
            if(!commsRecipientsCCBCC.isEmpty()){
                for(Communication_Recipient__c ccVar : commsRecipientsCCBCC){
                    if(ccVar.Send_as__c == 'CC') emailCCAddresses.add(ccVar.Contact__r.Email);
                    if(ccVar.Send_as__c == 'BCC') emailBCCAddresses.add(ccVar.Contact__r.Email);
                }
            }

            //Updated by Xen Reyes [CCN691] 10082021
            //This will automatically create an email message object when using single email messaging
            emailMessage.setsaveAsActivity(true); 

            emailMessage.setOptOutPolicy('FILTER');
            
            if(settings==null){
               settings = Email_Settings__c.getOrgDefaults();
            }

            if(String.isNotBlank(orgWideEmailId)){
                emailMessage.setOrgWideEmailAddressId(orgWideEmailId);
            }
            
            if(whatObj!=null){
                emailMessage.setWhatId(whatObj.Id);
                
                if(whatObj.Reply_Email_Address__c != null){
                    emailMessage.setReplyTo(whatObj.Reply_Email_Address__c);
                }
                
                if(whatObj.Email_Template_Id__c!=null){
                    hasTemplate = true;
                    //emailMessage.setTemplateId(whatObj.Email_Template_Id__c);
                    //List<Messaging.EmailFileAttachment> emailAttachments = getEmailTemplateAttachments(whatObj.Email_Template_Id__c);
                    if(emailAttachments.size() > 0){
                        emailMessage.setFileAttachments(emailAttachments);
                    }
                    //Updated by Xen Reyes [CCN691/814] 10082021
                    //List<String> contentDocFiles = getContentDocuments(whatObj.Email_Template_Id__c, whatObj.Id);
                    if(!contentDocFiles.isEmpty()){
                        emailMessage.setEntityAttachments(contentDocFiles);
                    }
                }
                
                if(whatObj.Subject__c!=null){
                    emailMessage.setSubject(whatObj.Subject__c);
                }
                if(whatObj.Body__c!=null){
                    emailMessage.setTreatBodiesAsTemplate(true);
                    emailMessage.setHtmlBody(whatObj.Body__c);
                }
                if(commsRecipient != null){
                    if(commsRecipient.Contact__c != null){
                        emailMessage.setTargetObjectId(commsRecipient.Contact__c);
                    }
                    else if(commsRecipient.Journey_Participant__c!=null && commsRecipient.Journey_Participant__r.Contact__c!=null){
                        emailMessage.setTargetObjectId(commsRecipient.Journey_Participant__r.Contact__c);
                    }
                    else if(commsRecipient.Survey_Participant__c!=null && commsRecipient.Survey_Participant__r.Participant__c!=null){
                        emailMessage.setTargetObjectId(commsRecipient.Survey_Participant__r.Participant__c);
                    }
                    else if(commsRecipient.Event_Participant__c!=null && commsRecipient.Event_Participant__r.Member_Contact__c!=null){
                        emailMessage.setTargetObjectId(commsRecipient.Event_Participant__r.Member_Contact__c);
                    }
                    else{
                        hasError = true;
                        messages.add('Communication Recipient has no contact related to it.');
                    }
                }

                //CCN-1004 Xen Reyes January 25, 2022
                if(!emailCCAddresses.isEmpty()){
                    if(emailCCAddresses.size() <= settings.Max_Email_CC_BCC_Number__c){
                        emailMessage.setCcAddresses(emailCCAddresses);
                    }
                    else{
                        hasError = true;
                        messages.add(settings.Email_CC_Limit_Error_Message__c);
                    }
                }

                if(!emailBCCAddresses.isEmpty()){
                    if(emailBCCAddresses.size() <= settings.Max_Email_CC_BCC_Number__c){
                        emailMessage.setBccAddresses(emailBCCAddresses);
                    }
                    else{
                        hasError = true;
                        messages.add(settings.Email_BCC_Limit_Error_Message__c);
                    }
                }

                /* if(whatObj.Email_Recipient_CC__c!=null && String.isNotEmpty(whatObj.Email_Recipient_CC__c)) {
                    emailCCAddresses.addAll(whatObj.Email_Recipient_CC__c.replace(' ','').split(','));
                    system.debug('[buildCommunicationEmailList]emailCCAddresses-->'+emailCCAddresses);
                    
                    if(emailCCAddresses.size() <= settings.Max_Email_CC_BCC_Number__c){
                        emailMessage.setCcAddresses(emailCCAddresses);
                    }
                    else{
                        hasError = true;
                        messages.add(settings.Email_CC_Limit_Error_Message__c);
                    }
                }
                if(whatObj.Email_Recipient_BCC__c!=null && String.isNotEmpty(whatObj.Email_Recipient_BCC__c)) {
                    emailBCCAddresses.addAll(whatObj.Email_Recipient_BCC__c.replace(' ','').split(','));
                    system.debug('[buildCommunicationEmailList]emailBCCAddresses-->'+emailBCCAddresses);
                    
                    if(emailBCCAddresses.size() <= settings.Max_Email_CC_BCC_Number__c){
                        emailMessage.setBccAddresses(emailBCCAddresses);
                    }
                    else{
                        hasError = true;
                        messages.add(settings.Email_BCC_Limit_Error_Message__c);
                    }
                } */
            }
            else{
                hasError = true;
                messages.add('Communications record error.');
            }

            response.put('hasError', hasError);
            response.put('messages', messages);
            if(!hasError){
                response.put('emailMessage', emailMessage);
            }
            responseList.add(response);
        }
        
        return responseList;
    }

    /*
    * @filename        : sendCommunicationEmailMessages
    * @created         : 28.MAR.2021
    * @author          : JLabn
    * @description     : This method uses executeSendEmail to send a List of Messaging.SingleEmailMessage and update Success and Failed sending.

    */
    public static String sendCommunicationEmailMessages(Communication__c communication, List<Messaging.SingleEmailMessage> emails, List<Communication_Recipient__c> recipientsList, Integer counter){
        String errorMessages = '';
        Map<String, Object> sendingResponse = null;
        if(!emails.isEmpty()){
            sendingResponse = executeSendEmail(emails);
        }

        if(sendingResponse!=null && sendingResponse.containsKey('hasError')){
            Boolean hasError = (Boolean)sendingResponse.get('hasError');
            Set<Id> successIds = new Set<Id>();
            Map<String, Object> failedResults = new Map<String, Object>();
            if(!hasError){
                Map<String, Object> resultMap =(Map<String, Object>)sendingResponse.get('resultMap');
                List<Messaging.SendEmailError> emailErrorList = new List<Messaging.SendEmailError>();
                for(String whatId : resultMap.keySet()){
                    Messaging.SendEmailResult result = (Messaging.SendEmailResult)resultMap.get(whatId);
                    if(result.isSuccess()){
                        //System.debug('Success email sent');
                        successIds.add(whatId);
                    }
                    else{
                        emailErrorList.addAll(result.getErrors());
                        failedResults.put(whatId, result);
                    }
                }
                for(Messaging.SendEmailError emailError : emailErrorList){
                    String error = emailError.getStatusCode() + ': ' + emailError.getMessage();
                    if(!errorMessages.contains(error)){
                        errorMessages += error + '  |  ';
                    }
                }
                System.debug('sendCommunicationEmailMessages >> errorMessages ' + errorMessages);
            }
            else{
                //overall sending failed
                //error occured
                System.debug('[sendCommunicationEmailMessages]Error Messages-->' + sendingResponse.get('messages'));
            }
            //post-sending processing
            if(!successIds.isEmpty()){

                //CCN-1122 Xen Reyes Jan. 15, 2022
                Map<String, Object> successDMLResults = updateSuccessComms(successIds, recipientsList, counter);
                
                if (communication != null){
                    updateParticipants(successIds, recipientsList);
                }
            }
            if(!failedResults.isEmpty()){
                Map<String, Object> failedDMLResults = updateFailedComms(failedResults, counter);
            }
        }

        return errorMessages;
    }

    private static void updateParticipants(Set<Id> whatIds, List<Communication_Recipient__c> recipientsList){
        List<Sobject> participantList = new List<Sobject>();

        //CCN-1122 Xen Reyes Jan. 15, 2022
        //Updated the query to only the include the recipients in scope

        //query for survey participants if there is a what id for survey participant
        for (Communication_Recipient__c participant : [SELECT Id, Event_Participant__c, Survey_Participant__c FROM Communication_Recipient__c 
                                                        WHERE CC_Communication__c IN :whatIds AND Id IN: recipientsList]){
            
            if (participant.Event_Participant__c != null){
                participantList.add(new Participant__c(Id = participant.Event_Participant__c, Survey_Status__c = PARTICIPANT_STATUS_SENT));
            } else if (participant.Survey_Participant__c != null){
                participantList.add(new Survey_Participant__c(Id = participant.Survey_Participant__c, Status__c = PARTICIPANT_STATUS_SENT));
            }
        }

        if (!participantList.isEmpty()){
            update participantList;
        }
    }
    
    public static List<Messaging.EmailFileAttachment> getEmailTemplateAttachments(String emailTemplateId){
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        
        List<Attachment> files = [SELECT Name, Body, ContentType, ParentId FROM Attachment WHERE ParentId =:emailTemplateId];
        
        for (Attachment file: files) {
          Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
          efa.setFileName(file.Name);
          efa.setBody(file.Body);
          efa.setContentType(file.ContentType);
          attachments.add(efa);
        }

        return attachments;
    }

     /*******************************************************************************************
  * @name: getContentDocuments
  * @author: Abram Reyes
  * @created: 14-10-2021
  * @description: TO CATER RELATED FILES ATTACHED IN LIGHTNING EMAIL TEMPLATES & TO THE WHAT ID (e.g. Communications) RECORD
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *       No.  Date(dd-mm-yyy) Author         Description
  *       ----  ---------   --------------------  -----------------------------
  * @version   1.0  8-10-2021   Abram Reyes      [CCN691/814] Initial version.
  *********************************************************************************************/
    public static List<String> getContentDocuments (String emailTemplateId, String whatObjId){
        
        Set<String> contentDocumentIdList = new Set<String>();
        List<String> contentVersionidList = new List<String>();
        
        for(ContentDocumentLink cdVar : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: emailTemplateId OR LinkedEntityId =: whatObjId]){
            contentDocumentIdList.add(cdVar.ContentDocumentId);
        }

        if(!contentDocumentIdList.isEmpty()){
            for(ContentVersion cvVar : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN: contentDocumentIdList]){
                contentVersionidList.add(cvVar.Id);
            }
        }
        return contentVersionidList;
    }
}