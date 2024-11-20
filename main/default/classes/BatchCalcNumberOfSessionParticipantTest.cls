@isTest
public class BatchCalcNumberOfSessionParticipantTest {
    @isTest
    public static void testBatch(){
        
        Contact con1 = new Contact();
        con1.FirstName = 'Test Contact';
        con1.LastName = 'Record 1';
        con1.Email = 'testemail@testemail.com';
        insert con1;
	
	Apex_Trigger_Switch__c aps_c2 = new Apex_Trigger_Switch__c();
        aps_c2.Name = 'SessionTrigger';
        aps_c2.Active__c = true;
        insert aps_c2;
        
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
        eventList.add(event1);
        
        Event__c event2 = new Event__c();
        event2.Campaign__c = camp1.Id;
        event2.Name = 'Test Event 002';
        event2.Milestone__c = true;
        event2.IsActive__c = true;
        event2.Start_Date_Time__c = system.today();
        event2.End_Date_Time__c = system.today() + 1;
         event2.Time_Zone__c = 'AKDT';
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
        session1.Start_Date_Time__c = DateTime.newInstance(2020, 08, 29, 9, 31, 0);
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
        sp.Status__c = 'Registered';
        sp.Invitation_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sp.Registration_Date__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        sessionParticipantList.add(sp);
        
        insert sessionParticipantList;
        
        BatchCalculateNumberOfSessionParticipant BatchCalculateNumberOfSessionParticipant = new BatchCalculateNumberOfSessionParticipant();
        Id batchId = Database.executeBatch(BatchCalculateNumberOfSessionParticipant);
    }
}