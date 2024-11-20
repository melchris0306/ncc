/*******************************************************************************************
* @name: CommunicationEmailMessagesBatch_Test
* @author: Xen Reyes
* @created: 15-01-2022
* @description: [CCN1122] Test class for CommunicationEmailMessagesBatch
*
* Changes (version)
* -------------------------------------------------------------------------------------------
*        No.   Date(dd-mm-yyy) Author         Description
*        ----  ---------    --------------------  -----------------------------
* @version   1.0   15-01-2022    Xen Reyes          Initial version.
*********************************************************************************************/

@IsTest
private class CommunicationEmailMessagesBatch_Test {

    @testSetup
    static void setup() {
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

    @IsTest
    static void testBehavior() {
        Communication__c communication = [SELECT Id, Organization_Wide_Email_Id__c FROM Communication__c LIMIT 1];
        String orgWideEmailId = communication.Organization_Wide_Email_Id__c;
        Database.executeBatch(new CommunicationEmailMessagesBatch(communication, orgWideEmailId), Integer.valueOf(System.Label.Communication_Batch_Size));
    }
}