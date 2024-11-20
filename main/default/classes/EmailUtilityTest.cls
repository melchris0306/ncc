@isTest
private class EmailUtilityTest{
    @testSetup
    static void setup(){
        String alias = 'tstSysAd';
        Profile profile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User sysad = new User(
            Username=alias+'@test.com', Alias=alias, CommunityNickname=alias, TimeZoneSidKey='America/Chicago', 
            LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1', LanguageLocaleKey='en_US',
            FirstName=alias, LastName=alias, Email=alias+'@test.com', ProfileId=profile.Id, Department = 'Test');
        insert sysad;
        
        //create email template
        EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = 'unique_name_test_emailtemplate';
        validEmailTemplate.DeveloperName = 'unique_name_test_emailtemplate';
        validEmailTemplate.TemplateType = 'text';
        validEmailTemplate.FolderId = UserInfo.getUserId();
        validEmailTemplate.Subject = 'Test Template Subject';
        insert validEmailTemplate;
        
        System.runAs(sysad) {
            // OrgWideEmailAddress
            Id emailAddressesId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;

            //create Account
            Account testAccount = new Account(Name='EmailUtilityTestAccount');
            insert testAccount;
            
            //create Contact
            List<Contact> contactList = new List<Contact>();
            for(Integer i=0;i<10;i++){
                contactList.add(new Contact(FirstName='EmailUtility', LastName='TestContact'+i, AccountId=testAccount.Id, Email='test_'+i+'@testEmailUtility.test'));
            }
            insert contactList;
            
            //create Journey__c
            Journey__c testJourney = new Journey__c(Name='EmailUtilityTestJourney');
            insert testJourney;
            
            //create Journey_Participant__c
            List<Journey_Participant__c> jpList = new List<Journey_Participant__c>();
            for(Contact cnt:contactList){
                jpList.add(new Journey_Participant__c(Journey__c=testJourney.Id, Contact__c=cnt.Id));
            }
            insert jpList;
            
            //create CommunicScheduliation__c record;
            Communication__c testRecord = new Communication__c();
            testRecord.Status__c = 'Draft';
            testRecord.Frequency__c = 'Real-time';
            testRecord.Active__c = true;
            testRecord.Subject__c = 'Test Comm Subject';
            testRecord.Body__c = 'Test Comm HTML Body';
            testRecord.Email_Recipient_CC__c = 'testCC1@testEmailUtility.test, testCC2@testEmailUtility.test, testCC3@testEmailUtility.test, testCC4@testEmailUtility.test';
            testRecord.Email_Recipient_BCC__c = 'testBCC1@testEmailUtility.test, testBCC2@testEmailUtility.test, testBCC3@testEmailUtility.test, testBCC4@testEmailUtility.test';
            testRecord.OwnerId = UserInfo.getUserId();
            insert testRecord;
            
            //create Communication_Recipient__c
            List<Communication_Recipient__c> crList = new List<Communication_Recipient__c>();
            for(Journey_Participant__c jp:jpList){
                crList.add(new Communication_Recipient__c(CC_Communication__c=testRecord.Id, Journey_Participant__c=jp.Id, Contact__c=jp.Contact__c));
            }
            insert crList;
            
            // EventTrigger Switch Custom Settings
            Insert new Apex_Trigger_Switch__c(Name='EventTrigger' ,Active__c=true);
            
            Compass_Setting__c comp = TestDataFactory.createCSData(1);
            insert comp;
            //create Event
            Event__c evt = TestFactory.createEvent('Test');
            evt.Email_Sender_Id__c = emailAddressesId;
            Update evt;

            //with start and end
            List<Session__c> sessionList = new List<Session__c>();
            Session__c newCampaign = new Session__c();
            newCampaign.Name = 'Test1';
            newCampaign.Event__c = evt.Id;
            newCampaign.IsActive__c = true ;
            newCampaign.Start_Date_Time__c = date.today();
            newCampaign.End_Date_Time__c = date.today().addDays(5);
            newCampaign.Description__c = 'TEST DESCRIPTION 1';
            newCampaign.Subtitle__c = 'TEST SUBTITLE 1';
            newCampaign.Meeting_URL__c = 'https://teams.microsoft.com/l/meetup-join/samplemeetin1';
            newCampaign.Time_Zone__c = 'PST';
            sessionList.add(newCampaign);
            
            //with Start
            Session__c newCampaign2 = new Session__c();
            newCampaign2.Name = 'Test2';
            newCampaign2.Event__c = evt.Id;
            newCampaign2.IsActive__c = true ;
            newCampaign2.Start_Date_Time__c = date.today();
            newCampaign2.End_Date_Time__c = date.today().addDays(5);
            newCampaign2.Description__c = 'TEST DESCRIPTION 2';
            newCampaign2.Subtitle__c = 'TEST SUBTITLE 2';
            newCampaign2.Meeting_URL__c = 'https://teams.microsoft.com/l/meetup-join/samplemeetin2';
            newCampaign2.Time_Zone__c = 'PST';
            sessionList.add(newCampaign2);
            
            //with End
            Session__c newCampaign3 = new Session__c();
            newCampaign3.Name = 'Test3';
            newCampaign3.Event__c = evt.Id;
            newCampaign3.IsActive__c = true ;
            newCampaign3.Start_Date_Time__c = date.today();
            newCampaign3.End_Date_Time__c = date.today().addDays(5);
            sessionList.add(newCampaign3);
            
            //without Start and End
            Session__c newCampaign4 = new Session__c();
            newCampaign4.Name = 'Test4';
            newCampaign4.Event__c = evt.Id;
            newCampaign4.Start_Date_Time__c = date.today();
            newCampaign4.End_Date_Time__c = date.today().addDays(5);
            newCampaign4.IsActive__c = true ;
            sessionList.add(newCampaign4);
            
            //with same start and end
            Session__c newCampaign5 = new Session__c();
            newCampaign5.Name = 'Test5';
            newCampaign5.Event__c = evt.Id;
            newCampaign5.IsActive__c = true ;
            newCampaign5.Start_Date_Time__c = date.today();
            newCampaign5.End_Date_Time__c = date.today().addDays(5);
            sessionList.add(newCampaign5);
            insert sessionList;
            
            // Compass setting for Participant
            Compass_Setting__c compassSetting = new Compass_Setting__c();
            compassSetting.Name = 'Default Settings';
            compassSetting.Email_Sender_Id__c = emailAddressesId;
            compassSetting.Email_Sender_Name__c = 'Test Sender';
            compassSetting.Email_Template_Invitation_Id__c = validEmailTemplate.Id;
            compassSetting.Email_Template_Registration_Id__c = validEmailTemplate.Id;
            Insert compassSetting;
            
            Participant__c cm = TestFactory.createParticipant(evt.Id, contactList[0]);
            cm.Status__c = 'Invited';
            update cm;
            
            Session_Participant__c sesPart = new Session_Participant__c(
                Event__c = evt.Id,
                Session__c = sessionList[0].Id,
                Contact__c = contactList[0].Id,
                Participant__c = cm.Id
            );
            insert sesPart;
        }
    }
    
    static void populateActiveSettings(){
        Email_Settings__c emailSettings = new Email_Settings__c();
        emailSettings.Default_Org_Wide_Email_Id__c = 'nicole@ulapp.co';
        emailSettings.Email_BCC_Limit_Error_Message__c = 'Maximum Email BCC Address Count Reached: 25.';
        emailSettings.Email_CC_Limit_Error_Message__c = 'Maximum Email CC Address Count Reached: 25.';
        emailSettings.Email_Disabled_Error_Message__c = 'Email Sending is disabled in settings.';
        emailSettings.Email_Sent_Daily_Limit_Error_Message__c = 'Maximum Daily Email Sent Reached: 5000.';
        emailSettings.Email_To_Limit_Error_Message__c = 'Maximum Email To Address Count Reached: 100.';
        emailSettings.Email_Transaction_Limit_Error_Message__c = 'Maximum Transaction Email Sent Reached: 10.';
        emailSettings.isActive__c = true;
        emailSettings.Max_Email_CC_BCC_Number__c = 5;
        emailSettings.Max_Email_To_Number__c = 11;
        insert emailSettings;
    }
    
    static void populateInactiveSettings(){
        Email_Settings__c emailSettings = new Email_Settings__c();
        emailSettings.Default_Org_Wide_Email_Id__c = 'nicole@ulapp.co';
        emailSettings.Email_BCC_Limit_Error_Message__c = 'Maximum Email BCC Address Count Reached: 25.';
        emailSettings.Email_CC_Limit_Error_Message__c = 'Maximum Email CC Address Count Reached: 25.';
        emailSettings.Email_Disabled_Error_Message__c = 'Email Sending is disabled in settings.';
        emailSettings.Email_Sent_Daily_Limit_Error_Message__c = 'Maximum Daily Email Sent Reached: 5000.';
        emailSettings.Email_To_Limit_Error_Message__c = 'Maximum Email To Address Count Reached: 100.';
        emailSettings.Email_Transaction_Limit_Error_Message__c = 'Maximum Transaction Email Sent Reached: 10.';
        emailSettings.isActive__c = false;
        emailSettings.Max_Email_CC_BCC_Number__c = 3;
        emailSettings.Max_Email_To_Number__c = 5;
        insert emailSettings;
    }
    
    static void populateLowLimitSettings(){
        Email_Settings__c emailSettings = new Email_Settings__c();
        emailSettings.Default_Org_Wide_Email_Id__c = 'nicole@ulapp.co';
        emailSettings.Email_BCC_Limit_Error_Message__c = 'Maximum Email BCC Address Count Reached: 25.';
        emailSettings.Email_CC_Limit_Error_Message__c = 'Maximum Email CC Address Count Reached: 25.';
        emailSettings.Email_Disabled_Error_Message__c = 'Email Sending is disabled in settings.';
        emailSettings.Email_Sent_Daily_Limit_Error_Message__c = 'Maximum Daily Email Sent Reached: 5000.';
        emailSettings.Email_To_Limit_Error_Message__c = 'Maximum Email To Address Count Reached: 100.';
        emailSettings.Email_Transaction_Limit_Error_Message__c = 'Maximum Transaction Email Sent Reached: 10.';
        emailSettings.isActive__c = true;
        emailSettings.Max_Email_CC_BCC_Number__c = 3;
        emailSettings.Max_Email_To_Number__c = 5;
        insert emailSettings;
    }
    
    //happy path test for EmailUtility.buildEmailMessage()
    static testmethod void test_buildEmailMessage_positive() {
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        
        test.startTest();
        Communication__c whatObj = [SELECT Id, OwnerId, Email_Template_Id__c FROM Communication__c];
        EmailTemplate template = [SELECT id FROM EmailTemplate WHERE DeveloperName = 'unique_name_test_emailtemplate'];
        whatObj.Email_Template_Id__c = template.Id;
         
        emailMessage = EmailUtility.buildEmailMessage((SObject)whatObj, 
                                        whatObj.OwnerId, 
                                        (String)template.Id, 
                                        'TEST CUSTOM SUBJECT',
                                        'TEST CUSTOM HTML BODY',
                                        new List<String>{'testTo@testEmailUtility.test'},
                                        new List<String>{'testCC@testEmailUtility.test'},
                                        new List<String>{'testBCC@testEmailUtility.test'});
        System.debug('[test_buildEmailMessage_positive]emailMessage-->'+emailMessage);
        test.stopTest();
        System.assertEquals(whatObj.OwnerId, emailMessage.getTargetObjectId());
        System.assertEquals('TEST CUSTOM SUBJECT', emailMessage.getSubject());
    }
    
    //happy path test for EmailUtility.buildCommunicationEmailMessage()
    static testMethod void test_buildCommunicationEmailMessage_positive(){
        
        //setup settings
        populateActiveSettings();
        
        //retrieve sample template
        EmailTemplate emailTemplate = Database.query(EmailUtility.getCreatableFieldsSOQL('EmailTemplate','DeveloperName =\'Event_Invitation_Template\''));//[SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName ='Event_Invitation_Template'];
        
        //retrieve Communication__c record
        List<Communication__c> comms = Database.query(EmailUtility.getCreatableFieldsSOQL('Communication__c',''));//[SELECT Id, OwnerId, Email_Template_Id__c, Subject__c, Body__c, Email_Recipient_CC__c, Email_Recipient_BCC__c FROM Communication__c];
        
        //retrieve Communication_Recipient__c
        Map<Id, List<Communication_Recipient__c>> recipientPerCommsMap = new Map<Id, List<Communication_Recipient__c>>();
        for(Communication_Recipient__c recipient: [SELECT Id, 
                                                        Journey_Participant__c, 
                                                        Journey_Participant__r.Contact__c, 
                                                        Journey_Participant__r.Contact__r.Email,
                                                   		Survey_Participant__c,
                                                   		Survey_Participant__r.Participant__c,
                                                   		Survey_Participant__r.Participant__r.Email,
                                                   		Event_Participant__c,
                                                   		Event_Participant__r.Member_Contact__c,
                                                   		Event_Participant__r.Member_Contact__r.Email,
                                                        CC_Communication__c
                                                    FROM Communication_Recipient__c
                                                   WHERE CC_Communication__c IN: comms
                                                  ])
        {
            List<Communication_Recipient__c> recipients = new List<Communication_Recipient__c>();
            if(recipientPerCommsMap.containsKey(recipient.CC_Communication__c)){
                recipients = recipientPerCommsMap.get(recipient.CC_Communication__c);
            }
            recipients.add(recipient);
            recipientPerCommsMap.put(recipient.CC_Communication__c, recipients);
        }
        
        Email_Settings__c settings = [SELECT Default_Org_Wide_Email_Id__c, Email_BCC_Limit_Error_Message__c, Email_CC_Limit_Error_Message__c,
                                        Email_Disabled_Error_Message__c, Email_Sent_Daily_Limit_Error_Message__c, Email_To_Limit_Error_Message__c,
                                        Email_Transaction_Limit_Error_Message__c, isActive__c, Max_Email_CC_BCC_Number__c,
                                        Max_Email_To_Number__c
                                      FROM Email_Settings__c];
        System.debug('[test_buildCommunicationEmailMessage_positive]settings-->'+settings);
        EmailUtility.settings= settings;
        String orgWideEmailId = null;
        if(settings.Default_Org_Wide_Email_Id__c != null){
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: settings.Default_Org_Wide_Email_Id__c];
            if ( owea.size() > 0 ) {
                orgWideEmailId = owea[0].id;
            }
        }
        
        test.startTest();
        Communication__c whatObj = comms[0];
        whatObj.Email_Template_Id__c = emailTemplate.Id;
        
        Map<String, Object> buildResponse = EmailUtility.buildCommunicationEmailMessage(whatObj, recipientPerCommsMap, orgWideEmailId);
        System.debug('[test_buildCommunicationEmailMessage_positive]buildResponse-->'+buildResponse);
        test.stopTest();
        System.assertEquals(false, (boolean)buildResponse.get('hasError'));
         
    }
    
    //negative path test 1 for EmailUtility.buildCommunicationEmailMessage()-->INVALID COMMUNICATION OBJECT
    static testMethod void test_buildCommunicationEmailMessage_negative1(){
        
        //setup settings
        populateLowLimitSettings();
        
        //retrieve sample template
        EmailTemplate emailTemplate = Database.query(EmailUtility.getCreatableFieldsSOQL('EmailTemplate','DeveloperName =\'Event_Invitation_Template\''));//[SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName ='Event_Invitation_Template'];
        
        //retrieve Communication__c record
        List<Communication__c> comms = Database.query(EmailUtility.getCreatableFieldsSOQL('Communication__c',''));//[SELECT Id, OwnerId, Email_Template_Id__c, Subject__c, Body__c, Email_Recipient_CC__c, Email_Recipient_BCC__c FROM Communication__c];
        
        //retrieve Communication_Recipient__c
        Map<Id, List<Communication_Recipient__c>> recipientPerCommsMap = new Map<Id, List<Communication_Recipient__c>>();
        for(Communication_Recipient__c recipient: [SELECT Id, 
                                                        Journey_Participant__c, 
                                                        Journey_Participant__r.Contact__c, 
                                                        Journey_Participant__r.Contact__r.Email,
                                                        CC_Communication__c
                                                    FROM Communication_Recipient__c
                                                   WHERE CC_Communication__c IN: comms
                                                  ])
        {
            List<Communication_Recipient__c> recipients = new List<Communication_Recipient__c>();
            if(recipientPerCommsMap.containsKey(recipient.CC_Communication__c)){
                recipients = recipientPerCommsMap.get(recipient.CC_Communication__c);
            }
            recipients.add(recipient);
            recipientPerCommsMap.put(recipient.CC_Communication__c, recipients);
        }
        
        Email_Settings__c settings = [SELECT Default_Org_Wide_Email_Id__c, Email_BCC_Limit_Error_Message__c, Email_CC_Limit_Error_Message__c,
                                        Email_Disabled_Error_Message__c, Email_Sent_Daily_Limit_Error_Message__c, Email_To_Limit_Error_Message__c,
                                        Email_Transaction_Limit_Error_Message__c, isActive__c, Max_Email_CC_BCC_Number__c,
                                        Max_Email_To_Number__c
                                      FROM Email_Settings__c];
        System.debug('[test_buildCommunicationEmailMessage_negative1]settings-->'+settings);
        EmailUtility.settings= settings;
        String orgWideEmailId = null;
        if(settings.Default_Org_Wide_Email_Id__c != null){
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: settings.Default_Org_Wide_Email_Id__c];
            if ( owea.size() > 0 ) {
                orgWideEmailId = owea[0].id;
            }
        }
        
        test.startTest();
        Communication__c whatObj = comms[0];
        whatObj.Email_Template_Id__c = emailTemplate.Id;
        
        Map<String, Object> buildResponse = EmailUtility.buildCommunicationEmailMessage(null, recipientPerCommsMap, orgWideEmailId);
        System.debug('[test_buildCommunicationEmailMessage_negative1]buildResponse-->'+buildResponse);
        test.stopTest();
        //buildResponse-->{hasError=true, messages=(Communications record error.)}
        System.assertEquals(true, (boolean)buildResponse.get('hasError'));
        System.assertEquals('Communications record error.', ((List<String>)buildResponse.get('messages'))[0]);
        
         
    }
    
    //negative path test 2 for EmailUtility.buildCommunicationEmailMessage()-->EXCEED MAXIMUM RECIPIENTS (TO, CC, BCC)
    static testMethod void test_buildCommunicationEmailMessage_negative2(){
        
        //setup settings
        populateInactiveSettings();
        
        //retrieve sample template
        EmailTemplate emailTemplate = Database.query(EmailUtility.getCreatableFieldsSOQL('EmailTemplate','DeveloperName =\'Event_Invitation_Template\''));//[SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName ='Event_Invitation_Template'];
        
        //retrieve Communication__c record
        List<Communication__c> comms = Database.query(EmailUtility.getCreatableFieldsSOQL('Communication__c',''));//[SELECT Id, OwnerId, Email_Template_Id__c, Subject__c, Body__c, Email_Recipient_CC__c, Email_Recipient_BCC__c FROM Communication__c];
        
        //retrieve Communication_Recipient__c
        Map<Id, List<Communication_Recipient__c>> recipientPerCommsMap = new Map<Id, List<Communication_Recipient__c>>();
        for(Communication_Recipient__c recipient: [SELECT Id, 
                                                        Journey_Participant__c, 
                                                        Journey_Participant__r.Contact__c, 
                                                        Journey_Participant__r.Contact__r.Email,
                                                        CC_Communication__c
                                                    FROM Communication_Recipient__c
                                                   WHERE CC_Communication__c IN: comms
                                                  ])
        {
            List<Communication_Recipient__c> recipients = new List<Communication_Recipient__c>();
            if(recipientPerCommsMap.containsKey(recipient.CC_Communication__c)){
                recipients = recipientPerCommsMap.get(recipient.CC_Communication__c);
            }
            recipients.add(recipient);
            recipientPerCommsMap.put(recipient.CC_Communication__c, recipients);
        }
        
        Email_Settings__c settings = [SELECT Default_Org_Wide_Email_Id__c, Email_BCC_Limit_Error_Message__c, Email_CC_Limit_Error_Message__c,
                                        Email_Disabled_Error_Message__c, Email_Sent_Daily_Limit_Error_Message__c, Email_To_Limit_Error_Message__c,
                                        Email_Transaction_Limit_Error_Message__c, isActive__c, Max_Email_CC_BCC_Number__c,
                                        Max_Email_To_Number__c
                                      FROM Email_Settings__c];
        System.debug('[test_buildCommunicationEmailMessage_negative2]settings-->'+settings);
        EmailUtility.settings= settings;
        String orgWideEmailId = null;
        if(settings.Default_Org_Wide_Email_Id__c != null){
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =: settings.Default_Org_Wide_Email_Id__c];
            if ( owea.size() > 0 ) {
                orgWideEmailId = owea[0].id;
            }
        }
        
        test.startTest();
        Communication__c whatObj = comms[0];
        whatObj.Email_Template_Id__c = emailTemplate.Id;
        
        Map<String, Object> buildResponse = EmailUtility.buildCommunicationEmailMessage(whatObj, recipientPerCommsMap, orgWideEmailId);
        System.debug('[test_buildCommunicationEmailMessage_negative2]buildResponse-->'+buildResponse);
        test.stopTest();
        //{hasError=true, messages=(Maximum Email To Address Count Reached: 100., Maximum Email CC Address Count Reached: 25., Maximum Email BCC Address Count Reached: 25.)}
        System.assertEquals(true, (boolean)buildResponse.get('hasError'));
        System.assertEquals(3, ((List<String>)buildResponse.get('messages')).size());
         
    }
    
    //happy path test for EmailUtility.wrapEmailMessage()
    static testMethod void test_wrapEmailMessage_positive(){        
        //retrieve sample template
        EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName ='Event_Invitation_Template'];
        
        //retrieve Communication__c record
        List<Communication__c> comms = [SELECT Id, OwnerId, Email_Template_Id__c, Subject__c, Body__c, Email_Recipient_CC__c, Email_Recipient_BCC__c FROM Communication__c];
        
        test.startTest();
        Communication__c whatObj = comms[0];
        whatObj.Email_Template_Id__c = emailTemplate.Id;
        EmailUtility.singleMailMessageWrapper wrapper = EmailUtility.wrapEmailMessage(whatObj.Id, 
                                                             whatObj.OwnerId,
                                                             whatObj.Email_Template_Id__c,
                                                             'Custom Subject',
                                                             'Custom HTML BODY',
                                                            new List<String>{'testTo@testEmailUtility.test'},
                                                            new List<String>{'testCC@testEmailUtility.test'},
                                                            new List<String>{'testBCC@testEmailUtility.test'});
        wrapper.setPlainTextBody = 'Custom PLAIN BODY';
        System.debug('[test_wrapEmailMessage_positive]wrapper-->'+wrapper);
        test.stopTest();
        System.assertEquals(true, wrapper!=null);
        System.assertEquals(whatObj.OwnerId, wrapper.setTargetObjectId);
         
    }
    
    //happy path test for EmailUtility.wrapCommunicationEmailMessage()
    static testMethod void test_wrapCommunicationEmailMessage_positive(){
        //setup settings
        populateActiveSettings();
        
        //retrieve sample template
        EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName ='Event_Invitation_Template'];
        
        //retrieve Communication__c record
        List<Communication__c> comms = [SELECT Id, OwnerId, Email_Template_Id__c, Subject__c, Body__c, Email_Recipient_CC__c, Email_Recipient_BCC__c, Organization_Wide_Email_Id__c FROM Communication__c];
        
        //retrieve Communication_Recipient__c
        Map<Id, List<Communication_Recipient__c>> recipientPerCommsMap = new Map<Id, List<Communication_Recipient__c>>();
        for(Communication_Recipient__c recipient: [SELECT Id, 
                                                        Journey_Participant__c, 
                                                        Journey_Participant__r.Contact__c, 
                                                        Journey_Participant__r.Contact__r.Email,
                                                        CC_Communication__c
                                                    FROM Communication_Recipient__c
                                                   WHERE CC_Communication__c IN: comms
                                                  ])
        {
            List<Communication_Recipient__c> recipients = new List<Communication_Recipient__c>();
            if(recipientPerCommsMap.containsKey(recipient.CC_Communication__c)){
                recipients = recipientPerCommsMap.get(recipient.CC_Communication__c);
            }
            recipients.add(recipient);
            recipientPerCommsMap.put(recipient.CC_Communication__c, recipients);
        }
        
        
        test.startTest();
        Communication__c whatObj = comms[0];
        whatObj.Email_Template_Id__c = emailTemplate.Id;
        Map<String, Object> wrapResponse = EmailUtility.wrapCommunicationEmailMessage(whatObj, recipientPerCommsMap);
        System.debug('[test_wrapCommunicationEmailMessage_positive]wrapResponse-->'+wrapResponse);
        test.stopTest();
        System.assertEquals(false, (boolean)wrapResponse.get('hasError'));
        System.assertEquals(10, ((List<String>)((EmailUtility.singleMailMessageWrapper)wrapResponse.get('emailMessage')).setToAddresses).size());
         
    }
    
    //happy path test for EmailUtility.sendEmailMessage()
    static testMethod void test_sendEmailMessage_positive(){
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        Communication__c whatObj = [SELECT Id, OwnerId, Email_Template_Id__c FROM Communication__c];
        EmailTemplate template = [SELECT id FROM EmailTemplate WHERE DeveloperName = 'unique_name_test_emailtemplate'];
        whatObj.Email_Template_Id__c = template.Id;
        
        List<Messaging.SingleEmailMessage> emailObjects = new List<Messaging.SingleEmailMessage>();
        emailMessage = EmailUtility.buildEmailMessage((SObject)whatObj, 
                                        whatObj.OwnerId, 
                                        (String)template.Id, 
                                        'TEST CUSTOM SUBJECT',
                                        'TEST CUSTOM HTML BODY',
                                        new List<String>{'testTo@testEmailUtility.test'},
                                        new List<String>{'testCC@testEmailUtility.test'},
                                        new List<String>{'testBCC@testEmailUtility.test'});
        emailObjects.add(emailMessage);
        
        test.startTest();
        Messaging.SendEmailResult[] result = EmailUtility.sendEmailMessage(emailObjects);
        System.debug('[test_sendEmailMessage_positive]result-->'+result);
        test.stopTest();
        //result-->(Messaging.SendEmailResult[getErrors=();isSuccess=true;])        
        System.assertEquals(true, (boolean)result[0].isSuccess());
    }
    
    //happy path test for EmailUtility.sendEmailMessage_SingleEmailMessage()
    static testMethod void test_sendEmailMessage_SingleEmailMessage_positive(){
        //setting utility class for testing
        //EmailUtility.isTest = false;//
        EmailUtility.currentOrgEmailCalls=10;
        EmailUtility.currentTransactionEmailCalls=10;  
        System.debug('[test_sendEmailMessage_SingleEmailMessage_positive]EmailUtility.isTest-->'+EmailUtility.isTest);      
        //setup settings
        populateActiveSettings();
        Email_Settings__c settings = [SELECT Default_Org_Wide_Email_Id__c, Email_BCC_Limit_Error_Message__c, Email_CC_Limit_Error_Message__c,
                                        Email_Disabled_Error_Message__c, Email_Sent_Daily_Limit_Error_Message__c, Email_To_Limit_Error_Message__c,
                                        Email_Transaction_Limit_Error_Message__c, isActive__c, Max_Email_CC_BCC_Number__c,
                                        Max_Email_To_Number__c
                                      FROM Email_Settings__c];
        System.debug('[test_sendEmailMessage_SingleEmailMessage_positive]settings-->'+settings);
        EmailUtility.settings= settings;
        Communication__c whatObj = [SELECT Id, OwnerId, Email_Template_Id__c FROM Communication__c];
        EmailTemplate template = [SELECT id FROM EmailTemplate WHERE DeveloperName = 'unique_name_test_emailtemplate'];
        whatObj.Email_Template_Id__c = template.Id;
        
        List<Messaging.SingleEmailMessage> emailObjects = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage emailMessage = EmailUtility.buildEmailMessage((SObject)whatObj, 
                                        whatObj.OwnerId, 
                                        (String)template.Id, 
                                        'TEST CUSTOM SUBJECT',
                                        'TEST CUSTOM HTML BODY',
                                        new List<String>{'testTo@testEmailUtility.test'},
                                        new List<String>{'testCC@testEmailUtility.test'},
                                        new List<String>{'testBCC@testEmailUtility.test'});
        emailObjects.add(emailMessage);
        
        test.startTest();
        Map<String, Object> sendingResponse = EmailUtility.sendEmailMessage_SingleEmailMessage(emailObjects);
        System.debug('[test_sendEmailMessage_SingleEmailMessage_positive]sendingResponse-->'+sendingResponse);
        test.stopTest();
        //{hasError=false, messages=(), resultMap={a4u030000004DZ5AAM=Messaging.SendEmailResult[getErrors=();isSuccess=true;]}}
        System.assertEquals(false, (boolean)sendingResponse.get('hasError'));
        System.assertEquals(true, ((Map<String, Object>)sendingResponse.get('resultMap')).containsKey(whatObj.Id));
    }
    
    //negative path test for EmailUtility.sendEmailMessage_SingleEmailMessage()-->INACTIVE SETTINGS
    static testMethod void test_sendEmailMessage_SingleEmailMessage_negative1(){
        //setting utility class for testing
        EmailUtility.isTest = true;//
        EmailUtility.currentOrgEmailCalls=3;
        EmailUtility.currentTransactionEmailCalls=3;  
        //System.debug('[test_sendEmailMessage_SingleEmailMessage_negative1]EmailUtility.isTest-->'+EmailUtility.isTest);      
        //setup settings
        populateInactiveSettings();
        Email_Settings__c settings = [SELECT Default_Org_Wide_Email_Id__c, Email_BCC_Limit_Error_Message__c, Email_CC_Limit_Error_Message__c,
                                        Email_Disabled_Error_Message__c, Email_Sent_Daily_Limit_Error_Message__c, Email_To_Limit_Error_Message__c,
                                        Email_Transaction_Limit_Error_Message__c, isActive__c, Max_Email_CC_BCC_Number__c,
                                        Max_Email_To_Number__c
                                      FROM Email_Settings__c];
        System.debug('[test_sendEmailMessage_SingleEmailMessage_negative1]settings-->'+settings);
        //EmailUtility.settings= settings;
        Communication__c whatObj = [SELECT Id, OwnerId, Email_Template_Id__c FROM Communication__c];
        EmailTemplate template = [SELECT id FROM EmailTemplate WHERE DeveloperName = 'unique_name_test_emailtemplate'];
        whatObj.Email_Template_Id__c = template.Id;
        
        List<Messaging.SingleEmailMessage> emailObjects = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage emailMessage = EmailUtility.buildEmailMessage((SObject)whatObj, 
                                        whatObj.OwnerId, 
                                        (String)template.Id, 
                                        'TEST CUSTOM SUBJECT',
                                        'TEST CUSTOM HTML BODY',
                                        new List<String>{'testTo@testEmailUtility.test'},
                                        new List<String>{'testCC@testEmailUtility.test'},
                                        new List<String>{'testBCC@testEmailUtility.test'});
        emailObjects.add(emailMessage);
        
        test.startTest();
        Map<String, Object> sendingResponse = EmailUtility.sendEmailMessage_SingleEmailMessage(emailObjects);
        System.debug('[test_sendEmailMessage_SingleEmailMessage_negative1]sendingResponse-->'+sendingResponse);
        test.stopTest();
        //sendingResponse-->{hasError=true, messages=(Email Sending is disabled in settings.)}
        System.assertEquals(true, (boolean)sendingResponse.get('hasError'));
        System.assertEquals('Email Sending is disabled in settings.', ((List<String>)sendingResponse.get('messages'))[0]);
    }
    
    //negative path test for EmailUtility.sendEmailMessage_SingleEmailMessage()-->LIMIT REACHED
    static testMethod void test_sendEmailMessage_SingleEmailMessage_negative2(){
        //setting utility class for testing
        EmailUtility.isTest = true;//
        EmailUtility.currentOrgEmailCalls=5000;
        EmailUtility.currentTransactionEmailCalls=10;  
        //System.debug('[test_sendEmailMessage_SingleEmailMessage_negative2]EmailUtility.isTest-->'+EmailUtility.isTest);      
        //setup settings
        populateLowLimitSettings();
        Email_Settings__c settings = [SELECT Default_Org_Wide_Email_Id__c, Email_BCC_Limit_Error_Message__c, Email_CC_Limit_Error_Message__c,
                                        Email_Disabled_Error_Message__c, Email_Sent_Daily_Limit_Error_Message__c, Email_To_Limit_Error_Message__c,
                                        Email_Transaction_Limit_Error_Message__c, isActive__c, Max_Email_CC_BCC_Number__c,
                                        Max_Email_To_Number__c
                                      FROM Email_Settings__c];
        System.debug('[test_sendEmailMessage_SingleEmailMessage_negative2]settings-->'+settings);
        //EmailUtility.settings= settings;
        Communication__c whatObj = [SELECT Id, OwnerId, Email_Template_Id__c FROM Communication__c];
        EmailTemplate template = [SELECT id FROM EmailTemplate WHERE DeveloperName = 'unique_name_test_emailtemplate'];
        whatObj.Email_Template_Id__c = template.Id;
        
        List<Messaging.SingleEmailMessage> emailObjects = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage emailMessage = EmailUtility.buildEmailMessage((SObject)whatObj, 
                                        whatObj.OwnerId, 
                                        (String)template.Id, 
                                        'TEST CUSTOM SUBJECT',
                                        'TEST CUSTOM HTML BODY',
                                        new List<String>{'testTo@testEmailUtility.test'},
                                        new List<String>{'testCC@testEmailUtility.test'},
                                        new List<String>{'testBCC@testEmailUtility.test'});
        emailObjects.add(emailMessage);
        
        test.startTest();
        Map<String, Object> sendingResponse = EmailUtility.sendEmailMessage_SingleEmailMessage(emailObjects);
        System.debug('[test_sendEmailMessage_SingleEmailMessage_negative2]sendingResponse-->'+sendingResponse);
        test.stopTest();
        //sendingResponse-->{hasError=true, messages=(Email Sending is disabled in settings.)}
        System.assertEquals(true, (boolean)sendingResponse.get('hasError'));
        //System.assertEquals('Email Sending is disabled in settings.', ((List<String>)sendingResponse.get('messages'))[0]);
    }
    
    //negative path test for EmailUtility.sendEmailMessage_SingleEmailMessage()-->TRANSACTION LIMIT REACHED
    static testMethod void test_sendEmailMessage_SingleEmailMessage_negative3(){
        //setting utility class for testing
        EmailUtility.isTest = true;//
        EmailUtility.currentOrgEmailCalls=500;
        EmailUtility.currentTransactionEmailCalls=10; 
        //System.debug('[test_sendEmailMessage_SingleEmailMessage_negative3]EmailUtility.isTest-->'+EmailUtility.isTest);      
        //setup settings
        populateLowLimitSettings();
        Email_Settings__c settings = [SELECT Default_Org_Wide_Email_Id__c, Email_BCC_Limit_Error_Message__c, Email_CC_Limit_Error_Message__c,
                                        Email_Disabled_Error_Message__c, Email_Sent_Daily_Limit_Error_Message__c, Email_To_Limit_Error_Message__c,
                                        Email_Transaction_Limit_Error_Message__c, isActive__c, Max_Email_CC_BCC_Number__c,
                                        Max_Email_To_Number__c
                                      FROM Email_Settings__c];
        System.debug('[test_sendEmailMessage_SingleEmailMessage_negative3]settings-->'+settings);
        //EmailUtility.settings= settings;
        Communication__c whatObj = [SELECT Id, OwnerId, Email_Template_Id__c FROM Communication__c];
        EmailTemplate template = [SELECT id FROM EmailTemplate WHERE DeveloperName = 'unique_name_test_emailtemplate'];
        whatObj.Email_Template_Id__c = template.Id;
        
        List<Messaging.SingleEmailMessage> emailObjects = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage emailMessage = EmailUtility.buildEmailMessage((SObject)whatObj, 
                                        whatObj.OwnerId, 
                                        (String)template.Id, 
                                        'TEST CUSTOM SUBJECT',
                                        'TEST CUSTOM HTML BODY',
                                        new List<String>{'testTo@testEmailUtility.test'},
                                        new List<String>{'testCC@testEmailUtility.test'},
                                        new List<String>{'testBCC@testEmailUtility.test'});
        emailObjects.add(emailMessage);
        
        test.startTest();
        Map<String, Object> sendingResponse = EmailUtility.sendEmailMessage_SingleEmailMessage(emailObjects);
        System.debug('[test_sendEmailMessage_SingleEmailMessage_negative3]sendingResponse-->'+sendingResponse);
        test.stopTest();
        //sendingResponse-->{hasError=true, messages=(Email Sending is disabled in settings.)}
        System.assertEquals(true, (boolean)sendingResponse.get('hasError'));
        //System.assertEquals('Email Sending is disabled in settings.', ((List<String>)sendingResponse.get('messages'))[0]);
    }
    
    //happy path test for EmailUtility.sendEmailMessage_EmailWrapper()
    static testMethod void test_sendEmailMessage_EmailWrapper_positive(){
        //setting utility class for testing
        //EmailUtility.isTest = false;//
        EmailUtility.currentOrgEmailCalls=10;
        EmailUtility.currentTransactionEmailCalls=10;  
        //setup settings
        populateActiveSettings();
        Email_Settings__c settings = [SELECT Default_Org_Wide_Email_Id__c, Email_BCC_Limit_Error_Message__c, Email_CC_Limit_Error_Message__c,
                                        Email_Disabled_Error_Message__c, Email_Sent_Daily_Limit_Error_Message__c, Email_To_Limit_Error_Message__c,
                                        Email_Transaction_Limit_Error_Message__c, isActive__c, Max_Email_CC_BCC_Number__c,
                                        Max_Email_To_Number__c
                                      FROM Email_Settings__c];
        EmailUtility.settings= settings;
        //retrieve sample template
        EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName ='Event_Invitation_Template'];
        
        //retrieve Communication__c record
        List<Communication__c> comms = [SELECT Id, OwnerId, Email_Template_Id__c, Subject__c, Body__c, Email_Recipient_CC__c, Email_Recipient_BCC__c FROM Communication__c];
        
        test.startTest();
        Communication__c whatObj = comms[0];
        whatObj.Email_Template_Id__c = emailTemplate.Id;
        EmailUtility.singleMailMessageWrapper wrapper = EmailUtility.wrapEmailMessage(whatObj.Id, 
                                                             whatObj.OwnerId,
                                                             whatObj.Email_Template_Id__c,
                                                             'Custom Subject',
                                                             'Custom HTML BODY',
                                                            new List<String>{'testTo@testEmailUtility.test'},
                                                            new List<String>{'testCC@testEmailUtility.test'},
                                                            new List<String>{'testBCC@testEmailUtility.test'});
        wrapper.setPlainTextBody = 'Custom PLAIN BODY';
        List<EmailUtility.singleMailMessageWrapper> wrappers = new List<EmailUtility.singleMailMessageWrapper>();
        wrappers.add(wrapper);
        Map<String, Object> response = EmailUtility.sendEmailMessage_EmailWrapper(JSON.serialize(wrappers));
        System.debug('[test_sendEmailMessage_EmailWrapper_positive]response-->'+response);
        System.assertEquals(false, (boolean)response.get('hasError'));
    }
    
    //happy path test for EmailUtility.sendEmailMessageFuture()
    static testMethod void test_sendEmailMessageFuture_positive(){
        //setting utility class for testing
        //EmailUtility.isTest = false;//
        EmailUtility.currentOrgEmailCalls=10;
        EmailUtility.currentTransactionEmailCalls=10;  
        //setup settings
        populateActiveSettings();
        Email_Settings__c settings = [SELECT Default_Org_Wide_Email_Id__c, Email_BCC_Limit_Error_Message__c, Email_CC_Limit_Error_Message__c,
                                        Email_Disabled_Error_Message__c, Email_Sent_Daily_Limit_Error_Message__c, Email_To_Limit_Error_Message__c,
                                        Email_Transaction_Limit_Error_Message__c, isActive__c, Max_Email_CC_BCC_Number__c,
                                        Max_Email_To_Number__c
                                      FROM Email_Settings__c];
        //System.debug('[test_sendEmailMessageFuture_positive]settings-->'+settings);
        EmailUtility.settings= settings;
        //retrieve sample template
        EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName ='Event_Invitation_Template'];
        
        //retrieve Communication__c record
        List<Communication__c> comms = [SELECT Id, OwnerId, Email_Template_Id__c, Subject__c, Body__c, Email_Recipient_CC__c, Email_Recipient_BCC__c FROM Communication__c];
        
        test.startTest();
        Communication__c whatObj = comms[0];
        whatObj.Email_Template_Id__c = emailTemplate.Id;
        EmailUtility.singleMailMessageWrapper wrapper = EmailUtility.wrapEmailMessage(whatObj.Id, 
                                                             whatObj.OwnerId,
                                                             whatObj.Email_Template_Id__c,
                                                             'Custom Subject',
                                                             'Custom HTML BODY',
                                                            new List<String>{'testTo@testEmailUtility.test'},
                                                            new List<String>{'testCC@testEmailUtility.test'},
                                                            new List<String>{'testBCC@testEmailUtility.test'});
        wrapper.setPlainTextBody = 'Custom PLAIN BODY';
        //System.debug('[test_sendEmailMessageFuture_positive]wrapper-->'+wrapper);
        List<EmailUtility.singleMailMessageWrapper> wrappers = new List<EmailUtility.singleMailMessageWrapper>();
        wrappers.add(wrapper);
        EmailUtility.sendEmailMessageFuture(JSON.serialize(wrappers));
        //System.debug('[test_sendEmailMessageFuture_positive]JSON.serialize(wrappers)-->'+JSON.serialize(wrappers));
        System.assertEquals(true, wrapper!=null);
        System.assertEquals(whatObj.OwnerId, wrapper.setTargetObjectId);
        
        
        List<Communication__c> commsAfter = [SELECT Id, OwnerId, Email_Template_Id__c, Subject__c, Body__c, Email_Recipient_CC__c, Email_Recipient_BCC__c FROM Communication__c];
        System.debug('[test_sendEmailMessageFuture_positive]commsAfter-->'+commsAfter);
    }
    
    //happy path test for EmailUtility.sendCommunicationEmailMessageFuture()
    /* static testMethod void test_sendCommunicationEmailMessageFuture_positive(){
        //setting utility class for testing
        //EmailUtility.isTest = false;//
        EmailUtility.currentOrgEmailCalls=10;
        EmailUtility.currentTransactionEmailCalls=10;  
        //setup settings
        populateActiveSettings();
        
        //retrieve sample template
        EmailTemplate emailTemplate = Database.query(EmailUtility.getCreatableFieldsSOQL('EmailTemplate','DeveloperName =\'Event_Invitation_Template\''));//[SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName ='Event_Invitation_Template'];
        
        //retrieve Communication__c record
        List<Communication__c> comms = Database.query(EmailUtility.getCreatableFieldsSOQL('Communication__c',''));//[SELECT Id, OwnerId, Email_Template_Id__c, Subject__c, Body__c, Email_Recipient_CC__c, Email_Recipient_BCC__c FROM Communication__c];
        System.debug('[test_sendCommunicationEmailMessageFuture_positive]BEFORE EMAIL-->'+comms);   
        //retrieve Communication_Recipient__c
        Map<Id, List<Communication_Recipient__c>> recipientPerCommsMap = new Map<Id, List<Communication_Recipient__c>>();
        for(Communication_Recipient__c recipient: [SELECT Id, 
                                                        Journey_Participant__c, 
                                                        Journey_Participant__r.Contact__c, 
                                                        Journey_Participant__r.Contact__r.Email,
                                                        CC_Communication__c
                                                    FROM Communication_Recipient__c
                                                   WHERE CC_Communication__c IN: comms
                                                  ])
        {
            List<Communication_Recipient__c> recipients = new List<Communication_Recipient__c>();
            if(recipientPerCommsMap.containsKey(recipient.CC_Communication__c)){
                recipients = recipientPerCommsMap.get(recipient.CC_Communication__c);
            }
            recipients.add(recipient);
            recipientPerCommsMap.put(recipient.CC_Communication__c, recipients);
        }
        
        Communication__c whatObj = comms[0];
        whatObj.Email_Template_Id__c = emailTemplate.Id;
        
        Map<String, Object> buildResponse = EmailUtility.wrapCommunicationEmailMessage(whatObj,recipientPerCommsMap);
        System.debug('[test_sendCommunicationEmailMessageFuture_positive]buildResponse-->'+buildResponse);
        
        
        List<EmailUtility.singleMailMessageWrapper> wrappers = new List<EmailUtility.singleMailMessageWrapper>();
        if(buildResponse.containsKey('hasError')){
            Boolean hasError = (Boolean)buildResponse.get('hasError');
            if(!hasError){
                EmailUtility.singleMailMessageWrapper email = (EmailUtility.singleMailMessageWrapper)buildResponse.get('emailMessage');
                System.debug('[test_sendCommunicationEmailMessageFuture_positive]email-->'+email);
                wrappers.add(email);
            }
        }
        EmailUtility.sendCommunicationEmailMessageFuture(JSON.serialize(wrappers));
        List<Communication__c> afterComms = Database.query(EmailUtility.getCreatableFieldsSOQL('Communication__c',''));
        System.debug('[test_sendCommunicationEmailMessageFuture_positive]after EMAIL-->'+afterComms);
        System.assertEquals(false, (boolean)buildResponse.get('hasError'));
        System.assertEquals(10, ((List<String>)((EmailUtility.singleMailMessageWrapper)buildResponse.get('emailMessage')).setToAddresses).size());   
    } */
    
    //negative path test for EmailUtility.test_updateFailedComms()-->wrong email recipients
    static testMethod void test_updateFailedComms(){
        //setting utility class for testing
        EmailUtility.isTest = true;//
        EmailUtility.currentOrgEmailCalls=10;
        EmailUtility.currentTransactionEmailCalls=5;  
        //setup settings
        populateActiveSettings();
        
        //retrieve Communication__c record
        List<Communication__c> comms = Database.query(EmailUtility.getCreatableFieldsSOQL('Communication__c',''));//[SELECT Id, OwnerId, Email_Template_Id__c, Subject__c, Body__c, Email_Recipient_CC__c, Email_Recipient_BCC__c FROM Communication__c];
        System.debug('[test_updateFailedComms]BEFORE EMAIL-->'+comms);   
        //retrieve Communication_Recipient__c
        Map<Id, List<Communication_Recipient__c>> recipientPerCommsMap = new Map<Id, List<Communication_Recipient__c>>();
        for(Communication_Recipient__c recipient: [SELECT Id, 
                                                        Journey_Participant__c, 
                                                        Journey_Participant__r.Contact__c, 
                                                        Journey_Participant__r.Contact__r.Email,
                                                        CC_Communication__c
                                                    FROM Communication_Recipient__c
                                                   WHERE CC_Communication__c IN: comms
                                                  ])
        {
            List<Communication_Recipient__c> recipients = new List<Communication_Recipient__c>();
            if(recipientPerCommsMap.containsKey(recipient.CC_Communication__c)){
                recipients = recipientPerCommsMap.get(recipient.CC_Communication__c);
            }
            recipients.add(recipient);
            recipientPerCommsMap.put(recipient.CC_Communication__c, recipients);
        }
        
        Communication__c whatObj = comms[0];
        whatObj.Email_Template_Id__c = whatObj.Id;//emailTemplate.Id;//wrong template id
        
        Map<String, Object> buildResponse = EmailUtility.wrapCommunicationEmailMessage(whatObj,recipientPerCommsMap);
        //System.debug('[test_updateFailedComms]buildResponse-->'+buildResponse);
        
        
        List<EmailUtility.singleMailMessageWrapper> wrappers = new List<EmailUtility.singleMailMessageWrapper>();
        if(buildResponse.containsKey('hasError')){
            Boolean hasError = (Boolean)buildResponse.get('hasError');
            if(!hasError){
                EmailUtility.singleMailMessageWrapper email = (EmailUtility.singleMailMessageWrapper)buildResponse.get('emailMessage');
                System.debug('[test_updateFailedComms]email-->'+email);
                wrappers.add(email);
            }
        }
        String jsonWrapper = JSON.serialize(wrappers);
        System.debug('[test_updateFailedComms]jsonWrapper-->'+jsonWrapper);
        jsonWrapper=jsonWrapper.replace('.test', '');
        System.debug('[test_updateFailedComms]BEFORE SENDING(jsonWrapper)-->'+jsonWrapper);
        
        
        //
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage emailmessage;
        if(jsonWrapper != null){
            for(EmailUtility.singleMailMessageWrapper eWrapper : (List<EmailUtility.singleMailMessageWrapper>) JSON.deserialize(jsonWrapper,List<EmailUtility.singleMailMessageWrapper>.class)){
                emailmessage = new Messaging.SingleEmailMessage();
                emailmessage.setSaveAsActivity(eWrapper.setSaveAsActivity);
                emailmessage.setSubject(eWrapper.setSubject);
                emailmessage.setPlainTextBody(eWrapper.setPlainTextBody);//<!--START - ADDED BY JLAURIO 20191129 JCC5862 BUG FIX (JCC-6098) -->
                emailmessage.setHtmlBody(eWrapper.setHtmlBody);
                emailmessage.setWhatId(eWrapper.setWhatId);
                //emailmessage.settargetObjectId(eWrapper.settargetObjectId);
                emailmessage.setTemplateId(eWrapper.setTemplateId);
                emailmessage.setToAddresses(eWrapper.setToAddresses);
                emailmessage.setCcAddresses(eWrapper.setCcAddresses);
                
                emails.add(emailmessage);
            }
            
            Map<String, Object> sendingResponse = null;
            if(emails.size()>0){
                System.debug('emails: ' + emails);
                sendingResponse = EmailUtility.executeSendEmail(emails);
            }
            
            System.debug('[test_updateFailedComms]sendingResponse-->'+sendingResponse);
            if(sendingResponse!=null && sendingResponse.containsKey('hasError')){
                Boolean hasError = (Boolean)sendingResponse.get('hasError');
                Set<Id> successIds = new Set<Id>();
                Map<String, Object> failedResults = new Map<String, Object>();
                if(!hasError){
                    Map<String, Object> resultMap =(Map<String, Object>)sendingResponse.get('resultMap');
                    
                    System.debug('[test_updateFailedComms]resultMap-->'+resultMap);
                    for(String whatId : resultMap.keySet()){
                        System.debug('[test_updateFailedComms]whatId-->'+whatId);
                        Messaging.SendEmailResult result = (Messaging.SendEmailResult)resultMap.get(whatId);
                        System.debug('[test_updateFailedComms]result-->'+result);
                        if(result.isSuccess()){
                            successIds.add(whatId);
                        }
                        else{
                            failedResults.put(whatId, result);
                        }
                    }
                }
                //post-sending processing
                if(successIds.size()>0){
                    List<Id> successIdList = new List<Id>(successIds);
                    Map<String, Object> successDMLResults = EmailUtility.updateSuccessComms(successIds, recipientPerCommsMap.get(successIdList[0]), 0);
                }
                if(failedResults.size()>0){
                    Map<String, Object> failedDMLResults = EmailUtility.updateFailedComms(failedResults, 0);
                }
            }
        }

        List<Communication__c> afterComms = Database.query(EmailUtility.getCreatableFieldsSOQL('Communication__c',''));        
        System.debug('[test_updateFailedComms]after EMAIL-->'+afterComms);
        System.assertEquals(true, comms[0].Status__c!='Failed');
        System.assertEquals(true, afterComms[0].Id==comms[0].Id);
        System.assertEquals(true, afterComms[0].Status__c=='Failed');
        //System.assertEquals(10, ((List<String>)((EmailUtility.singleMailMessageWrapper)buildResponse.get('emailMessage')).setToAddresses).size());   
    }
    
    //happy path test for EmailUtility.sendConfirmationCalendarInvite()
    static testMethod void test_sendConfirmationCalendarInvite_positive(){
        List<Participant__c> participants = [SELECT Id, Status__c, Session_Modified__c FROM Participant__c];
        System.debug('[test_sendConfirmationCalendarInvite_positive]participants-->'+participants);
        if(!participants.isEmpty()){
            participants[0].Status__c = 'Registered';
            participants[0].Session_Modified__c = true;
            update participants;
        }
        EmailUtility.sendConfirmationCalendarInvite(new List<ID>{participants[0].Id});
    }

    static testMethod void test_buildCommunicationEmailList_positive(){
        populateActiveSettings();
        Id emailAddressesId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        Communication__c testComms = [SELECT Id, 
                                             Email_Template_Id__c, 
                                             Subject__c, 
                                             Body__c, 
                                             Email_Recipient_CC__c, 
                                             Email_Recipient_BCC__c,
                                             Reply_Email_Address__c
                                             FROM Communication__c LIMIT 1];
        List<Communication_Recipient__c> commsRecipients = [SELECT Id, 
                                                                   Contact__c, 
                                                                   Journey_Participant__c,
                                                                   Journey_Participant__r.Contact__c,
                                                                   Survey_Participant__c,
                                                                   Survey_Participant__r.Participant__c,
                                                                   Event_Participant__c,
                                                                   Event_Participant__r.Member_Contact__c
                                                                   FROM Communication_Recipient__c LIMIT 1];
        Test.startTest();
        List<Map<String, Object>> responseList = EmailUtility.buildCommunicationEmailList(testComms, commsRecipients, emailAddressesId);
        Test.stopTest();
        System.debug('EmailUtilityTest: hasError' + responseList[0].get('hasError'));
        System.debug('EmailUtilityTest: error messages' + responseList[0].get('messages'));
        System.assert(!(Boolean)responseList[0].get('hasError'));
    }
    static testMethod void test_buildCommunicationEmailList_negative(){
        Id emailAddressesId = [SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id;
        Communication__c testComms = [SELECT Id, 
                                             Email_Template_Id__c, 
                                             Subject__c, 
                                             Body__c, 
                                             Email_Recipient_CC__c, 
                                             Email_Recipient_BCC__c
                                             FROM Communication__c LIMIT 1];
        // no recipients
        List<Communication_Recipient__c> commsRecipients = new List<Communication_Recipient__c>();
        Test.startTest();
        List<Map<String, Object>> responseList = EmailUtility.buildCommunicationEmailList(testComms, commsRecipients, emailAddressesId);
        Test.stopTest();
        System.assert(responseList == null || responseList.size() == 0);
    }

}