@isTest
private class CampaignHierarchyPageTest {
    
    @testSetup
    static void testSetup() {
        //Campaign 
        Campaign__c camp1 = new Campaign__c();
        camp1.Name = 'Test Campaign 001';
        
        insert camp1;
        
        Compass_Setting__c comp = TestDataFactory.createCSData(1);
        insert comp;
        //Event
        List<Event__c> eventList = new List<Event__c>();
        Event__c event1 = new Event__c();
        event1.Name = 'Test Event 001';
        event1.Campaign__c = camp1.Id;
        eventList.add(event1);
        
        Event__c event2 = new Event__c();
        event2.Name = 'Test Event 002';
        event2.Campaign__c = camp1.Id;
        eventList.add(event2);

        insert eventList;
        
        //Session
        List<Session__c> sessionList = new List<Session__c>();
        Session__c session1 = new Session__c();
        session1.Name = 'Test Session 001';
        session1.Event__c = event1.Id;
        sessionList.add(session1);
        
        Session__c session2 = new Session__c();
        session2.Name = 'Test Session 002';
        session2.Event__c = event2.Id;
        sessionList.add(session2);
        
        insert sessionList;
    }
    
    @isTest
    static void checkObjectTypeTest(){
        Campaign__c camp = [SELECT Id FROM Campaign__c LIMIT 1];
        String objectType;

        Test.startTest();
        objectType = CampaignHierarchyPage.objectType(camp.Id);
        Test.stopTest();

        System.assertNotEquals(null, objectType, 'objectType not found');
    }
    
    @isTest
    static void searchForCampaignTest(){
        Campaign__c camp = [SELECT Id FROM Campaign__c LIMIT 1];
        List<Campaign__c> campList = new List<Campaign__c>();

        Test.startTest();
        
            campList = CampaignHierarchyPage.searchForCampaign(camp.Id);
        
        Test.stopTest();
        System.assert(!campList.isEmpty(), 'No campList');
    }
    
    @isTest
    static void searchForEventTest(){
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];
        List<Event__c> eventList = new List<Event__c>();

        Test.startTest();
        eventList = CampaignHierarchyPage.searchForEvent(event.Id);
        Test.stopTest();

        System.assert(!eventList.isEmpty(), 'no eventList');
    }
    
    @isTest
    static void searchForEventTest2(){
        Campaign__c campaign = [SELECT Id FROM Campaign__c LIMIT 1];
        List<Event__c> eventList = new List<Event__c>();

        Test.startTest();
        eventList = CampaignHierarchyPage.searchForEvent(campaign.Id);
        Test.stopTest();

        System.assert(!eventList.isEmpty(), 'no campaignList');
    }
    
    @isTest
    static void searchForSessionTest(){
        Event__c event = [SELECT Id FROM Event__c LIMIT 1];
        List<Session__c> sessionList;

        Test.startTest();
        sessionList = CampaignHierarchyPage.searchForSession(new List<Id>{event.Id}, null);
        Test.stopTest();

        System.assert(!sessionList.isEmpty(), 'no eventsessionList');
    }
    
    @isTest
    static void searchForSessionTest2(){
        Session__c session = [SELECT Id FROM Session__c LIMIT 1];
        List<Session__c> sessionList;

        Test.startTest();
        sessionList = CampaignHierarchyPage.searchForSession(new List<Id>(), session.Id);
        Test.stopTest();

        System.assert(!sessionList.isEmpty(), 'no sessionList');
    }
}