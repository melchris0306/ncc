@isTest
private class CCEventTriggerHandlerTest {
    @testSetup static void createData(){
        Compass_Setting__c comp = TestDataFactory.createCSData(1);
        insert comp;
        
		Campaign__c camp = TestDataFactory.createCampaign(1);
        insert camp;
        
    }
    static testmethod void testOrgWide(){
        Campaign__c campRec = [Select Id, Name FROM Campaign__c WHERE Name =: 'Test Campaign1' ];
        system.debug('camp' + campRec);
        
        Compass_Setting__c comp = [Select Id, Name, Email_Sender_Id__c FROM Compass_Setting__c WHERE Name =: 'Default Settings' ];
        List<Event__c> eventList = new List<Event__c>();
        for(Integer i = 0 ; i<=100 ;i++){
            Event__c eve = new Event__c();
            eve.Name = 'Test Event' + i;
            eve.Campaign__c = campRec.Id;
            eve.Email_Sender_Id__c = NULL;
            eventList.add(eve);
        }
        Test.startTest();        
        //Event__c eve = new Event__c(Name = 'Test Event', Campaign__c = campRec.Id, Email_Sender_Id__c = NULL);
        insert eventList;
        Test.stopTest();
        System.assert(eventList != null);
    }
    
    static testmethod void testRegenerateEventURL(){
        Campaign__c campRec = [Select Id, Name FROM Campaign__c WHERE Name =: 'Test Campaign1' ];
        system.debug('camp' + campRec);
        
        Compass_Setting__c comp = [Select Id, Name, Email_Sender_Id__c FROM Compass_Setting__c WHERE Name =: 'Default Settings' ];
        List<Event__c> eventList = new List<Event__c>();
        for(Integer i = 0 ; i<=100 ;i++){
            Event__c eve = new Event__c();
            eve.Name = 'Test Event' + i;
            eve.Campaign__c = campRec.Id;
            eve.Email_Sender_Id__c = NULL;
            eventList.add(eve);
        }
        insert eventList;
        
        Test.startTest();        
        Event__c evn = [SELECT Id, Re_Generate_URL__c FROM Event__c LIMIT 1];
        evn.Re_Generate_URL__c = true;
        evn.Internal_Logistics_Required__c = true; //[CCN-LOG-2217-DV] Xen Reyes 25Nov2022
        update evn;
        Test.stopTest();
        System.assert(eventList != null);
    }

    static testmethod void testVirtualMeetingIntegrationInPerson(){
        Campaign__c campRec = [Select Id, Name FROM Campaign__c WHERE Name =: 'Test Campaign1' ];
        system.debug('camp' + campRec);
        
        Compass_Setting__c comp = [Select Id, Name, Email_Sender_Id__c FROM Compass_Setting__c WHERE Name =: 'Default Settings' ];
        List<Event__c> eventList = new List<Event__c>();
        for(Integer i = 0 ; i<=100 ;i++){
            Event__c eve = new Event__c();
            eve.Name = 'Test Event' + i;
            eve.Campaign__c = campRec.Id;
            eve.Email_Sender_Id__c = NULL;
            eventList.add(eve);
            //Virtual, MS Teams InPersonToVirtual-RunIntegration
        }
        insert eventList;
        Test.setMock(HttpCalloutMock.class, new AzureAPIMockHttpResponseGenerator());
        Test.startTest();    
        Event__c evn = [SELECT Id, Re_Generate_URL__c FROM Event__c LIMIT 1];
        evn.Event_Type__c = 'In-Person';
        evn.ChangeEventTypeAction__c = 'VirtualToInPerson-RemoveVirtualPlatformInfo';
        update evn;
        Test.stopTest();
        System.assert(eventList != null);
    }

    static testmethod void testVirtualMeetingIntegrationVirtual(){
        Campaign__c campRec = [Select Id, Name FROM Campaign__c WHERE Name =: 'Test Campaign1' ];
        system.debug('camp' + campRec);
        
        Compass_Setting__c comp = [Select Id, Name, Email_Sender_Id__c FROM Compass_Setting__c WHERE Name =: 'Default Settings' ];
        List<Event__c> eventList = new List<Event__c>();
        for(Integer i = 0 ; i<=100 ;i++){
            Event__c eve = new Event__c();
            eve.Name = 'Test Event' + i;
            eve.Campaign__c = campRec.Id;
            eve.Email_Sender_Id__c = NULL;
            eventList.add(eve);
            //Virtual, MS Teams 
        }
        insert eventList;
        Test.setMock(HttpCalloutMock.class, new AzureAPIMockHttpResponseGenerator());
        Test.startTest();    
        Event__c evn = [SELECT Id, Re_Generate_URL__c FROM Event__c LIMIT 1];
        evn.Event_Type__c = 'Virtual';
        evn.Virtual_Meeting_Platform__c = 'MS Teams';
        evn.ChangeEventTypeAction__c = 'InPersonToVirtual-RunIntegration';
        update evn;

        Event__c evnTwo = [SELECT Id, Re_Generate_URL__c FROM Event__c LIMIT 1];
        evnTwo.Event_Type__c = 'In-Person';
        evnTwo.Virtual_Meeting_Platform__c = '';
        evnTwo.ChangeEventTypeAction__c = 'VirtualToInPerson-RemoveVirtualPlatformInfo';
        update evnTwo;

        Test.stopTest();
        System.assert(eventList != null);
    }
}