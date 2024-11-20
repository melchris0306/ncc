@isTest
public class RelatedListControllerTest {

    @testSetup static void setup() {
        // Create common test records
        Apex_Trigger_Switch__c eventSwitch = new Apex_Trigger_Switch__c();
        eventSwitch.Name = 'EventTrigger';
        eventSwitch.active__c = true;
        insert eventSwitch;
      	Campaign__c camp = new Campaign__c(Name='Test Name');
      	insert camp;
       	Event__c evnt = new Event__c(Name='Test Name', IsActive__c=true,Campaign__c=camp.Id, Start_Date_Time__c = DateTime.now(), End_Date_Time__c=DateTime.now().AddDays(1), Time_Zone__c='ET');
      	insert evnt;
       	
    }
    
    static testMethod void getDataTest() {
        RelatedListController.dataWrapper dWrapper = New RelatedListController.dataWrapper();
        Id evntId = [SELECT Id FROM Event__c  LIMIT 1].Id;
        
        Session__c session1 = new Session__c(Name='Test Name',IsActive__c=true,Start_Date_Time__c = DateTime.now(), End_Date_Time__c=DateTime.now().AddDays(1), Event__c=evntId, Time_Zone__c='ET');
      	insert session1;
        
        Test.startTest();
        dWrapper = RelatedListController.getData(evntId);
        Test.stopTest();
        
        System.assertEquals(1, dWrapper.sessionList.size());
        
    }
    
    static testMethod void deleteRecTest() {
        
        Id evntId = [SELECT Id FROM Event__c  LIMIT 1].Id;
        
        Session__c session1 = new Session__c(Name='Test Name',IsActive__c=true,Start_Date_Time__c = DateTime.now(), End_Date_Time__c=DateTime.now().AddDays(1), Event__c=evntId, Time_Zone__c='ET');
      	insert session1;
        
        Test.startTest();
        List<Session__c> listSession = RelatedListController.deleteRec(evntId,session1.Id);
        Test.stopTest();
        
        System.assertEquals(0, listSession.size());
        
    }
    
    static testMethod void handleNameSpace() {
        RelatedListController.namespaceWrapper fieldWrapper = New RelatedListController.namespaceWrapper();
         Test.startTest();
        fieldWrapper = RelatedListController.handleNameSpace();
        Test.stopTest();
        System.assertEquals('Status__c', fieldWrapper.recStatus);
    }
}