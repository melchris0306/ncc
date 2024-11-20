@isTest
public with sharing class OrgWideAddressControllerTest {
    @testSetup static void createData(){
        Compass_Setting__c comp = TestDataFactory.createCSData(1);
        insert comp;
        
        Campaign__c camp = TestDataFactory.createCampaign(1);
        insert camp;
        system.debug('camp' + camp);
        
        
        List<Apex_Trigger_Switch__c> switchRecs = TestDataFactory.createAllTriggerSwitch();
        insert switchRecs;
    }
    @isTest static void testController(){
        List<Compass_Setting__c> compSum = new List<Compass_Setting__c>();
        Compass_Setting__c compRec = [Select Id, Name FROM Compass_Setting__c WHERE Name =: 'Default Settings'];
        //compSum.add(compRec);
        //insert compSum;
        
        Test.StartTest(); 
        PageReference pageRef = Page.OrgWideAddressPage; 
        //pageRef.getParameters().put('id', String.valueOf(compRec.Id));
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('Id', String.valueOf(compRec.Id));

        ApexPages.StandardController sc = new ApexPages.StandardController(compRec);
        OrgWideAddressController oc = new OrgWideAddressController(sc);
        
        OrgWideEmailAddress[] addresses = [SELECT Id, Address FROM OrgWideEmailAddress LIMIT 1];
        System.assertEquals(1, addresses.size());
        
		oc.getSelectedOrgWideAddress();

        oc.save();
        Test.StopTest();

        
    }
    @isTest static void eventOrgWideTest(){
        Campaign__c campRec = [Select Id, Name FROM Campaign__c WHERE Name =: 'Test Campaign1' ];

		Event__c eve = new Event__c(Name = 'Event 1', Campaign__c = campRec.Id);      
        insert eve;
        Test.StartTest(); 
        PageReference pageRef = Page.OrgWideAddressEventPage; 
        //pageRef.getParameters().put('id', String.valueOf(compRec.Id));
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('Id', String.valueOf(eve.Id));
        
        ApexPages.StandardController sc = new ApexPages.StandardController(eve);
        OrgWideAddressEventController oc = new OrgWideAddressEventController(sc);
        
        OrgWideEmailAddress[] addresses = [SELECT Id, Address FROM OrgWideEmailAddress LIMIT 1];
        System.assertEquals(1, addresses.size());
      
        oc.getSelectedOrgWideAddress();
        
        oc.save();
        Test.StopTest();
        
        
    }
}