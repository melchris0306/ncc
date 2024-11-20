/** 
 * @Date: 05/18/2021
 * @Description: test class for CC_SessionParticipantsAttended
 * @Modification: increase code coverage for [CCN975]
**/
@isTest (seeAllData = false)
public with sharing class CC_SessionParticipantsAttendedTest {

    @TestSetup static void testData(){
        User adminUser = TestFactory.createInteralUser('first','last','admin@compass.test.com','System Administrator');

        System.runAs(adminUser) {
            Apex_Trigger_Switch__c apexSwitch = TestDataFactory.createTriggerSwitch('EventTrigger');
            insert apexSwitch;
            
            EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
            insert e;
            
            Compass_Setting__c compSetting = new Compass_Setting__c();
            compSetting.Name = 'Default Settings';
            compSetting.Email_Sender_Id__c = '123';
            compSetting.Email_Sender_Name__c = 'NAME';
            compSetting.Email_Template_Invitation_Id__c = e.Id;
            compSetting.Email_Template_Registration_Id__c = e.Id;
            insert compSetting;
            
            
            Event__c  event = TestFactory.createEvent('TestEventName');
            Session__c session = TestFactory.createSession('Test Session',event.Id); 
            List<Session_Participant__c> participants = TestFactory.createSessionParticipants(2,session.Id);
            participants[0].Status__c = 'Registered';
            participants[1].Status__c = 'Registered';
            insert participants;
            
            //Contact
            Contact con1 = new Contact();
            con1.FirstName = 'Test Contact';
            con1.LastName = 'Record 1';
            con1.Email = 'testemail@testemail.com';
            insert con1;
            
            //Campaign  
            List<Campaign__c> campList = new List<Campaign__c>();
            Campaign__c camp1 = new Campaign__c();
            camp1.Name = 'Test Campaign 001';
            campList.add(camp1);
            
            insert campList;
            
            OrgWideEmailAddress owea = [SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Edera' LIMIT 1];
            
            //Event
            List<Event__c> eventList = new List<Event__c>();
            Event__c event1 = new Event__c();
            event1.Name = 'Test Event 001';
            event1.Campaign__c = camp1.Id;
            event1.Email_Sender_Id__c = owea.Id;
            event1.Email_Sender_Name__c = owea.DisplayName;
            eventList.add(event1);
            
            Event__c event2 = new Event__c();
            event2.Campaign__c = camp1.Id;
            event2.Name = 'Test Event 002';
            eventList.add(event2);
            
            insert eventList;
            
            //Session
            List<Session__c> sessionList = new List<Session__c>();
            Session__c session1 = new Session__c();
            session1.Name = 'Test Session 001';
            session1.Event__c = event1.Id;
            session1.Start_Date_Time__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
            session1.End_Date_Time__c = DateTime.newInstance(2020, 08, 29, 10, 30, 0);
            sessionList.add(session1);
            
            Session__c session2 = new Session__c();
            session2.Name = 'Test Session 002';
            session2.Event__c = event2.Id;
            session2.Time_Zone__c = 'EDT';  
            sessionList.add(session2);
            
            insert sessionList;
            
            
            //Session Participant
            List<Session_Participant__c> sessionParticipantList = new List<Session_Participant__c>();
            Session_Participant__c sp = new Session_Participant__c();
            sp.Session__c = session1.Id;
            sp.Event__c = event1.Id;
            sp.Contact__c = con1.Id;
            sp.Status__c = 'Attended';
            sp.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
            sp.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
            sessionParticipantList.add(sp);
            
            insert sessionParticipantList;
            
        }
    }

    @IsTest
    static void testGetSessionParticipants() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'admin@compass.test.com'];
        
        System.runAs(adminUser) {
            Session__c session = [SELECT Id FROM Session__c LIMIT 1];
            List<Session_Participant__c> participants = null;

            Test.startTest();
                participants = CC_SessionParticipantsAttended.getSessionParticipants(session.Id);
            Test.stopTest();

            System.assert(participants != null);
        }     
    }   

    @IsTest
    static void testMarkSessionParticipantsToAttended() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'admin@compass.test.com'];
        
        System.runAs(adminUser) {
            List<Session_Participant__c> participants = [SELECT Id,Session__c,Status__c FROM Session_Participant__c];

            Test.startTest();
                participants = CC_SessionParticipantsAttended.markSessionParticipantsToAttended(participants[0].Session__c,participants);
            Test.stopTest();

            System.assert(participants.isEmpty());
        }     
    }   

    @IsTest
    static void testMarkSessionParticipantsToAttendedError() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'admin@compass.test.com'];
        
        System.runAs(adminUser) {
            Boolean isError = false;
            Test.startTest();
            try {
                CC_SessionParticipantsAttended.markSessionParticipantsToAttended(null,null);
            } catch (Exception e) {
                isError = true;
            }
            Test.stopTest();
            
            System.assert(isError);
        }     
    }   
    
    /**
    * @description  Added for [CCN975]
    **/
    @IsTest
    static void testGetEventAttendedParticipantFieldsJSON() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'admin@compass.test.com'];
        
        System.runAs(adminUser) {
            Session__c session = [SELECT Id FROM Session__c limit 1];
            
            Test.startTest();
            String attendedFields = CC_SessionParticipantsAttended.getEventAttendedParticipantFieldsJSON(session.Id);
            Test.stopTest();
            
        }     
    }   
    
    /**
    * @description  Added for [CCN975]
    **/
    @IsTest
    static void testGetEventAttendedParticipantFieldsJSONError() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'admin@compass.test.com'];
        
        System.runAs(adminUser) {
            
            Test.startTest();
            try {
                String attendedFields = CC_SessionParticipantsAttended.getEventAttendedParticipantFieldsJSON(null);
            }catch (Exception e){
                System.assert(TRUE);
            }
            Test.stopTest();
        }     
    }   

    /**
    * @description  Added for [CCN975]
    **/    
    @IsTest
    static void testGetPickListValues() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'admin@compass.test.com'];
        
        System.runAs(adminUser) {
            
            Test.startTest();
            List<String> picklistValues = CC_SessionParticipantsAttended.getPickListValues('Readiness_Self_Ranking__c');
            Test.stopTest();
            
        }     
    }      
    
}