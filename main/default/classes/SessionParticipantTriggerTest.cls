@isTest
private class SessionParticipantTriggerTest {
    @testSetup
    static void setup(){
        List<Apex_Trigger_Switch__c> atsList = new List<Apex_Trigger_Switch__c>();
        Apex_Trigger_Switch__c aps_sp = new Apex_Trigger_Switch__c();
        aps_sp.Name = 'SessionParticipantTrigger';
        aps_sp.Active__c = true;
        atsList.add(aps_sp);
        
        Apex_Trigger_Switch__c aps_event = new Apex_Trigger_Switch__c();
        aps_event.Name = 'EventTrigger';
        aps_event.Active__c = false;
        atsList.add(aps_event);
        
        insert atsList;
        
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
   
        Journey__c testJourney = new Journey__c();
        testJourney.Name = 'Test Journey';
        testJourney.Campaign__c = campList[0].Id;
        testJourney.Status__c = 'Approved';
        testJourney.End_Date__c = System.now().addYears(1).date();
        insert testJourney;

        EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        system.runAs( new User(Id = UserInfo.getUserId())){
        	insert e;
        }
        
        Compass_Setting__c compSetting = new Compass_Setting__c();
        compSetting.Name = 'Default Settings';
        compSetting.Email_Sender_Id__c = '123';
        compSetting.Email_Sender_Name__c = 'NAME';
        compSetting.Email_Template_Invitation_Id__c = e.Id;
        compSetting.Email_Template_Registration_Id__c = e.Id;
        insert compSetting;
        
        OrgWideEmailAddress owea = [SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Edera' LIMIT 1];
        
        //Event
        List<Event__c> eventList = new List<Event__c>();
        Event__c event1 = new Event__c();
        event1.Name = 'Test Event 001';
        event1.Campaign__c = camp1.Id;
        event1.Email_Sender_Id__c = owea.Id;
        event1.Email_Sender_Name__c = owea.DisplayName;
        event1.Milestone__c = true;
        event1.IsActive__c = true;
        event1.Start_Date_Time__c = system.today();
        event1.End_Date_Time__c = system.today() + 1;
        event1.Time_Zone__c = 'AKDT';
        event1.Session_Calendar_Invite_Delivery__c = 'Send on session confirmation';
        eventList.add(event1);
        
        Event__c event2 = new Event__c();
        event2.Campaign__c = camp1.Id;
        event2.Name = 'Test Event 002';
        event2.Milestone__c = true;
        event2.IsActive__c = true;
        event2.Start_Date_Time__c = system.today();
        event2.End_Date_Time__c = system.today() + 1;
         event2.Time_Zone__c = 'AKDT';
        event2.Session_Calendar_Invite_Delivery__c = 'Send on session registration';
        eventList.add(event2);
        
        insert eventList;

        Event__c event01 = [SELECT Id FROM Event__c WHERE Name ='Test Event 001' LIMIT 1]; 
       
        Adhoc_Journey_Assignment__c journeyAssignment = new Adhoc_Journey_Assignment__c (
            Journey__c = testJourney.id,
            Event__c = event01.Id,
            Type__c = 'Event'
        );
        insert journeyAssignment;
        
        //Session
        List<Session__c> sessionList = new List<Session__c>();
        Session__c session1 = new Session__c();
        session1.Name = 'Test Session 001';
        session1.Event__c = event1.Id;
        session1.Time_Zone__c = 'AKDT';
        session1.Start_Date_Time__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        session1.End_Date_Time__c = DateTime.newInstance(2020, 08, 29, 10, 30, 0);
        sessionList.add(session1);
        
        Session__c session2 = new Session__c();
        session2.Name = 'Test Session 002';
        session2.Event__c = event2.Id;

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
    
    @isTest private static void calendarInviteTest(){
        Session__c session1 = [SELECT Id FROM Session__c WHERE Name ='Test Session 001' LIMIT 1];
        Event__c event1 = [SELECT Id FROM Event__c WHERE Name ='Test Event 001' LIMIT 1]; 
        Contact con1 = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact' LIMIT 1];
        
        //Session Participant
        List<Session_Participant__c> sessionParticipantList = new List<Session_Participant__c>();
        Session_Participant__c sp = new Session_Participant__c();
        sp.Session__c = session1.Id;
		sp.Event__c = event1.Id;
		sp.Contact__c = con1.Id;
        sp.Status__c = 'Registered';
        sp.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sp.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sessionParticipantList.add(sp);
        
        Test.startTest();
        insert sessionParticipantList;
        Test.stopTest();
    }
    
    @IsTest static void sendEmailToSessionParticipant(){
        Session__c session1 = [SELECT Id FROM Session__c WHERE Name ='Test Session 001' LIMIT 1];
        Event__c event1 = [SELECT Id FROM Event__c WHERE Name ='Test Event 001' LIMIT 1]; 
        Contact con1 = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact' LIMIT 1];
        
        Participant__c participantData = new Participant__c();
        participantData.Event__c = event1.Id;
        participantData.Member_Contact__c = con1.Id;
        participantData.Status__c = 'Registered';
        insert participantData;
        
        //Session Participant
        List<Session_Participant__c> sessionParticipantList = new List<Session_Participant__c>();
        Session_Participant__c sp = new Session_Participant__c();
        sp.Session__c = session1.Id;
		sp.Event__c = event1.Id;
		sp.Contact__c = con1.Id;
        sp.Status__c = 'Attended';
        sp.Participant__c = participantData.Id;
        sp.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sp.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sessionParticipantList.add(sp);
        
        Test.startTest();
        insert sessionParticipantList;
        Test.stopTest();
    }
    
    @isTest static void onAfterUpdate() {
        Session__c session1 = [SELECT Id FROM Session__c WHERE Name ='Test Session 001' LIMIT 1];
        Event__c event1 = [SELECT Id FROM Event__c WHERE Name ='Test Event 001' LIMIT 1]; 
        Contact con1 = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact' LIMIT 1];
        
        List<Participant__c> participantDataList = new List<Participant__c>();
        Participant__c participantData = new Participant__c();
        participantData.Event__c = event1.Id;
        participantData.Member_Contact__c = con1.Id;
        participantData.Status__c = 'Registered';
        participantDataList.add(participantData);
        
        Participant__c participantData2 = new Participant__c();
        participantData2.Event__c = event1.Id;
        participantData2.Member_Contact__c = con1.Id;
        participantData2.Status__c = 'Registered';
        participantDataList.add(participantData2);
        insert participantDataList;
        
        //Session Participant
        List<Session_Participant__c> sessionParticipantList = new List<Session_Participant__c>();
        Session_Participant__c sp = new Session_Participant__c();
        sp.Session__c = session1.Id;
		sp.Event__c = event1.Id;
		sp.Contact__c = con1.Id;
        sp.Status__c = 'Attended';
        sp.Participant__c = participantData.Id;
        sp.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sp.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sessionParticipantList.add(sp);
        
        Session_Participant__c sp2 = new Session_Participant__c();
        sp2.Session__c = session1.Id;
		sp2.Event__c = event1.Id;
		sp2.Contact__c = con1.Id;
        sp2.Status__c = 'Confirmed';
        sp2.Participant__c = participantData2.Id;
        sp2.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sp2.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sessionParticipantList.add(sp2);       
        
        Session_Participant__c sp3 = new Session_Participant__c();
        sp3.Session__c = session1.Id;
		sp3.Event__c = event1.Id;
		sp3.Contact__c = con1.Id;
        sp3.Status__c = 'Declined';
        sp3.Participant__c = participantData2.Id;
        sp3.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sp3.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sessionParticipantList.add(sp3);
        
        Test.startTest();
        insert sessionParticipantList;
        
        Session_Participant__c spUpdated = [SELECT Id, Status__c FROM Session_Participant__c WHERE Status__c = 'Attended' LIMIT 1];
        spUpdated.Status__c = 'Confirmed';
        update spUpdated;
        Test.stopTest();
    }
    
    @isTest static void onBeforeUpdate() {
        Session__c session1 = [SELECT Id FROM Session__c WHERE Name ='Test Session 001' LIMIT 1];
        Event__c event1 = [SELECT Id FROM Event__c WHERE Name ='Test Event 001' LIMIT 1]; 
        Contact con1 = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact' LIMIT 1];
        
        List<Participant__c> participantDataList = new List<Participant__c>();
        Participant__c participantData = new Participant__c();
        participantData.Event__c = event1.Id;
        participantData.Member_Contact__c = con1.Id;
        participantData.Status__c = 'Registered';
        participantDataList.add(participantData);
        
        Participant__c participantData2 = new Participant__c();
        participantData2.Event__c = event1.Id;
        participantData2.Member_Contact__c = con1.Id;
        participantData2.Status__c = 'Registered';
        participantDataList.add(participantData2);
        insert participantDataList;
        
        //Session Participant
        List<Session_Participant__c> sessionParticipantList = new List<Session_Participant__c>();
        Session_Participant__c sp = new Session_Participant__c();
        sp.Session__c = session1.Id;
		sp.Event__c = event1.Id;
		sp.Contact__c = con1.Id;
        sp.Status__c = 'Attended';
        sp.Participant__c = participantData.Id;
        sp.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sp.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sessionParticipantList.add(sp);
        
        Test.startTest();
        insert sessionParticipantList;
        
        Session_Participant__c spUpdated = [SELECT Id, Status__c FROM Session_Participant__c WHERE Status__c = 'Attended' LIMIT 1];
        spUpdated.Status__c = 'Declined';
        update spUpdated;
        Test.stopTest();
    }
    
    @isTest static void returnTrigger() {
        Session__c session1 = [SELECT Id FROM Session__c WHERE Name ='Test Session 001' LIMIT 1];
        Event__c event1 = [SELECT Id FROM Event__c WHERE Name ='Test Event 001' LIMIT 1]; 
        Contact con1 = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact' LIMIT 1];
        
        Participant__c participantData = new Participant__c();
        participantData.Event__c = event1.Id;
        participantData.Member_Contact__c = con1.Id;
        participantData.Status__c = 'Registered';
        insert participantData;
        
        Apex_Trigger_Switch__c aps_sp = [SELECT Id, Active__c FROM Apex_Trigger_Switch__c WHERE Name = 'SessionParticipantTrigger'];
        aps_sp.Active__c = false;

        Session_Participant__c sp = new Session_Participant__c();
        sp.Session__c = session1.Id;
		sp.Event__c = event1.Id;
		sp.Contact__c = con1.Id;
        sp.Status__c = 'Attended';
        sp.Participant__c = participantData.Id;
        sp.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sp.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        
        Test.startTest();
        update aps_sp;
        insert sp;
        
        Test.stopTest();
    }
    
}