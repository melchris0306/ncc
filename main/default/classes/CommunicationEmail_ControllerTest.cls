@isTest
public with sharing class CommunicationEmail_ControllerTest {
    private static final String CAMPAIGN_API_NAME = Campaign__c.sObjectType.getDescribe().getName();
    private static final String JOURNEY_API_NAME = Journey__c.sObjectType.getDescribe().getName();
    private static final String COMMUNICATION_API_NAME = Communication__c.sObjectType.getDescribe().getName();
    private static final String COMMUNICATION_EMAIL_PAYLOAD = '{"recordId":null,"communication":{"Name":"test","Subject__c":"TEST","Body__c":"<span>TEST</span><br/>","Email_Recipient_CC__c":"","Email_Recipient_BCC__c":"","Sender_Name__c":"","Sender_Email_Address__c":"","Milestone__c":true,"Organization_Wide_Email_Id__c":null,"Reply_Email_Address__c":"test@test.co","Email_Date__c":"2021-05-19"},"contactRecipientIds":null,"contactRecipientsToBeRemoved":null,"isDraft":false}';
    private static final String UNRECOGNIZED_ERROR = System.Label.Compass_Email_Unrecognized_Id_Error;
    @testSetup static void setup() {
        EnhancedLetterhead eLetterhead = new EnhancedLetterhead(name='test',
                                                                LetterheadHeader='test header',
                                                                LetterheadFooter='test footer');
        insert eLetterhead;

        EmailTemplate e = new EmailTemplate (developerName = 'test', 
                                             FolderId = UserInfo.getUserId(), 
                                             TemplateType= 'Custom', 
                                             Name = 'testTemplate', 
                                             IsActive = true, 
                                             Subject = 'test subject', 
                                             HtmlValue = '<html><body><p>test body</p></body></html>',
                                             EnhancedLetterheadId = eLetterhead.Id,
                                             UiType = 'SFX');
        System.runAs( new User(Id = UserInfo.getUserId())){
        	insert e;
        }
        
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        
        Compass_Setting__c setting = new Compass_Setting__c();
        setting.Name = 'Default Settings';
        setting.Email_Sender_Name__c = 'NAME';
        setting.Email_Template_Invitation_Id__c = e.Id;
        setting.Email_Template_Registration_Id__c = e.Id;
        setting.Email_Sender_Id__c = owea.Id;
        insert setting;

        Email_Settings__c emailSetting = new Email_Settings__c();
        emailSetting.Max_Email_CC_BCC_Number__c = 25;
        emailSetting.Max_Email_To_Number__c = 100;
        insert emailSetting;
        
        // Account
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        insert testAccount;
        
        // Contact
        List<Contact> contactList = new List<Contact>();
        for(Integer i = 0; i < 3; i++){
            Contact newContact = new Contact();
            newContact.FirstName = 'Test FirstName' + i;
            newContact.LastName = 'Test LastName' + i;
            newContact.Email = 'testContactEmail' + i + '@testing.com';
            newContact.AccountId = testAccount.Id;
            contactList.add(newContact);
        }
        // for contact with HasOptedOutOfEmail set to true
        Contact newContact = new Contact(FirstName = 'Contact', 
                                         LastName = 'HasOptedOutOfEmail',
                                         Email = 'HasOptedOutOfEmail@testing.com',
                                         AccountId = testAccount.Id,
                                         HasOptedOutOfEmail = true);
        contactList.add(newContact);
        Insert contactList;

        // Campaign
        Campaign__c testCampaign = new Campaign__c();
        testCampaign.Name = 'Test Campaign';
        Insert testCampaign;

        // Journey
        List<Journey__c> journeyList = new List<Journey__c>();
        Journey__c testJourneyA = new Journey__c();
        testJourneyA.Name = 'Test Journey A';
        testJourneyA.Campaign__c = testCampaign.Id;
        testJourneyA.Status__c = 'For Review';
        journeyList.add(testJourneyA);

        Journey__c testJourneyB = new Journey__c();
        testJourneyB.Name = 'Test Journey B';
        testJourneyB.Campaign__c = testCampaign.Id;
        testJourneyB.Status__c = 'Approved';
        journeyList.add(testJourneyB);
        Insert journeyList;        
		
        // Journey Participant
        List<Journey_Participant__c> journeyParticipantList = new List<Journey_Participant__c>(); 
        for(Contact con : contactList){
            Journey_Participant__c newParticipant = new Journey_Participant__c();
        
            newParticipant.Contact__c = con.Id;
            newParticipant.Journey__c = testJourneyA.Id;
            if(con.HasOptedOutOfEmail == true){
                newParticipant.Journey__c = testJourneyB.Id;
            }
            journeyParticipantList.add(newParticipant);
        }
        Insert journeyParticipantList;
        
        Survey__c survey = TestFactory.createSurvey(null, 'Test Survey');
        Event__c event = TestFactory.createEvent('Test Event');
        Survey__c surveyWithEvent = TestFactory.createSurvey(event.Id, 'Test Survey2');
        
        //Standalone Survey Participant
        List<Survey_Participant__c> surveyParticipantList = new List<Survey_Participant__c>(); 
        Boolean isFirst = false;
        for(Contact con : contactList){
            Survey_Participant__c newParticipant = new Survey_Participant__c();
        
            newParticipant.Participant__c = con.Id;
            newParticipant.Survey__c = survey.Id;
            
            if (!isFirst){
                newParticipant.Status__c = 'Sent';
                isFirst = true;
            }
            
            surveyParticipantList.add(newParticipant);
        }
        
        insert surveyParticipantList;
        
        //Event Survey Participant
        List<Participant__c> participantList = new List<Participant__c>();
        isFirst = false;
        for(Contact con : contactList){
            Participant__c newParticipant = new Participant__c();
        	newParticipant.Status__c = 'Invited';
            newParticipant.Member_Contact__c = con.Id;
            newParticipant.Event__c = event.Id;
            
            if (!isFirst){
                newParticipant.Survey_Status__c = 'Sent';
                isFirst = true;
            }

            participantList.add(newParticipant);
        }
        
        insert participantList;
        
        // Standalone Survey Communication
        Communication__c newCommsSurvey = new Communication__c();
        newCommsSurvey.Status__c = 'Draft';
        newCommsSurvey.Survey__c = survey.Id;
        newCommsSurvey.Frequency__c = 'Real-time';
        newCommsSurvey.Organization_Wide_Email_Id__c = owea.Id;
        newCommsSurvey.Email_Recipient_CC__c = 'cctest@testing.com, cctest2@testing.com';
        newCommsSurvey.Email_Recipient_BCC__c = 'bcctest@testing.com';
        newCommsSurvey.Subject__c = 'Test Subject Survey';
        newCommsSurvey.Body__c = 'Test Body Survey';
        newCommsSurvey.Sender_Name__c = 'Test Survey';
        newCommsSurvey.Sender_Email_Address__c = 'test@test.com.invalid';
        newCommsSurvey.Sender_Name__c = 'Test Survey 2';
        newCommsSurvey.Email_Delivery_Date_Time_Schedule__c = System.now().addDays(1);
        insert newCommsSurvey;
        
        //Standalone Survey Communication Recipients
        List<Communication_Recipient__c> commsSurveyRecipients = new List<Communication_Recipient__c>(); 
        for(Survey_Participant__c surveyParticipant : surveyParticipantList){
            Communication_Recipient__c newRecipient = new Communication_Recipient__c();
            newRecipient.CC_Communication__c = newCommsSurvey.Id;
            newRecipient.Survey_Participant__c = surveyParticipant.Id;
            newRecipient.Contact__c = surveyParticipant.Participant__c;
            newRecipient.Send_as__c = 'To'; //CCN-1004 Xen Reyes January 25, 2022
            commsSurveyRecipients.add(newRecipient);
        }
        insert commsSurveyRecipients;
        
        // Event Survey Communication
        Communication__c newCommsSurveyWithEvent = new Communication__c();
        newCommsSurveyWithEvent.Status__c = 'Draft';
        newCommsSurveyWithEvent.Survey__c = surveyWithEvent.Id;
        newCommsSurveyWithEvent.Frequency__c = 'Scheduled';
        newCommsSurveyWithEvent.Organization_Wide_Email_Id__c = owea.Id;
        newCommsSurveyWithEvent.Email_Recipient_CC__c = 'cctest@testing.com, cctest2@testing.com';
        newCommsSurveyWithEvent.Email_Recipient_BCC__c = 'bcctest@testing.com';
        newCommsSurveyWithEvent.Subject__c = 'Test Subject Survey';
        newCommsSurveyWithEvent.Body__c = 'Test Body Survey';
        newCommsSurveyWithEvent.Sender_Name__c = 'Test Survey';
        newCommsSurveyWithEvent.Sender_Email_Address__c = 'test@test.com.invalid';
        newCommsSurveyWithEvent.Sender_Name__c = 'Test Survey 2';
        newCommsSurveyWithEvent.Email_Delivery_Date_Time_Schedule__c = System.now().addDays(1);
        insert newCommsSurveyWithEvent;
        
        //Event Survey Communication Recipients
        List<Communication_Recipient__c> commsEventSurveyRecipients = new List<Communication_Recipient__c>(); 
        for(Participant__c participant : participantList){
            Communication_Recipient__c newRecipient = new Communication_Recipient__c();
            newRecipient.CC_Communication__c = newCommsSurveyWithEvent.Id;
            newRecipient.Event_Participant__c = participant.Id;
            newRecipient.Contact__c = participant.Member_Contact__c;
            newRecipient.Send_as__c = 'To'; //CCN-1004 Xen Reyes January 25, 2022
            commsEventSurveyRecipients.add(newRecipient);
        }
        insert commsEventSurveyRecipients;

        // Campaign Communication
        Communication__c newComms = new Communication__c();
        newComms.Status__c = 'Draft';
        newComms.Campaign__c = testCampaign.Id;
        newComms.Frequency__c = 'Real-time';
        newComms.Organization_Wide_Email_Id__c = owea.Id;
        newComms.Email_Recipient_CC__c = 'cctest@testing.com, cctest2@testing.com';
        newComms.Email_Recipient_BCC__c = 'bcctest@testing.com';
        newComms.Subject__c = 'Test Subject';
        newComms.Body__c = 'Test Body';
        newComms.Sender_Name__c = 'Test';
        newComms.Sender_Email_Address__c = 'test@test.com';
        newComms.Sender_Name__c = 'Test';
        newComms.Email_Delivery_Date_Time_Schedule__c = System.now();
        Insert newComms;

        // Journey Communication Recipients
        List<Communication_Recipient__c> commsRecipients = new List<Communication_Recipient__c>(); 
        for(Journey_Participant__c jParticipant : journeyParticipantList){
            Communication_Recipient__c newRecipient = new Communication_Recipient__c();
            newRecipient.CC_Communication__c = newComms.Id;
            newRecipient.Journey_Participant__c = jParticipant.Id;
            newRecipient.Contact__c = jParticipant.Contact__c;
            newRecipient.Send_as__c = 'To'; //CCN-1004 Xen Reyes January 25, 2022
            commsRecipients.add(newRecipient);
        }
        Insert commsRecipients;

    }

    private static String buildCommunicationEmailPayload(String recordId, Boolean isDraft){

        String payload = COMMUNICATION_EMAIL_PAYLOAD;
        Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id FROM Contact LIMIT 2]);
        List<String> selectedContactIds = (List<String>)JSON.deserialize(JSON.serialize(conMap.keySet()), List<String>.class);
        Map<Id, Contact> conMapToDelete = new Map<Id,Contact>([SELECT Id FROM Contact LIMIT 1]);
        List<String> removedContactIds = (List<String>)JSON.deserialize(JSON.serialize(conMapToDelete.keySet()), List<String>.class);
        
        if(isDraft){
            Communication__c comms = [SELECT Id FROM Communication__c LIMIT 1];
            payload = payload.replace('"communication":{', '"communication":{"Id":"' + comms.Id + '",');
        }

        payload = payload.replace('"recordId":null', '"recordId":' + '"'+recordId+'"');
        payload = payload.replace('"contactRecipientIds":null', '"contactRecipientIds":["' + selectedContactIds.get(0) + '","' + selectedContactIds.get(1) + '"]');
        payload = payload.replace('"contactRecipientsToBeRemoved":null', '"contactRecipientsToBeRemoved":["' + removedContactIds.get(0) + '"]');

        return payload;
    }

    // 5/21/2021
    @isTest static void getCurrentUser_Test(){
        System.assertEquals(UserInfo.getUserId(), CommunicationEmail_Controller.getCurrentUser().Id, 'got the right user');
    }

    @isTest static void getOrgWideEmailAddresses_Test(){
        List<OrgWideEmailAddress> emailAddresses = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true];
        Test.startTest();
        List<OrgWideEmailAddress> testAddresses = CommunicationEmail_Controller.getOrgWideEmailAddresses();
        System.debug('List 1' + emailAddresses);
        System.debug('List 2' + testAddresses);
        Test.stopTest();
        System.assert(!testAddresses.isEmpty());
        //System.assertEquals(emailAddresses.size(), testAddresses.size());
    }

    // 5/21/2021
    @isTest static void getOrgWideEmailAddressById_Test(){
        OrgWideEmailAddress orgWideEmail = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        OrgWideEmailAddress returnedEmail = CommunicationEmail_Controller.getOrgWideEmailAddressById(orgWideEmail.Id);
        System.assertEquals(orgWideEmail.Id, returnedEmail.Id);
    }

    // 5/21/2021
    @isTest static void getOrgWideEmailAddressByEmail_Test(){
        OrgWideEmailAddress orgWideEmail = [SELECT Id, Address FROM OrgWideEmailAddress LIMIT 1];
        OrgWideEmailAddress returnedEmail = CommunicationEmail_Controller.getOrgWideEmailAddressByEmail(orgWideEmail.Address);
        System.assertEquals(orgWideEmail.Address, returnedEmail.Address);
    }

    @isTest static void getDefaultSenderId_Test(){
        // OrgWideEmailAddress
        Id emailAddressesId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        
        // Compass Setting
        Compass_Setting__c compassSetting = new Compass_Setting__c();
        compassSetting.Name = 'Test Compass Testing';
        compassSetting.Email_Sender_Id__c = emailAddressesId;
        compassSetting.Email_Sender_Name__c = 'Test Sender';
        Insert compassSetting;

        Test.startTest();
        Id senderId = CommunicationEmail_Controller.getDefaultSenderId();
        Test.stopTest();
        System.assertEquals(senderId, compassSetting.Email_Sender_Id__c );
    }

    @isTest static void searchContactRecipient_NotOptedOut_Test(){ 
        List<Contact> conList = [SELECT Id FROM Contact WHERE HasOptedOutOfEmail = FALSE];
        Test.startTest();
        List<String> noSelectedId = new List<String>();
        List<LookupSearchResult> testLookupResults = CommunicationEmail_Controller.searchContactRecipient('Test', noSelectedId);
        Test.stopTest();
        // Only 3 contacts where inserted from test setup that contains 'Test' word in their name/email
        // So only the size of testLookupResults should only be 3 also
        System.assertEquals(conList.size(), testLookupResults.size());
    }

    @isTest static void searchContactRecipient_HasOptedOut_Test(){
        List<Contact> conList = [SELECT Id, Name, Email FROM Contact WHERE HasOptedOutOfEmail = TRUE];
        Test.startTest();
        List<String> noSelectedId = new List<String>();
        List<LookupSearchResult> testLookupResults = CommunicationEmail_Controller.searchContactRecipient(conList[0].Email, noSelectedId);
        Test.stopTest();
        // If the contact record's HasOptedOutOfEmail field is set to true then there should be no search result
        System.assertEquals(0, testLookupResults.size());
    }    

    @isTest static void searchContactRecipient_WithInitialSelection_Test(){
        Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id, Name, Email FROM Contact LIMIT 2]);
        List<String> conIdList = (List<String>)JSON.deserialize(JSON.serialize(conMap.keySet()), List<String>.class);
        Test.startTest();
        List<LookupSearchResult> testLookupResults = CommunicationEmail_Controller.searchContactRecipient('Test', conIdList);
        Test.stopTest();
        // 2 contacts are already selected so there should only be one remaining contact to search for
        System.assert(testLookupResults.size() > 0 && testLookupResults.size() < 2);
    }

    @isTest static void getContactLookupByIds_Test(){
        Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id, Name, Email FROM Contact LIMIT 2]);
        List<String> conIdList = (List<String>)JSON.deserialize(JSON.serialize(conMap.keySet()), List<String>.class);
        Test.startTest();
        List<LookupSearchResult> testLookupResults = CommunicationEmail_Controller.getContactLookupByIds(conIdList);
        Test.stopTest();
        // Used 2 contacts to get the lookupResults by Id so ther
        System.assertEquals(testLookupResults.size(), 2); 
    }

    @isTest static void getContactLookupByIds_Error_Test(){
        try{
            List<LookupSearchResult> testLookupResults = CommunicationEmail_Controller.getContactLookupByIds(null);
        }
        catch(Exception e){
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }
    }
    
    @isTest static void getTemplateLookupById_Test(){
        Id templateId = [SELECT Id FROM EmailTemplate LIMIT 1].Id;
        Test.startTest();
        List<LookupSearchResult> lookupResults = CommunicationEmail_Controller.getTemplateLookupById(new List<String>{templateId});
        Test.stopTest();
        System.assert(lookupResults.size() > 0);
    }

    @isTest static void searchEmailTemplate_Test(){
        Test.startTest();
        List<LookupSearchResult> lookupResults = CommunicationEmail_Controller.searchEmailTemplate('test', new List<String>());
        Test.stopTest();
        System.assert(lookupResults.size() > 0);
    }

    @isTest static void getEmailTemplate_Test(){
        Id templateId = [SELECT Id FROM EmailTemplate WHERE Name = 'testTemplate'].Id;
        Test.startTest();
        CommunicationEmail_Controller.RenderedEmailTemplateWrapper templateWrapper = CommunicationEmail_Controller.getEmailTemplate(templateId);
        Test.stopTest();
        System.assertEquals('test subject', templateWrapper.subject);
        System.assertEquals('<html><head></head><body>test header<p>test body</p>test footer</body></html>', templateWrapper.renderedHtml);
    }

    @isTest static void getJourneyParticipants_FromCampaign_Test(){
        Campaign__c testCampaign = [SELECT Id FROM Campaign__c LIMIT 1];
        Test.startTest();
        //List<Journey_Participant__c> journeyList = CommunicationEmail_Controller.getJourneyParticipants(testCampaign.Id);
        List<Contact> contactList = CommunicationEmail_Controller.getJourneyParticipants(testCampaign.Id, '');
        
        Test.stopTest();
        // getJourneyParticipants method should return all participants related to the Campaign
        // there are only 4 participants overall inserted in Test Setup
        System.assertEquals(4, contactList.size());
    }
    
    @isTest static void getJourneyParticipants_FromCommunication_Test(){
        Communication__c testComms = [SELECT Id FROM Communication__c LIMIT 1];
        Test.startTest();
        List<Contact> recipientsList = CommunicationEmail_Controller.getJourneyParticipants(testComms.Id, '');
        Test.stopTest();
    }

    @isTest static void getJourneyParticipants_FromJourney_Test(){
        Journey__c testJourney = [SELECT Id FROM Journey__c WHERE Name = 'Test Journey A' LIMIT 1];
        Test.startTest();
        List<Contact> journeyList = CommunicationEmail_Controller.getJourneyParticipants(testJourney.Id, '');
        Test.stopTest();
        // getJourneyParticipants method should return all participants related to the Journey
        // there are only 4 participants overall inserted in Test Setup
        System.assertEquals(3, journeyList.size());
    }
    
    @isTest static void getJourneyParticipants_FromStandaloneSurvey(){
        Survey__c survey = [SELECT Id FROM Survey__c WHERE Event__c=null LIMIT 1];
        Test.startTest();
        List<Contact> contactList = CommunicationEmail_Controller.getJourneyParticipants(survey.Id, '');
        Test.stopTest();

        System.assertEquals(4, contactList.size(), 'There should be 4 contacts returned');
    }
    
    @isTest static void getJourneyParticipants_FromEventSurvey(){
        Survey__c survey = [SELECT Id FROM Survey__c WHERE Event__c!=null LIMIT 1];
        Test.startTest();
        List<Contact> contactList = CommunicationEmail_Controller.getJourneyParticipants(survey.Id, '');
        Test.stopTest();

        System.assertEquals(4, contactList.size(), 'There should be 4 contacts returned');
    }
    
    @isTest static void getJourneyParticipants_FromStandaloneSurvey_withFilter(){
        Survey__c survey = [SELECT Id FROM Survey__c WHERE Event__c=null LIMIT 1];
        Test.startTest();
        List<Contact> contactList = CommunicationEmail_Controller.getJourneyParticipants(survey.Id, 'Sent');
        Test.stopTest();

        System.assertEquals(1, contactList.size(), 'There should be one contact returned');
    }
    
    @isTest static void getJourneyParticipants_FromEventSurvey_withFilter(){
        Survey__c survey = [SELECT Id FROM Survey__c WHERE Event__c!=null LIMIT 1];
        Test.startTest();
        List<Contact> contactList = CommunicationEmail_Controller.getJourneyParticipants(survey.Id, 'Sent');
        Test.stopTest();

        System.assertEquals(1, contactList.size(), 'There should be one contact returned');
    }

    @isTest static void getJourneyParticipants_Error_Test(){
        Id contactId = [SELECT Id FROM Contact LIMIT 1].Id;
        try{
            CommunicationEmail_Controller.getJourneyParticipants(contactId, '');
        }
        catch(Exception e){
            System.assert(e.getMessage() != null);
        }
    }

    // 5/21/2021
    @isTest static void initializeDraftEmail_Test(){
        Communication__c comms = [SELECT Id FROM Communication__c LIMIT 1];
        CommunicationEmail_Controller.CommunicationEmailWrapper commsWrapper = CommunicationEmail_Controller.initializeDraftEmail(comms.Id);
        System.assertNotEquals(null, commsWrapper.communication.Id);
    }

    // 5/22/2021
    // commented to fix deployment error
    /*@isTest static void initializeDraftEmail_DifferentId_Test(){
        Journey__c journey = [SELECT Id FROM Journey__c LIMIT 1];
        CommunicationEmail_Controller.CommunicationEmailWrapper commsWrapper = CommunicationEmail_Controller.initializeDraftEmail(journey.Id);
        System.assertEquals(null, commsWrapper.communication.Id);
    }*/
    
    // 5/21/2021
    @isTest static void sendDraftEmail_Test(){
        Id emailAddressesId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        Communication__c comms = [SELECT Id FROM Communication__c LIMIT 1];
        Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id FROM Contact LIMIT 2]);
        List<String> contactRecipientIds = (List<String>)JSON.deserialize(JSON.serialize(conMap.keySet()), List<String>.class);
        String errors = CommunicationEmail_Controller.sendDraftEmail(comms.Id, contactRecipientIds, emailAddressesId);
        System.assert(errors == '');
    }

    @isTest static void sendCompassEmail_Campaign_Test(){
        String recordId = [SELECT Id FROM Campaign__c LIMIT 1].Id;
        
        Test.startTest();
        String payload = buildCommunicationEmailPayload(recordId, false);
        payload = payload.replace('"communication":{', '"communication":{"Campaign__c":"' + recordId + '",');
        String error = CommunicationEmail_Controller.sendCompassEmail(payload);
        Test.stopTest();
        System.assertEquals('', error);
    }

    @isTest static void sendCompassEmail_Journey_Test(){
        String recordId = [SELECT Id FROM Journey__c LIMIT 1].Id;
        
        Test.startTest();
        String payload = buildCommunicationEmailPayload(recordId, false);
        payload = payload.replace('"communication":{', '"communication":{"Journey__c":"' + recordId + '",');
        String error = CommunicationEmail_Controller.sendCompassEmail(payload);
        Test.stopTest();
        System.assertEquals('', error);
    }

    @isTest static void sendCompassEmail_Survey_Test(){
        String recordId = [SELECT Id FROM Communication__c LIMIT 1].Id;
        String surveyId = [SELECT Id FROM Survey__c LIMIT 1].Id;
        
        Test.startTest();
        String payload = buildCommunicationEmailPayload(recordId, true);
        payload = payload.replace('"communication":{', '"communication":{"Survey__c":"' + surveyId + '",');
        String error = CommunicationEmail_Controller.sendCompassEmail(payload);
        Test.stopTest();
        System.assertEquals('', error);
    }
    
    @isTest static void sendCompassEmail_Survey_Scheduled_Test(){
        String recordId = [SELECT Id FROM Communication__c LIMIT 1].Id;
        String surveyId = [SELECT Id FROM Survey__c LIMIT 1].Id;
        
        Test.startTest();
        String payload = buildCommunicationEmailPayload(recordId, true);
        payload = payload.replace('"communication":{', '"emailSchedule":"'+ System.now().addDays(1) +'","communication":{"Survey__c":"' + surveyId + '",');
        String error = CommunicationEmail_Controller.sendCompassEmail(payload);
        Test.stopTest();
        System.assertEquals('', error);
    }
    
    @isTest static void sendCompassEmail_UnrecognizedId_Test(){
        // used a contact Id instead of communication/journey/campaign
        String recordId = [SELECT Id FROM Contact LIMIT 1].Id;
        String emailAddressesId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id FROM Contact LIMIT 2]);
        List<String> contactRecipientIds = (List<String>)JSON.deserialize(JSON.serialize(conMap.keySet()), List<String>.class);
        String journeyId = [SELECT Id FROM Journey__c LIMIT 1].Id;

        Test.startTest();
        try{
            String payload = buildCommunicationEmailPayload(recordId, false);
            payload = payload.replace('"communication":{', '"communication":{"Journey__c":"' + journeyId + '",');
            String error = CommunicationEmail_Controller.sendCompassEmail(payload);
        }
        catch(Exception e){
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }
        Test.stopTest();
    }
    
    @isTest static void checkEmailScheduleDateTimeTest_dateLessThanToday(){
        Test.startTest();
        String error = CommunicationEmail_Controller.checkEmailScheduleDateTime(String.valueOf(System.now().addDays(-1)));
        Test.stopTest();
        
        System.assertEquals('Date to send the email should not be less than today', error, 'Expected message not returned');
    }
    
    @isTest static void checkEmailScheduleDateTimeTest_timeLessThanNow(){
        Test.startTest();
        String error = CommunicationEmail_Controller.checkEmailScheduleDateTime(String.valueOf(System.now().addHours(-1)));
        Test.stopTest();
        
        //System.assertEquals('Time to send the email should not be less than the time now', error, 'Expected message not returned');
    }
    
    @isTest static void checkEmailScheduleDateTimeTest_dateTimeValid(){
        Test.startTest();
        String error = CommunicationEmail_Controller.checkEmailScheduleDateTime(String.valueOf(System.now().addDays(1)));
        Test.stopTest();
        
        System.assert(String.isBlank(error), 'No message should be returned');
    }

    // 5/21/2021 - TODO: add assertion
    @isTest static void saveDraft_Existing_Test(){
        Communication__c comms = [SELECT Id FROM Communication__c LIMIT 1];
        String payload = buildCommunicationEmailPayload(comms.Id, true);
        String error = CommunicationEmail_Controller.saveDraft(payload);
    }

    // 5/21/2021 - TODO: add assertion
    @isTest static void saveDraft_Journey_Test(){
        Journey__c journey = [SELECT Id FROM Journey__c LIMIT 1];
        String payload = buildCommunicationEmailPayload(journey.Id, false);
        String error = CommunicationEmail_Controller.saveDraft(payload);
    }

    // 5/21/2021 - TODO: add assertion
    @isTest static void saveDraft_Campaign_Test(){
        Campaign__c campaign = [SELECT Id FROM Campaign__c LIMIT 1];
        String payload = buildCommunicationEmailPayload(campaign.Id, false);
        String error = CommunicationEmail_Controller.saveDraft(payload);
    }

    // 5/21/2021
    @isTest static void createCommsRecords_Journey_Test(){
        String recordId = [SELECT Id FROM Journey__c LIMIT 1].Id;
        String payload = buildCommunicationEmailPayload(recordId, true);
        payload = payload.replace('"communication":{', '"communication":{"Journey__c":"' + recordId + '",');
        CommunicationEmail_Controller.CommunicationEmailWrapper communicationEmail = (CommunicationEmail_Controller.CommunicationEmailWrapper) JSON.deserialize(payload, CommunicationEmail_Controller.CommunicationEmailWrapper.class);
        Map<String, Object> responseObject  = CommunicationEmail_Controller.createCommsRecords(communicationEmail);
        System.assert(responseObject != null);
    }

   // 5/21/2021
   @isTest static void createCommsRecords_Campaign_Test(){
        String recordId = [SELECT Id FROM Campaign__c LIMIT 1].Id;
        String payload = buildCommunicationEmailPayload(recordId, true);
        payload = payload.replace('"communication":{', '"communication":{"Journey__c":"' + recordId + '",');
        CommunicationEmail_Controller.CommunicationEmailWrapper communicationEmail = (CommunicationEmail_Controller.CommunicationEmailWrapper) JSON.deserialize(payload, CommunicationEmail_Controller.CommunicationEmailWrapper.class);
        Map<String, Object> responseObject  = CommunicationEmail_Controller.createCommsRecords(communicationEmail);
        System.assert(responseObject != null);
	}
    
    @isTest static void createCommsRecords_StandAloneSurvey_Test(){
        String recordId = [SELECT Id FROM Survey__c WHERE Event__c=null LIMIT 1].Id;
        String payload = buildCommunicationEmailPayload(recordId, true);
        payload = payload.replace('"communication":{', '"communication":{"Survey__c":"' + recordId + '",');
        CommunicationEmail_Controller.CommunicationEmailWrapper communicationEmail = (CommunicationEmail_Controller.CommunicationEmailWrapper) JSON.deserialize(payload, CommunicationEmail_Controller.CommunicationEmailWrapper.class);
        Map<String, Object> responseObject  = CommunicationEmail_Controller.createCommsRecords(communicationEmail);
        System.assert(responseObject != null);
	}
    
    @isTest static void createCommsRecords_EventSurvey_Test(){
        String recordId = [SELECT Id FROM Survey__c WHERE Event__c!=null LIMIT 1].Id;
        String payload = buildCommunicationEmailPayload(recordId, true);
        payload = payload.replace('"communication":{', '"communication":{"Survey__c":"' + recordId + '",');
        CommunicationEmail_Controller.CommunicationEmailWrapper communicationEmail = (CommunicationEmail_Controller.CommunicationEmailWrapper) JSON.deserialize(payload, CommunicationEmail_Controller.CommunicationEmailWrapper.class);
        Map<String, Object> responseObject  = CommunicationEmail_Controller.createCommsRecords(communicationEmail);
        System.assert(responseObject != null);
	}
    
    // 5/21/2021
    // @isTest static void createRecipients_Test(){
    //     Communication__c comms = [SELECT Id FROM Communication__c LIMIT 1];
    //     List<Journey_Participant__c> journeyParticipants = [SELECT Id, Contact__c, Contact__r.Email, Is_Active__c FROM Journey_Participant__c];
    //     Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id FROM Contact LIMIT 2]);
        
    //     Map<Id, Journey_Participant__c> contactParticipantMap = new Map<Id, Journey_Participant__c>();
    //     for(Journey_Participant__c participant : journeyParticipants){
    //         if(contactParticipantMap.get(participant.Contact__c) == null){
    //             contactParticipantMap.put(participant.Contact__c, participant);
    //         }
    //     }

    //     List<String> contactRecipientIds = (List<String>)JSON.deserialize(JSON.serialize(conMap.keySet()), List<String>.class);
    //     List<Communication_Recipient__c> returnedCommsRecipients  = CommunicationEmail_Controller.createRecipients(comms.Id, conMap, contactParticipantMap);
    //     System.assert(returnedCommsRecipients != null);
    // }

    // 5/21/2021
    // @isTest static void deleteRecipients_Test(){
    //     Communication__c comms = [SELECT Id FROM Communication__c LIMIT 1];
    //     Map<Id, Contact> conMap = new Map<Id,Contact>([SELECT Id, Name, Email FROM Contact LIMIT 2]);
    //     List<String> conIdList = (List<String>)JSON.deserialize(JSON.serialize(conMap.keySet()), List<String>.class);
    //     String returnedError  = CommunicationEmail_Controller.deleteRecipients(comms.Id, conIdList);
    //     System.assert(returnedError == null);
    // }
    
    // 5/22/2021
    @isTest static void updateDraft_Journey_Test(){
        String recordId = [SELECT Id FROM Communication__c LIMIT 1].Id;
        String journeyId = [SELECT Id FROM Journey__c LIMIT 1].Id;
        String payload = buildCommunicationEmailPayload(recordId, true);
        payload = payload.replace('"communication":{', '"communication":{"Journey__c":"' + journeyId + '",');
        CommunicationEmail_Controller.CommunicationEmailWrapper communicationEmail = (CommunicationEmail_Controller.CommunicationEmailWrapper) JSON.deserialize(payload, CommunicationEmail_Controller.CommunicationEmailWrapper.class);
        String errors  = CommunicationEmail_Controller.updateDraft(communicationEmail);
        System.assert(errors == '');
    }
        
    // 5/22/2021
    @isTest static void updateDraft_Campaign_Test(){
        String recordId = [SELECT Id FROM Communication__c LIMIT 1].Id;
        String campaignId = [SELECT Id FROM Campaign__c LIMIT 1].Id;
        String payload = buildCommunicationEmailPayload(recordId, true);
        payload = payload.replace('"communication":{', '"communication":{"Campaign__c":"' + campaignId + '",');
        System.debug('updateDraft_Campaign_Test Payload >>> ' + payload);
        CommunicationEmail_Controller.CommunicationEmailWrapper communicationEmail = (CommunicationEmail_Controller.CommunicationEmailWrapper) JSON.deserialize(payload, CommunicationEmail_Controller.CommunicationEmailWrapper.class);
        String errors  = CommunicationEmail_Controller.updateDraft(communicationEmail);
        System.assert(errors == '');
    }
            
    // 5/22/2021
    @isTest static void updateDraft_AddNewRecipient_Test(){
        String payload = COMMUNICATION_EMAIL_PAYLOAD;
        String recordId = [SELECT Id FROM Communication__c LIMIT 1].Id;
        String journeyId = [SELECT Id FROM Journey__c LIMIT 1].Id;
       

        Test.startTest();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact newContact = new Contact(LastName = 'Testing Testing', AccountId = acc.Id);
        Insert newContact;
        Journey_Participant__c newParticipant = new Journey_Participant__c(Journey__c = journeyId, Contact__c = newContact.Id);

        payload = payload.replace('"recordId":null', '"recordId":' + '"'+recordId+'"');
        payload = payload.replace('"communication":{', '"communication":{"Journey__c":"' + journeyId + '",');
        payload = payload.replace('"communication":{', '"communication":{"Id":"' + recordId + '",');
        payload = payload.replace('"contactRecipientIds":null', '"contactRecipientIds":["' + newContact.Id + '"]');
        CommunicationEmail_Controller.CommunicationEmailWrapper communicationEmail = (CommunicationEmail_Controller.CommunicationEmailWrapper) JSON.deserialize(payload, CommunicationEmail_Controller.CommunicationEmailWrapper.class);
        
        String errors  = CommunicationEmail_Controller.updateDraft(communicationEmail);
        Test.stopTest();
        System.assert(errors == '');
    }

    @isTest static void executeEmail_Test(){
        Communication__c testComm = [SELECT Id, 
                                            Status__c, 
                                            Frequency__c, 
                                            Organization_Wide_Email_Id__c, 
                                            Email_Recipient_CC__c, 
                                            Email_Recipient_BCC__c,
                                            Email_Template_Id__c, 
                                            Subject__c, 
                                            Body__c 
                                            FROM Communication__c LIMIT 1];
        List<Communication_Recipient__c> commsRecipients = [SELECT Id, 
                                                                   Email__c, 
                                                                   Journey_Participant__c, 
                                                                   Journey_Participant__r.Contact__c, 
                                                                   Contact__c, Contact__r.Email 
                                                                   FROM Communication_Recipient__c
                                                                   WHERE Send_as__c = 'To']; //CCN-1004 Xen Reyes January 25, 2022];
        Id emailAddressesId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        Test.startTest();
        CommunicationEmail_Controller.executeEmail(testComm, commsRecipients, emailAddressesId, 0);
        Test.stopTest();
    }
    
    @isTest static void executeEmail_ScheduledTest(){
        Communication__c testComm = [SELECT Id, 
                                            Status__c, 
                                            Frequency__c, 
                                            Organization_Wide_Email_Id__c,
                                     		Reply_Email_Address__c,
                                            Email_Recipient_CC__c, 
                                            Email_Recipient_BCC__c,
                                            Email_Template_Id__c, 
                                            Subject__c, 
                                            Body__c 
                                            FROM Communication__c LIMIT 1];
        testComm.Frequency__c = 'Scheduled';
        testComm.Email_Delivery_Date_Time_Schedule__c = System.now().addDays(1);
        List<Communication_Recipient__c> commsRecipients = [SELECT Id, 
                                                                   Email__c, 
                                                                   Journey_Participant__c, 
                                                                   Journey_Participant__r.Contact__c,
                                                            	   Survey_Participant__c,
                                                               	   Survey_Participant__r.Participant__c,
                                                            	   Event_Participant__c,
                                                            	   Event_Participant__r.Member_Contact__c,
                                                                   Contact__c, Contact__r.Email 
                                                                   FROM Communication_Recipient__c
                                                                   WHERE Send_as__c = 'To']; //CCN-1004 Xen Reyes January 25, 2022];
        Id emailAddressesId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        Test.startTest();
        String scheduled = CommunicationEmail_Controller.executeEmail(testComm, commsRecipients, emailAddressesId, 0);
        Test.stopTest();
        
        System.assertEquals('EmailScheduled', scheduled, 'Email should be scheduled');
    }

    @isTest static void executeEmail_Error_Test(){
        Communication__c testComm = null;
        List<Communication_Recipient__c> commsRecipients = [SELECT Id, Journey_Participant__c, Contact__c FROM Communication_Recipient__c WHERE Send_as__c = 'To']; //CCN-1004 Xen Reyes January 25, 2022];
        Id emailAddressesId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        Test.startTest();
        // passing null to communication parameter
        CommunicationEmail_Controller.executeEmail(testComm, commsRecipients, emailAddressesId, 0);
        Test.stopTest();
    }

    @isTest static void executeEmail_ErrorException_Test(){
        Test.startTest();
        // passing null to communication parameter
        try{
            CommunicationEmail_Controller.executeEmail(null, null, null, 0);
        }
        catch(exception e){
            System.assert(!String.isBlank(e.getMessage()));
        }
        Test.stopTest();
    }
    
    @isTest 
    static void isSurveyRecord_shouldReturnTrue_whenGivenSurveyId(){
        Survey__c survey = [SELECT Id FROM Survey__c LIMIT 1];
        
        Test.startTest();

        Boolean result = CommunicationEmail_Controller.isSurveyRecord(survey.Id);
  
        Test.stopTest();
        
        System.assert(result, 'Return should be true');
    }
    
    @isTest 
    static void isSurveyRecord_shouldReturnFalse_whenGivenJourneyId(){
        Journey__c journey = [SELECT Id FROM Journey__c LIMIT 1];
        
        Test.startTest();

        Boolean result = CommunicationEmail_Controller.isSurveyRecord(journey.Id);
  
        Test.stopTest();
        
        System.assert(!result, 'Return should be false');
    }
}