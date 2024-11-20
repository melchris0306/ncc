public with sharing class CommunicationEmail_Controller {
    private static final Integer MAX_RESULT = 10;
    private static final String CAMPAIGN_API_NAME = Campaign__c.sObjectType.getDescribe().getName();
    private static final String JOURNEY_API_NAME = Journey__c.sObjectType.getDescribe().getName();
    private static final String COMMUNICATION_API_NAME = Communication__c.sObjectType.getDescribe().getName();
    private static final String SURVEY_API_NAME = Survey__c.sObjectType.getDescribe().getName();
    private static final Set<String> OTHER_SUPPORTED_OBJECT = new Set<String>{SURVEY_API_NAME};
    private static final String UNRECOGNIZED_ERROR = System.Label.Compass_Email_Unrecognized_Id_Error;
    private static final String CONTACT_OBJ = 'Contact';
    private static final String CONTACT_ICON = 'standard:contact';
    private static final String EMAIL_TEMPLATE_OBJ = 'EmailTemplate';
    private static final String EMAIL_TEMPLATE_ICON = 'custom:custom23';
    private static final String FREQUENCY_REALTIME = 'Real-time';
    private static final String FREQUENCY_SCHEDULED = 'Scheduled';
    private static final String STATUS_DRAFT = 'Draft';
    private static final String STATUS_OUTBOX = 'Outbox';
    private static final String COMPASS_FOLDER = 'Compass';
    private static final String NO_RELATIONSHIP_ERROR = 'This Communication record doesn\'t have any relationship with either Campaign or Journey or Survey';
    private static Boolean isForSurvey = false;

    public class CommunicationEmailWrapper {
        @AuraEnabled
        public String recordId{get;set;}

        @AuraEnabled
        public Communication__c communication{get;set;}

        @AuraEnabled
        public String emailSchedule{get;set;}

        @AuraEnabled
        public List<String> contactRecipientIds{get;set;}

        @AuraEnabled
        public List<String> contactRecipientsToBeRemoved{get;set;}

        @AuraEnabled
        public Boolean isDraft{get;set;}

        //Updated by XenReyes Oct282022 CCN-814
        @AuraEnabled
        public List<String> attachmentsList {get;set;}
        
        //Updated by CCN-1004 Xen Reyes January 25, 2022
        @AuraEnabled
        public List<String> contactRecipientIdsCC{get;set;}

        @AuraEnabled
        public List<String> contactRecipientIdsBCC{get;set;}

        @AuraEnabled
        public List<String> contactRecipientsToBeRemovedCC{get;set;}

        @AuraEnabled
        public List<String> contactRecipientsToBeRemovedBCC{get;set;}

        //CCN-COM-1214-DV XEN REYES Apr. 14, 2022
        @AuraEnabled
        public String excludedRecipients {get;set;}
    }

    public class RenderedEmailTemplateWrapper {
        @AuraEnabled
        public String subject{get;set;}

        @AuraEnabled
        public String renderedHtml{get;set;}
    }

    @AuraEnabled
    public static Boolean isSurveyRecord(String recordId){
        Id objectid = Id.valueOf(recordId);
        return String.valueOf(objectId.getSobjectType()) == SURVEY_API_NAME;
    }

    @AuraEnabled
    public static User getCurrentUser(){
        return [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
    }
    
    //XenReyes CCN-2251 Nov2022
    @AuraEnabled
    public static string getNamespacePrefix(){
        String prefix = String.isNotBlank(FlsUtils.prefix) ? FlsUtils.prefix : '';
        return prefix;
    }
    
    //Created by XenReyes Nov222021 CCN-814
    @AuraEnabled
    public static String getRecordSobject(Id recordId){
        return String.valueOf(recordId.getSobjectType());
    }

    //Created by XenReyes Nov222021 CCN-814
    @AuraEnabled
    public static List<ContentDocumentLink> getAttachmentRecordsCommunication (Id recordId){
        if(String.valueOf(recordId.getSobjectType()) != COMMUNICATION_API_NAME) return null;
        return [SELECT Id, ContentDocumentId,ContentDocument.Title,ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId =: recordId];
    }

    @AuraEnabled
    public static List<OrgWideEmailAddress> getOrgWideEmailAddresses(){
        try {
            return [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress LIMIT 50000];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static OrgWideEmailAddress getOrgWideEmailAddressById(String OrgWideEmailAddressId){
        return [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Id = :OrgWideEmailAddressId];
    }

    @AuraEnabled
    public static OrgWideEmailAddress getOrgWideEmailAddressByEmail(String OrgWideEmailAddress){
        return [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE Address = :OrgWideEmailAddress];
    }

    @AuraEnabled
    public static void deleteFile (List<String> idList){
        delete [SELECT Id FROM ContentDocument WHERE Id IN: idList]; //Updated by XenReyes Oct282022 CCN-814
    }

    @AuraEnabled
    public static String getDefaultSenderId(){
        try{
            return [SELECT Email_Sender_Id__c FROM Compass_Setting__c LIMIT 1].Email_Sender_Id__c;
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<LookupSearchResult> searchContactRecipient(String searchTerm, List<String> selectedIds){
        final String SEARCH_KEY = '%' + searchTerm + '%';
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        for (Contact con : [SELECT Id, Name, Email FROM Contact
                                WHERE (Name LIKE :SEARCH_KEY OR Email LIKE :SEARCH_KEY)
                                AND Id NOT IN :selectedIds
                                AND Email <> null
                                AND HasOptedOutOfEmail = false
                                LIMIT :MAX_RESULT]) {
            results.add(new LookupSearchResult(con.Id, CONTACT_OBJ, CONTACT_ICON, con.Name, con.Email));
        }
        results.sort();
        return results;
    }

    @AuraEnabled
    public static List<LookupSearchResult> getContactLookupByIds(List<String> initialLookupIds){
        try{
            List<LookupSearchResult> results = new List<LookupSearchResult>();
            System.debug('initialLookupIds: ' + initialLookupIds);
            for (Contact con : [SELECT Id, Name, Email FROM Contact WHERE Id IN :initialLookupIds]) {
                results.add(new LookupSearchResult(con.Id, CONTACT_OBJ, CONTACT_ICON, con.Name, con.Email));
            }
            results.sort();
            return results;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<LookupSearchResult> getTemplateLookupById(List<String> initialLookupIds){
        try{
            List<LookupSearchResult> results = new List<LookupSearchResult>();
            EmailTemplate eTemplate = [SELECT Id, Name, Folder.Name FROM EmailTemplate WHERE Id IN :initialLookupIds LIMIT 1];
            results.add(new LookupSearchResult(eTemplate.Id, EMAIL_TEMPLATE_OBJ, EMAIL_TEMPLATE_ICON, eTemplate.Name, eTemplate.Folder.Name));
            return results;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<LookupSearchResult> searchEmailTemplate(String searchTerm, List<String> selectedIds){
        final String SEARCH_KEY = '%' + searchTerm + '%';
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        try{
            for (EmailTemplate eTemplate : [SELECT Id, Name, Folder.Name FROM EmailTemplate
                                    WHERE (Name LIKE :SEARCH_KEY)
                                    AND Id NOT IN :selectedIds]) {
                results.add(new LookupSearchResult(eTemplate.Id, EMAIL_TEMPLATE_OBJ, EMAIL_TEMPLATE_ICON, eTemplate.Name, eTemplate.Folder.Name));
            }
            results.sort();
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return results;
    }

    @AuraEnabled
    public static RenderedEmailTemplateWrapper getEmailTemplate(String id){
        RenderedEmailTemplateWrapper templateWrapper = new RenderedEmailTemplateWrapper();
        EmailTemplate eTemplate = [SELECT Id, Name, Subject, Body, HtmlValue, EnhancedLetterhead.LetterheadHeader, EnhancedLetterhead.LetterheadFooter 
                                   FROM EmailTemplate 
                                   WHERE Id = :id 
                                   LIMIT 1];

        templateWrapper.subject = eTemplate.Subject;
        if(!String.isBlank(eTemplate.HtmlValue)){
            String htmlString = eTemplate.HtmlValue;
    
            if(!String.isBlank(eTemplate.EnhancedLetterhead.LetterheadHeader)){
                // Append Header
                String bodyStart = '';
                Pattern pBodyStart = Pattern.compile('<body[^>]*>');
                Matcher pMatcher = pBodyStart.matcher(htmlString);
                if(pMatcher.find()){
                    bodyStart = pMatcher.group(0);
                }
                htmlString = htmlString.replace(bodyStart, bodyStart + eTemplate.EnhancedLetterhead.LetterheadHeader);
            }
            if(!String.isBlank(eTemplate.EnhancedLetterhead.LetterheadFooter)){
                // Append Footer
                htmlString = htmlString.replace('</body', eTemplate.EnhancedLetterhead.LetterheadFooter + '</body');
            }
            templateWrapper.renderedHtml = htmlString;
        }
        else{
            String htmlString = eTemplate.Body;
            htmlString = htmlString.replaceAll('\r\n|\n|\r','<br/>');
            templateWrapper.renderedHtml = htmlString;
        }

        return templateWrapper;
    }

    @AuraEnabled
    public static List<sObject> getJourneyParticipants(String recordId, String filter){
        // journey participants and contact recipients should always have a contact related to it
        final Id OBJECT_ID = recordId;

        if(String.valueOf(OBJECT_ID.getSobjectType()) == CAMPAIGN_API_NAME){
            Map<Id, Journey__c> journeyList = new Map<Id, Journey__c>([SELECT Id FROM Journey__c WHERE Campaign__c = :OBJECT_ID]);
            return [SELECT Id, Name, Email FROM Contact WHERE ID IN (SELECT Contact__c FROM Journey_Participant__c 
                                                                        WHERE Journey__c = :journeyList.keySet()
                                                                        AND Contact__c <> NULL)];
        }
        else if(String.valueOf(OBJECT_ID.getSobjectType()) == JOURNEY_API_NAME){
            return [SELECT Id, Name, Email FROM Contact WHERE ID IN (SELECT Contact__c FROM Journey_Participant__c 
                                                                        WHERE Journey__c = :OBJECT_ID
                                                                        AND Contact__c <> NULL)];
        }
        // get all selected recipient/s even without the Journey Participant relationship
        else if(String.valueOf(OBJECT_ID.getSobjectType()) == COMMUNICATION_API_NAME){

            //CCN-1004 Xen Reyes January 25, 2022
            return [SELECT Id, Name, Email FROM Contact WHERE ID IN (SELECT Contact__c FROM Communication_Recipient__c 
                                                                        WHERE CC_Communication__c = :OBJECT_ID
                                                                        AND Contact__c <> NULL
                                                                        AND Send_As__c = 'To')];
        }
        // get contact detail from correct participant object if survey
        else if(String.valueOf(OBJECT_ID.getSobjectType()) == SURVEY_API_NAME){
            Survey__c survey = [SELECT Id, Event__c FROM Survey__c WHERE Id = :OBJECT_ID];

            //get contact details from survey participant if independent survey
            if (survey.Event__c == null){
                if (String.isBlank(filter)){
                    return [SELECT Id, Name, Email FROM Contact WHERE ID IN (SELECT Participant__c FROM Survey_Participant__c WHERE Survey__c = :OBJECT_ID
                                AND Participant__c != null)];
                } else {
                    return [SELECT Id, Name, Email FROM Contact WHERE ID IN (SELECT Participant__c FROM Survey_Participant__c WHERE Survey__c = :OBJECT_ID
                                AND Participant__c != null AND Status__c = :filter)];
                }              
            } else {
                if (String.isBlank(filter)){
                    return [SELECT Id, Name, Email FROM Contact WHERE ID IN (SELECT Member_Contact__c FROM Participant__c WHERE Event__c = :survey.Event__c
                                                                            AND Member_Contact__c != null)];
                } else {
                    return [SELECT Id, Name, Email FROM Contact WHERE ID IN (SELECT Member_Contact__c FROM Participant__c WHERE Event__c = :survey.Event__c
                                                                            AND Member_Contact__c != null AND Survey_Status__c = :filter)];
                }
            }
        } else {
            throw new AuraHandledException(UNRECOGNIZED_ERROR);
        }
    }

    // 5/16/2021 - 01102 - Ability to Save as Draft for Communications
    @AuraEnabled
    public static CommunicationEmailWrapper initializeDraftEmail(String recordId){
        final Id OBJECT_ID = recordId;
        CommunicationEmailWrapper communicationEmail = new CommunicationEmailWrapper();

        if(String.valueOf(OBJECT_ID.getSobjectType()) == COMMUNICATION_API_NAME){
            Communication__c communication = [SELECT Id, Name, Milestone__c, Email_Date__c, Email_Delivery_Date_Time_Schedule__c, 
                                                     Frequency__c, Journey__c, Campaign__c, Survey__c, Organization_Wide_Email_Id__c, 
                                                     Email_Recipient_CC__c, Email_Recipient_BCC__c, Subject__c, Body__c, Email_Template_Link__c,
                                                     OwnerId, Reply_Email_Address__c, Sender_Email_Address__c, Email_Template_Id__c FROM Communication__c
                                                                                                                                    WHERE Id = :OBJECT_ID LIMIT 1];

            //CCN-1004 Xen Reyes January 25, 2022
            List<Id> contactIdList = new List<Id>();
            List<Id> contactIdListCC = new List<Id>();
            List<Id> contactIdListBCC = new List<Id>();

            List<Communication_Recipient__c> commsRecipientList = [SELECT Contact__c, Send_as__c FROM Communication_Recipient__c WHERE CC_Communication__c = :OBJECT_ID];

            for(Communication_Recipient__c commsRecipient : commsRecipientList){
                if(commsRecipient.Send_as__c == 'To') contactIdList.add(commsRecipient.Contact__c);
                if(commsRecipient.Send_as__c == 'CC') contactIdListCC.add(commsRecipient.Contact__c);
                if(commsRecipient.Send_as__c == 'BCC') contactIdListBCC.add(commsRecipient.Contact__c);
            }

            communicationEmail.communication = communication;
            
            communicationEmail.contactRecipientIds = contactIdList;
            communicationEmail.contactRecipientIdsCC = contactIdListCC;
            communicationEmail.contactRecipientIdsBCC = contactIdListBCC;

            return communicationEmail;

        } else if (String.valueOf(OBJECT_ID.getSobjectType()) == SURVEY_API_NAME){
            Survey__c survey = [SELECT Name FROM Survey__c WHERE Id = :OBJECT_ID];
            
            List<EmailTemplate> emailTemp = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName LIKE '%Survey_Participation_Invitation%' LIMIT 1];                       
            Communication__c ccVar = new Communication__c(Name = survey.Name + ' Invitation', Subject__c = survey.Name + ' Invitation');
            if(!emailTemp.isEmpty()){
                ccVar.Email_Template_Id__c = emailTemp[0].Id;
                ccVar.Body__c = emailTemp[0].HtmlValue;
            }
            
            communicationEmail.communication = ccVar;
            communicationEmail.contactRecipientIds = new List<Id>();
            
            //CCN-1004 Xen Reyes January 25, 2022
            communicationEmail.contactRecipientIdsCC = new List<Id>();
            communicationEmail.contactRecipientIdsBCC = new List<Id>();
            
            return communicationEmail;

        }

        return null;
    }

    @AuraEnabled
    public static String sendCompassEmail(String communicationEmailPayload){

        CommunicationEmailWrapper communicationEmail = (CommunicationEmailWrapper) JSON.deserialize(communicationEmailPayload, CommunicationEmailWrapper.class);
        String errors = '';
        final Id OBJECT_ID = communicationEmail.recordId;
        isForSurvey = String.valueOf(OBJECT_ID.getSobjectType()) == SURVEY_API_NAME;

        if(String.valueOf(OBJECT_ID.getSobjectType()) == COMMUNICATION_API_NAME){
            errors += updateDraft(communicationEmail);
            if(communicationEmail.contactRecipientsToBeRemoved != null && !communicationEmail.contactRecipientsToBeRemoved.isEmpty()){
                errors += deleteRecipients(OBJECT_ID, communicationEmail.contactRecipientsToBeRemoved);
            }

            //CCN-1004 Xen Reyes January 25, 2022
            if(communicationEmail.contactRecipientsToBeRemovedCC != null && !communicationEmail.contactRecipientsToBeRemovedCC.isEmpty()){
                errors += deleteRecipients(OBJECT_ID, communicationEmail.contactRecipientsToBeRemovedCC);
            }

            if(communicationEmail.contactRecipientsToBeRemovedBCC != null && !communicationEmail.contactRecipientsToBeRemovedBCC.isEmpty()){
                errors += deleteRecipients(OBJECT_ID, communicationEmail.contactRecipientsToBeRemovedBCC);
            }

            errors += sendDraftEmail(OBJECT_ID, communicationEmail.contactRecipientIds, communicationEmail.communication.Organization_Wide_Email_Id__c);
        }

        else {
            Map<String, Object> response = createCommsRecords(communicationEmail);
            Communication__c communication = (Communication__c) response.get('communication');
            List<Communication_Recipient__c> recipientsList = (List<Communication_Recipient__c>) response.get('recipients');

            if(String.isBlank(String.valueOf(response.get('errors'))) && !communicationEmail.isDraft){
                
                //CCN-1122 Xen Reyes Jan. 15, 2022
                /* errors += executeEmail(communication, recipientsList, communicationEmail.communication.Organization_Wide_Email_Id__c); */
                Database.executeBatch(new CommunicationEmailMessagesBatch(communication, communicationEmail.communication.Organization_Wide_Email_Id__c), Integer.valueOf(System.Label.Communication_Batch_Size));
            }
            else{
                errors += response.get('errors');
            }
        }
        return errors;
    }

    @AuraEnabled
    public static string saveDraft(String communicationEmailPayload){

        CommunicationEmailWrapper communicationEmail = (CommunicationEmailWrapper) JSON.deserialize(communicationEmailPayload, CommunicationEmailWrapper.class);
        String errors = '';
        Id objectId = communicationEmail.recordId;

        if(String.valueOf(objectId.getSobjectType()) == COMMUNICATION_API_NAME){
            errors += updateDraft(communicationEmail);
            if(communicationEmail.contactRecipientsToBeRemoved != null && !communicationEmail.contactRecipientsToBeRemoved.isEmpty()){
                errors += deleteRecipients(communicationEmail.communication.Id, communicationEmail.contactRecipientsToBeRemoved);
            }

            //CCN-1004 Xen Reyes January 25, 2022
            if(communicationEmail.contactRecipientsToBeRemovedCC != null && !communicationEmail.contactRecipientsToBeRemovedCC.isEmpty()){
                errors += deleteRecipients(communicationEmail.communication.Id, communicationEmail.contactRecipientsToBeRemovedCC);
            }

            if(communicationEmail.contactRecipientsToBeRemovedBCC != null && !communicationEmail.contactRecipientsToBeRemovedBCC.isEmpty()){
                errors += deleteRecipients(communicationEmail.communication.Id, communicationEmail.contactRecipientsToBeRemovedBCC);
            }
        }

        else{
            Map<String, Object> response = createCommsRecords(communicationEmail);
            errors += response.get('errors');
        }
        return errors;
    }

    public static Map<String, Object> createCommsRecords(CommunicationEmailWrapper communicationEmail){
        String errors = '';
        Id objectId = communicationEmail.recordId;
        String campaignId = null;
        String journeyId = null;
        String surveyId = null;
        Map<String, Object> response = new Map<String, Object>();

        //CCN-1004 Xen Reyes January 25, 2022
        List<String> collectIds = new List<String>();
        collectIds.addAll(communicationEmail.contactRecipientIds);
        if(communicationEmail.contactRecipientIdsCC != null) collectIds.addAll(communicationEmail.contactRecipientIdsCC);
        if(communicationEmail.contactRecipientIdsBCC != null) collectIds.addAll(communicationEmail.contactRecipientIdsBCC);

        Map<Id, Contact> selectedContactsMap = new Map<Id, Contact>([ SELECT Id, Name, Email from Contact 
                                                                        WHERE Id IN: collectIds]);

        Map<Id, Journey__c> journeyMap = null;
        List<Journey_Participant__c> journeyParticipants = new List<Journey_Participant__c>();
        List<Survey_Participant__c> surveyParticipants = new List<Survey_Participant__c>();
        List<Participant__c> eventSurveyParticipants = new List<Participant__c>();
        final String OBJ_TYPE = String.valueOf(objectId.getSobjectType());

        if(OBJ_TYPE == CAMPAIGN_API_NAME){
            campaignId = communicationEmail.recordId;
            journeyMap = new Map<Id, Journey__c>([ SELECT Id from Journey__c WHERE Campaign__c = :communicationEmail.recordId ]);
            journeyParticipants = [ SELECT id, Contact__c,Contact__r.Email, Is_Active__c FROM Journey_Participant__c 
                                                                                         WHERE Contact__c IN :communicationEmail.contactRecipientIds
                                                                                         AND Journey__c IN :journeyMap.keySet()];
        } else if(OBJ_TYPE == JOURNEY_API_NAME){
            journeyId = communicationEmail.recordId;
            // 6/3/2021 Lynne's request: Associate a Campaign related from the Journey to the communication record
            // for the milestone creation
            Journey__c journey = [SELECT Id, Campaign__c FROM Journey__c WHERE Id = :journeyId];
            campaignId = journey.Campaign__c;
            journeyParticipants = [ SELECT Id, Contact__c, Contact__r.Email, Is_Active__c FROM Journey_Participant__c 
                                                                                          WHERE Contact__c IN :communicationEmail.contactRecipientIds
                                                                                          AND Journey__c = :communicationEmail.recordId];
        } else if (OBJ_TYPE == SURVEY_API_NAME){
            surveyId = communicationEmail.recordId;
            Survey__c survey = [SELECT Id, Event__c FROM Survey__c WHERE Id = :surveyId];

            if (survey.Event__c == null){
                surveyParticipants = [ SELECT Id, Participant__c, Participant__r.Email 
                                        FROM Survey_Participant__c 
                                        WHERE Participant__c IN :communicationEmail.contactRecipientIds
                                        AND Survey__c = :surveyId];
            } else {
                eventSurveyParticipants = [SELECT Id, Member_Contact__c, Member_Contact__r.Email 
                                            FROM Participant__c 
                                            WHERE Member_Contact__c IN :communicationEmail.contactRecipientIds
                                            AND Event__c = :survey.Event__c];
            }
            
        } else {
            throw new AuraHandledException(UNRECOGNIZED_ERROR);
        }

        Map<Id, Journey_Participant__c> contactParticipantMap = new Map<Id, Journey_Participant__c>();
        for(Journey_Participant__c participant : journeyParticipants){
            if(contactParticipantMap.get(participant.Contact__c) == null){
                contactParticipantMap.put(participant.Contact__c, participant);
            }
        }

        Map<Id, Survey_Participant__c> surveyParticipantMap = new Map<Id, Survey_Participant__c>();
        for(Survey_Participant__c participant : surveyParticipants){
            if(!surveyParticipantMap.containsKey(participant.Participant__c)){
                surveyParticipantMap.put(participant.Participant__c, participant);
            }
        }

        Map<Id, Participant__c> eventSurveyParticipantMap = new Map<Id, Participant__c>();
        for(Participant__c participant : eventSurveyParticipants){
            if(!eventSurveyParticipantMap.containsKey(participant.Member_Contact__c)){
                eventSurveyParticipantMap.put(participant.Member_Contact__c, participant);
            }
        }
        
        Communication__c communication = (Communication__c) communicationEmail.communication;
        Boolean isScheduled = communication.Email_Delivery_Date_Time_Schedule__c != null;

        communication.Campaign__c = campaignId;
        communication.Journey__c = journeyId;
        communication.Survey__c = surveyId;
        communication.Frequency__c = isScheduled ? FREQUENCY_SCHEDULED : FREQUENCY_REALTIME;
        communication.Active__c = true;
        // communication.Status__c = isScheduled && !communicationEmail.isDraft ? STATUS_OUTBOX : STATUS_DRAFT;

        //CCN-COM-1214-DV XEN REYES Apr. 14, 2022
        communication.Excluded_Recipients__c = communicationEmail.excludedRecipients;

        try {
            insert communication;
            
            //Updated by XenReyes Oct282022 CCN-814
            List<ContentDocumentLink> oldcdList = new List<ContentDocumentLink>();
            if(communicationEmail.attachmentsList != null) {
                oldcdList = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: communicationEmail.attachmentsList AND LinkedEntityId IN (:campaignId, :journeyId, :surveyId)];
            }

            List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
            if(!oldcdList.isEmpty() && oldcdList != null){
                for(ContentDocumentLink cdVar : oldcdList){
                    cdList.add(new ContentDocumentLink(ContentDocumentId = cdVar.ContentDocumentId, LinkedEntityId = communication.Id, ShareType = 'V'));
                }
            }

            insert cdList;
            delete oldcdList;

        } catch(DmlException e){
            errors += e.getMessage();
            System.debug('CompassEmailController.createCommsRecords - ERROR! >>> ' + errors);
        }

        //CCN-1004 Xen Reyes January 25, 2022
        List<Communication_Recipient__c> recipientsList = createRecipients(communicationEmail, communication.Id, selectedContactsMap, 
                                                                            contactParticipantMap, surveyParticipantMap, 
                                                                            eventSurveyParticipantMap);
        try{
            insert recipientsList;
        }catch(DmlException e){
            errors += e.getMessage();
            System.debug('CompassEmailController.createCommsRecords - ERROR! >>> ' + errors);
        }
        response.put('communication', communication);
        response.put('recipients', recipientsList);
        response.put('errors', errors);

        return response;
    }

    //makes sure that the date and time being compared to check is the date time in user timezone, not the client browser date time
    @AuraEnabled
    public static String checkEmailScheduleDateTime(String communicationSchedule){
        String errorMessage = '';
        DateTime commDateSched = DateTime.valueOfGmt(communicationSchedule); 
        
        if (commDateSched.date() < System.today()){
            errorMessage += 'Date to send the email should not be less than today';
        } else if (commDateSched.date() == System.today() && commDateSched.time() < System.now().time()){
            errorMessage += 'Time to send the email should not be less than the time now';
        }
        
        return errorMessage;
    }

    private static List<Communication_Recipient__c> createRecipients(CommunicationEmailWrapper coms,
                                                                     Id communicationId,
                                                                     Map<Id, Contact> selectedContactsMap,
                                                                     Map<Id, Journey_Participant__c> contactParticipantMap,
                                                                     Map<Id, Survey_Participant__c> surveyParticipantMap,
                                                                     Map<Id, Participant__c> eventSurveyParticipantMap){
        
        List<Communication_Recipient__c> commsRecipientsToInsert = new List<Communication_Recipient__c>();
        for(Contact con : selectedContactsMap.values()){

            //CCN-1004 Xen Reyes January 25, 2022
            String sendAs = 'To';
            if(coms.contactRecipientIdsCC != null && coms.contactRecipientIdsCC.contains(con.Id)) sendAs = 'CC';
            if(coms.contactRecipientIdsBCC != null && coms.contactRecipientIdsBCC.contains(con.Id)) sendAs = 'BCC';

            Communication_Recipient__c newRecipient = new Communication_Recipient__c(CC_Communication__c = communicationId,
                                                                                     Contact__c = con.Id,
                                                                                     Email__c = con.Email,
                                                                                     Send_as__c = sendAs);
            
            if(sendAs == 'To'){
                // if there's an existing Journey Participant related to the contact, associate it with the Comms Recipient
                if(contactParticipantMap.containsKey(con.Id)){
                    newRecipient.Journey_Participant__c = contactParticipantMap.get(con.Id).Id;
                }

                if(surveyParticipantMap.containsKey(con.Id)){
                    newRecipient.Survey_Participant__c = surveyParticipantMap.get(con.Id).Id;
                }

                if(eventSurveyParticipantMap.containsKey(con.Id)){
                    newRecipient.Event_Participant__c = eventSurveyParticipantMap.get(con.Id).Id;
                }
            }

            commsRecipientsToInsert.add(newRecipient);
        }
        return commsRecipientsToInsert;
    }

    private static String deleteRecipients(String communicationId, List<String> contactRecipientsToBeRemoved){
        String errors = '';
        System.debug('communicationId ' + communicationId);
        System.debug('contactRecipientsToBeRemoved ' + contactRecipientsToBeRemoved);
        if(communicationId != null && contactRecipientsToBeRemoved != null && !contactRecipientsToBeRemoved.isEmpty()){
            List<Communication_Recipient__c> commsRecipients = [SELECT Id, Contact__c FROM Communication_Recipient__c
                                                                                      WHERE Contact__c IN :contactRecipientsToBeRemoved
                                                                                      AND CC_Communication__c = :communicationId];
            try{
                if(!commsRecipients.isEmpty()){
                    delete commsRecipients;
                }
            }
            catch(DmlException e){
                errors += e.getMessage();
                System.debug(errors);
            }
        }
        return errors;
    }

    public static String executeEmail(Communication__c communication, List<Communication_Recipient__c> recipientsList, String orgWideEmailId, Integer counter){
        String errors = '';
        try{
            List<Map<String, Object>> responseList = EmailUtility.buildCommunicationEmailList(communication, recipientsList, orgWideEmailId);
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
            for(Map<String, Object> response : responseList){
                if(response.get('hasError') == true){
                    List<String> errorList = (List<String>) response.get('messages');
                    for(String error : errorList){
                        System.debug(error);
                        errors += error + '\n';
                    }
                } else {
                    // If there's no error then send
                    Messaging.SingleEmailMessage email = (Messaging.SingleEmailMessage) response.get('emailMessage');
                    emailMessages.add(email);
                }
            }
            if(!emailMessages.isEmpty()){
                if (communication.Frequency__c == FREQUENCY_REALTIME) {
                    errors += EmailUtility.sendCommunicationEmailMessages((isForSurvey ? communication : null), emailMessages, recipientsList, counter);
                } else {
                    EmailSenderSchedulable emailScheduledSender = new EmailSenderSchedulable(JSON.serialize(communication), 
                                                                                            JSON.serialize(recipientsList),
                                                                                            orgWideEmailId,
                                                                                            isForSurvey,
                                                                                            counter);

                    final String SCHEDULE_NAME = 'Communication Id: ' + communication.Id + ' Chunk ' + counter;
                    System.schedule(SCHEDULE_NAME, createCRONString(communication.Email_Delivery_Date_Time_Schedule__c), emailScheduledSender);

                    errors += 'EmailScheduled';
                }
            }
            else{
                errors += 'No email was sent';
            }
        }
        catch(exception e){
            System.debug('CompassEmailController.executeEmail - ERROR! >>> ' + e.getMessage());
            System.debug('CompassEmailController.executeEmail - ERROR Stack Trace! >>> ' + e.getStackTraceString());
            System.debug('CompassEmailController.executeEmail - ERROR Line Number! >>> ' + e.getLineNumber());
            errors += e.getMessage();
        }
        return errors;
    }

    private static String createCRONString(DateTime emailSchedule){
        final String CRON_FORMAT = '{0} {1} {2} {3} {4} {5} {6}';
        List<String> cronComponents = new List<String>();
        cronComponents.add('0'); //seconds
        cronComponents.add(String.valueOf(emailSchedule.minute()));
        cronComponents.add(String.valueOf(emailSchedule.hour()));
        cronComponents.add(String.valueOf(emailSchedule.day()));
        cronComponents.add(String.valueOf(emailSchedule.month()));
        cronComponents.add('?'); //day of the week
        cronComponents.add(String.valueOf(emailSchedule.year()));

        return String.format(CRON_FORMAT, cronComponents);
    }

    // send draft added 5/15/2021
    public static string sendDraftEmail(Id communicationId, List<String> contactRecipientIds, String orgWideEmailId){
        String errors = '';
        try {
            Communication__c communication = [SELECT Frequency__c, Journey__c, Survey__c, Campaign__c, Organization_Wide_Email_Id__c, 
                                                        Email_Recipient_CC__c, Email_Recipient_BCC__c, Subject__c, Body__c,
                                                        OwnerId, Reply_Email_Address__c, Email_Template_Id__c, Email_Template_Link__c,
                                                        Email_Delivery_Date_Time_Schedule__c FROM Communication__c
                                                                                             WHERE Id = :communicationId LIMIT 1];
            //CCN-1004 Xen Reyes January 25, 2022
            /* List<Communication_Recipient__c> recipientsList = [SELECT CC_Communication__c, Contact__c, Email__c, Survey_Participant__c FROM Communication_Recipient__c
                                                                                                                    WHERE CC_Communication__c = :communicationId
                                                                                                                    AND Contact__c IN :contactRecipientIds]; */
            
            if(communication != null){
                isForSurvey = communication.Survey__c!=null;

                //CCN-1122 Xen Reyes Jan. 15, 2022
                //errors = executeEmail(communication, recipientsList, orgWideEmailId);
                Database.executeBatch(new CommunicationEmailMessagesBatch(communication, orgWideEmailId), Integer.valueOf(System.Label.Communication_Batch_Size));
            }
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return errors;
    }

    public static string updateDraft(CommunicationEmailWrapper communicationEmail){
        String errors = '';
        Id objectId = communicationEmail.recordId;
        List<Communication_Recipient__c> commsRecipientsToAdd = new List<Communication_Recipient__c>();
        Communication__c communication = (Communication__c) communicationEmail.communication;

        if(communication.Email_Delivery_Date_Time_Schedule__c == null){
            communication.Frequency__c = FREQUENCY_REALTIME;
        }
        else{
            communication.Frequency__c = FREQUENCY_SCHEDULED;
        }

        //CCN-COM-1214-DV XEN REYES Apr. 14, 2022
        communication.Excluded_Recipients__c = communicationEmail.excludedRecipients;
        
        //CCN-1004 Xen Reyes January 25, 2022
        Map<Id, Contact> contactMap  = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Id IN :communicationEmail.contactRecipientIds]);
        Map<Id, Communication_Recipient__c> contactRecipientMap = new Map<Id, Communication_Recipient__c>();
        for(Communication_Recipient__c commsRecipient : [SELECT Id, Contact__c, Contact__r.Email FROM Communication_Recipient__c WHERE CC_Communication__c = :objectId]){
            if(contactRecipientMap.get(commsRecipient.Contact__c) == null){
                contactRecipientMap.put(commsRecipient.Contact__c, commsRecipient);
            }
        }

        if(communicationEmail.contactRecipientIds != null){
            List<Journey_Participant__c> journeyParticipants = new List<Journey_Participant__c>();
            List<Survey_Participant__c> surveyParticipants = new List<Survey_Participant__c>();
            List<Participant__c> eventParticipants = new List<Participant__c>();
            Map<Id, Journey__c> journeyMap;
            // if related only to a Campaign
            if(communication.Campaign__c != null && communication.Journey__c == null){
                journeyMap = new Map<Id, Journey__c>([ SELECT Id from Journey__c WHERE Campaign__c = :communication.Campaign__c ]);
                journeyParticipants = [ SELECT id, Contact__c,Contact__r.Email, Is_Active__c FROM Journey_Participant__c 
                                                                                                WHERE Contact__c IN :communicationEmail.contactRecipientIds
                                                                                                AND Journey__c IN :journeyMap.keySet()];
            }
            // if related to a Journey
            else if(communication.Journey__c != null){
                journeyParticipants = [ SELECT id, Contact__c,Contact__r.Email, Is_Active__c FROM Journey_Participant__c 
                                                                                                WHERE Contact__c IN :communicationEmail.contactRecipientIds
                                                                                                AND Journey__c = :communication.Journey__c];
            }
            else if (communication.Survey__c != null){
                Survey__c survey = [SELECT Id, Event__c FROM Survey__c WHERE Id = :communication.Survey__c];

                if (survey.Event__c == null){
                    surveyParticipants = [SELECT Id, Participant__c, Participant__r.Email FROM Survey_Participant__c 
                                            WHERE Participant__c IN :communicationEmail.contactRecipientIds
                                            AND Survey__c = :survey.Id];
                } else {
                    eventParticipants = [SELECT Id, Member_Contact__c, Member_Contact__r.Email FROM Participant__c 
                                            WHERE Member_Contact__c IN :communicationEmail.contactRecipientIds
                                            AND Event__c = :survey.Event__c];
                }
            }
            else {
                // No relationship with any object, error should be thrown.
                errors += NO_RELATIONSHIP_ERROR;
            }

            Map<Id, Journey_Participant__c> contactParticipantMap = new Map<Id, Journey_Participant__c>();
            for(Journey_Participant__c participant : journeyParticipants){
                if(contactParticipantMap.get(participant.Contact__c) == null){
                    contactParticipantMap.put(participant.Contact__c, participant);
                }
            }
            Map<Id, Survey_Participant__c> surveyParticipantMap = new Map<Id, Survey_Participant__c>();
            for(Survey_Participant__c participant : surveyParticipants){
                if(!surveyParticipantMap.containsKey(participant.Participant__c)){
                    surveyParticipantMap.put(participant.Participant__c, participant);
                }
            }
            Map<Id, Participant__c> eventParticipantMap = new Map<Id, Participant__c>();
            for(Participant__c participant : eventParticipants){
                if(!eventParticipantMap.containsKey(participant.Member_Contact__c)){
                    eventParticipantMap.put(participant.Member_Contact__c, participant);
                }
            }

            for(Id contactId : communicationEmail.contactRecipientIds){
                if(contactRecipientMap.get(contactId) == null){
                    Communication_Recipient__c newRecipient = new Communication_Recipient__c();
                    newRecipient.Contact__c = contactId;
                    newRecipient.CC_Communication__c = objectId;
                    newRecipient.Email__c = contactMap.get(contactId).Email;
                    if(contactParticipantMap.get(contactId) != null){
                        newRecipient.Journey_Participant__c = contactParticipantMap.get(contactId).Id;
                    }
                    if(surveyParticipantMap.get(contactId) != null){
                        newRecipient.Survey_Participant__c = surveyParticipantMap.get(contactId).Id;
                    }
                    if(eventParticipantMap.get(contactId) != null){
                        newRecipient.Event_Participant__c = eventParticipantMap.get(contactId).Id;
                    }

                    //CCN-1004 Xen Reyes January 25, 2022
                    newRecipient.Send_as__c = 'To';
        
                    commsRecipientsToAdd.add(newRecipient);
                }
            }
        }

        //CCN-1004 Xen Reyes January 25, 2022
        if(communicationEmail.contactRecipientIdsCC != null){
            Map<Id, Contact> contactMapCC = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Id IN :communicationEmail.contactRecipientIdsCC]);
            for(Id contactId : communicationEmail.contactRecipientIdsCC){
                if(contactRecipientMap.get(contactId) == null){
                    Communication_Recipient__c newRecipient = new Communication_Recipient__c();
                    newRecipient.Contact__c = contactId;
                    newRecipient.CC_Communication__c = objectId;
                    newRecipient.Email__c = contactMapCC.get(contactId).Email;
                    newRecipient.Send_as__c = 'CC';
                    commsRecipientsToAdd.add(newRecipient);
                }
            }
        }

        if(communicationEmail.contactRecipientIdsBCC != null){
            Map<Id, Contact> contactMapBCC = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Id IN :communicationEmail.contactRecipientIdsBCC]);
            for(Id contactId : communicationEmail.contactRecipientIdsBCC){
                if(contactRecipientMap.get(contactId) == null){
                    Communication_Recipient__c newRecipient = new Communication_Recipient__c();
                    newRecipient.Contact__c = contactId;
                    newRecipient.CC_Communication__c = objectId;
                    newRecipient.Email__c = contactMapBCC.get(contactId).Email;
                    newRecipient.Send_as__c = 'BCC';
                    commsRecipientsToAdd.add(newRecipient);
                }
            }
        }

        try{
            if(communication != null){
                update communication;
            }

            if(!commsRecipientsToAdd.isEmpty()){
                insert commsRecipientsToAdd;
            }
        }
        catch(DmlException e){
            errors += e.getMessage();
            System.debug(errors);
        }
        return errors;
    }
}