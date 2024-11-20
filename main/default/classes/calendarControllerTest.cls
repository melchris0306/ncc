@isTest
public class calendarControllerTest {
    
   @testSetup static void setup() {
       
        EmailTemplate e = new EmailTemplate (DeveloperName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        System.runAs( new User(Id = UserInfo.getUserId())){
            insert e;
        }
       
       	Compass_Setting__c compSetting = new Compass_Setting__c();
        compSetting.Name = 'Default Settings';
        compSetting.Email_Sender_Id__c = '123';
        compSetting.Email_Sender_Name__c = 'NAME';
        compSetting.Email_Template_Invitation_Id__c = e.Id;
        compSetting.Email_Template_Registration_Id__c = e.Id;
        insert compSetting;
       
        // Create common test records
        Apex_Trigger_Switch__c eventSwitch = new Apex_Trigger_Switch__c();
        eventSwitch.Name = 'EventTrigger';
        eventSwitch.active__c = true;
        insert eventSwitch;
      	Campaign__c camp = new Campaign__c(Name='Test Name');
      	insert camp;
       	Event__c evnt = new Event__c(Name='Test Name', Time_Zone__c = 'PST', IsActive__c=true,Campaign__c=camp.Id, Start_Date_Time__c = DateTime.now(), End_Date_Time__c=DateTime.now().AddDays(1));
      	insert evnt;
       	Session__c session1 = new Session__c(Name='Test Name', Time_Zone__c = 'PST', Start_Date_Time__c = DateTime.now(), End_Date_Time__c=DateTime.now().AddDays(1), Event__c=evnt.Id);
      	insert session1;
       
        
       
   
    }
    static testMethod void getEventsTest() {
       Compass_Setting__c compassSetting = [SELECT Id, Domain_Name__c FROM Compass_Setting__c WHERE Name = 'Default Settings'
        LIMIT 1];
        
        System.debug('Gavvv ' + compassSetting);
      	Campaign__c campaign = [SELECT Id FROM Campaign__c LIMIT 1];
        calendarController.getEvents('Event__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById', false, campaign.Id, new List<String> {'Virtual', 'In-Person', 'Hybrid'});
        calendarController.getEvents('Event__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById', true, campaign.Id, new List<String> {'Virtual', 'In-Person', 'Hybrid'});
    	//CCN-1000 Modified by Rianno Rizarri Apr 15, 2022
        calendarController.getEventsExceptShowToLinks('Event__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById', false, campaign.Id, new List<String> {'Virtual', 'In-Person', 'Hybrid'}, new List<String> {'Test1', 'Test2', 'Test3'});
        calendarController.getEventsExceptShowToLinks('Event__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById', true, campaign.Id, new List<String> {'Virtual', 'In-Person', 'Hybrid'}, new List<String> {'Test1', 'Test2', 'Test3'});
        //CCN-1000 Modified by Rianno Rizarri Apr 15, 2022
    }
    static testMethod void upsertEventsTest() {
        Session__c session1 = [SELECT Id, Event__r.Event_Id__c FROM Session__c LIMIT 1];
        calendarController.upsertEvents('{"title":"Test Name","startDateTime":"2017-04-26T17:00:00-07:00","endDateTime":"2017-04-26T19:00:00-07:00","description":"asdasd"}', 'Session__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById');
    	calendarController.upsertEvents('{"id":'+'"'+String.valueOf(session1.Id)+'"'+',"title":"Test Name","startDateTime":"2017-04-26T17:00:00-07:00","endDateTime":"2017-04-26T19:00:00-07:00","description":"asdasd"}', 'Session__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById');
        calendarController.getEventTypes();
    	System.assert(session1 != null);
    }
    static TestMethod void getRecIdTest(){
        Session__c session1 = [SELECT Id, Event__c, Event__r.Event_Id__c FROM Session__c LIMIT 1];
        String eventId = calendarController.getRecId(session1.Event__r.Event_Id__c);
        System.assertEquals(eventId, session1.Event__c);
    }
    static TestMethod void insertSessionTest(){
        Session__c session1 = [SELECT Id, Event__c, Event__r.Event_Id__c FROM Session__c LIMIT 1];
        calendarController.insertSession('{"id":'+'"'+String.valueOf(session1.Id)+'"'+',"title":"dasdsad","startDateTime":"2017-04-26T17:00:00-07:00","endDateTime":"2017-04-26T19:00:00-07:00","description":"asdasd"}', 'Session__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById', session1.Event__c);
    	calendarController.insertSession('{"id":'+'"'+String.valueOf(session1.Id)+'"'+',"title":"dasdsad","startDateTime":"2017-04-26T17:00:00-07:00","endDateTime":"2017-04-26T19:00:00-07:00","description":"asdasd"}', 'Session__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById', null);
    	Session__c session2 = [SELECT Id, Event__c, Event__r.Event_Id__c FROM Session__c WHERE Name = 'Test Name'  LIMIT 1];
        System.assert(session2 != null);
    }
    static testMethod void deleteEventTest() {
        Session__c session1 = [SELECT Id, Event__c, Event__r.Event_Id__c FROM Session__c LIMIT 1];
        calendarController.deleteEvent(session1.Id, 'Session__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById');
        Session__c session2 = [SELECT Id, Event__c, Event__r.Event_Id__c FROM Session__c WHERE Id=:session1.Id LIMIT 1];
        System.assert(session1 != null);
    }
    static testMethod void crudSecurityTest() {
        calendarController.isAccessible('Event__c');
        calendarController.isAccessible('Event__c','Name');
        calendarController.isCreateable('Event__c');
        calendarController.isDeletable('Event__c');
        System.assert(calendarController.isAccessible('Event__c') == true);
    }
}