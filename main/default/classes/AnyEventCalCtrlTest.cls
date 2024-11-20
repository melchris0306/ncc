@isTest
public class AnyEventCalCtrlTest {
    
   @testSetup static void setup() {
        // Create common test records
        Apex_Trigger_Switch__c eventSwitch = new Apex_Trigger_Switch__c();
        eventSwitch.Name = 'EventTrigger';
        eventSwitch.active__c = true;
        insert eventSwitch;
       	Account acc = new Account(Name ='Test Acc');
       insert acc;
      	Campaign__c camp = new Campaign__c(Name='Test Name', Account__c = acc.Id);
      	insert camp;
       	Event__c evnt = new Event__c(Name='Test Name', IsActive__c=true,Campaign__c=camp.Id, Start_Date_Time__c = DateTime.now(), End_Date_Time__c=DateTime.now().AddDays(1), Time_Zone__c='ET');
      	insert evnt;
       	Session__c session1 = new Session__c(Name='Test Name',IsActive__c=true,Start_Date_Time__c = DateTime.now(), End_Date_Time__c=DateTime.now().AddDays(1), Event__c=evnt.Id, Time_Zone__c='ET');
      	insert session1;
    }
  static testMethod void getEventsTest() {
      
      	Session__c session1 = [SELECT Id, Event__r.Event_Id__c FROM Session__c LIMIT 1];
  
      	String eventId = String.valueOf(session1.Event__r.Event_Id__c);
      	SObject session3 = [SELECT Id, Event__r.Event_Id__c FROM Session__c WHERE Event__r.Event_Id__c =:eventId];
      	System.Debug('!@#$%session3 : '+session3);
        List<String> sessionId = new List<String>();
        AnyEventCalCtrl.getEvents('Session__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById', false, eventId, sessionId);
        AnyEventCalCtrl.getEvents('Session__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById', true, eventId, sessionId);
      	System.assert(session3 != null);
    }
    static testMethod void upsertEventsTest() {
        Session__c session1 = [SELECT Id, Event__r.Event_Id__c FROM Session__c LIMIT 1];
        AnyEventCalCtrl.upsertEvents('{"id":'+'"'+String.valueOf(session1.Id)+'"'+',"title":"dasdsad","startDateTime":"2017-04-26T17:00:00-07:00","endDateTime":"2017-04-26T19:00:00-07:00","description":"asdasd"}', 'Session__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById');
    	AnyEventCalCtrl.upsertEvents('{"id":'+'"'+String.valueOf(session1.Id)+'"'+',"title":"dasdsad","startDateTime":"2017-04-26T17:00:00-07:00","endDateTime":"2017-04-26T19:00:00-07:00","description":"asdasd"}', 'Session__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById');
    	System.assert(session1 != null);
    }
    static TestMethod void getRecIdTest(){
        Session__c session1 = [SELECT Id, Event__c, Event__r.Event_Id__c FROM Session__c LIMIT 1];
        String eventId = AnyEventCalCtrl.getRecId(session1.Event__r.Event_Id__c);
        System.assertEquals(eventId, session1.Event__c);
    }
    static TestMethod void insertSessionTest(){
        Session__c session1 = [SELECT Id, Event__c, Event__r.Event_Id__c FROM Session__c LIMIT 1];
        AnyEventCalCtrl.insertSession('{"id":'+'"'+String.valueOf(session1.Id)+'"'+',"title":"dasdsad","startDateTime":"2017-04-26T17:00:00-07:00","endDateTime":"2017-04-26T19:00:00-07:00","description":"asdasd"}', 'Session__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById', session1.Event__c);
    	AnyEventCalCtrl.insertSession('{"id":'+'"'+String.valueOf(session1.Id)+'"'+',"title":"dasdsad","startDateTime":"2017-04-26T17:00:00-07:00","endDateTime":"2017-04-26T19:00:00-07:00","description":"asdasd"}', 'Session__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById', null);
    }
    static testMethod void deleteEventTest() {
        Session__c session1 = [SELECT Id, Event__c, Event__r.Event_Id__c FROM Session__c LIMIT 1];
        AnyEventCalCtrl.deleteEvent(session1.Id, 'Session__c', 'Name', 'Start_Date_Time__c', 'End_Date_Time__c', 'Session_Details__c', 'CreatedById');
        Session__c session2 = [SELECT Id, Event__c, Event__r.Event_Id__c FROM Session__c WHERE Id=:session1.Id LIMIT 1];
        System.assert(session1 != null);
    }
    static testMethod void crudSecurityTest() {
        AnyEventCalCtrl.isAccessible('Event__c');
        AnyEventCalCtrl.isAccessible('Event__c','Name');
        AnyEventCalCtrl.isCreateable('Event__c');
        AnyEventCalCtrl.isDeletable('Event__c');
        System.assert(AnyEventCalCtrl.isAccessible('Event__c') == true);
    }
}