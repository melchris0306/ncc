@isTest 
private with sharing class CCEHeroControllerTest {
    
    @isTest private static void getEventDetailsMethod(){
        
        // Setup test data
        // Create a unique UserName
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg45.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);
        insert u;
        
        Account newAccount = new Account();
        newAccount.Name = 'Location';
        newAccount.BillingStreet = '222 Lonsdale Street';
        newAccount.BillingCity = 'Melbourne';
        newAccount.BillingPostalCode = '3000';
        newAccount.BillingState = 'VIC';
        newAccount.BillingCountry = 'Australia';
        insert newAccount;
        
        system.debug('--- newAccount ' + newAccount);

		
        Campaign campaignRecord = new Campaign();
        campaignRecord.Event_Id__c = 'kkjdu34301';
        campaignRecord.Name= 'Evendra123';
        campaignRecord.Subtitle__c= 'Evendra123';
        campaignRecord.Hero_Image_URL__c= 'https://www.google.com';
        campaignRecord.Campaign_Logo_URL__c= 'https://www.google.com';
        campaignRecord.Description__c= 'Evendra123';
        campaignRecord.Contact_Us_Tag_Line__c= 'Evendra123';
        campaignRecord.Contact_Us_Message__c= 'Evendra123';
        campaignRecord.Location__c = newAccount.Id;
        campaignRecord.Start_Date_Time__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        campaignRecord.End_Date_Time__c = DateTime.newInstance(2020, 08, 29, 18, 30, 0);
        //campaignRecord.Contact_Us_User__c = u.Id;
        campaignRecord.OwnerId = u.Id;
        System.runAs(u) {
            insert campaignRecord;
        }
        system.debug('--- campaignRecord ' + campaignRecord);
        
        Campaign campaignRecord2 =  [SELECT 	Name,
                                     Subtitle__c,
                                     Event_Id__c,
                                     OwnerId
                                     FROM Campaign WHERE Id =:campaignRecord.Id];
        
        system.debug('--- campaignRecord2 ' + campaignRecord2);
        
        Campaign__c camp = new Campaign__c();
        camp.Name = 'Camp 1';
        insert camp;  
        
        Compass_Setting__c comp = TestDataFactory.createCSData(1);
        insert comp;
        
        Event__c eventRecord = new Event__c();
        eventRecord.Name= 'Evendra123';
        //eventRecord.Subtitle__c= 'Evendra123';
        eventRecord.Hero_Image_URL__c= 'https://www.google.com';
        eventRecord.Campaign_Logo_URL__c= 'https://www.google.com';
        eventRecord.Description__c= 'Evendra123';
        eventRecord.Contact_Us_Tag_Line__c= 'Evendra123';
        eventRecord.Contact_Us_Message__c= 'Evendra123';
        eventRecord.Location__c = newAccount.Id;
        eventRecord.Start_Date_Time__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        eventRecord.End_Date_Time__c = DateTime.newInstance(2020, 08, 29, 18, 30, 0);
        eventRecord.OwnerId = u.Id;
        eventRecord.Campaign__c = camp.Id;         
        eventRecord.Time_Zone__c = 'EDT'; 
        insert eventRecord; 
        
		Event__c event = [Select Event_Id__c From Event__c Where Id =: eventRecord.Id];        
        
         
        Test.startTest();
        try{
            CCEHeroController.getEventDetails(campaignRecord2.Event_Id__c);
        }
        catch(exception e){}
        try{
            CCEHeroController.getEventDetails(event.Event_Id__c);
        }
        catch(exception e){}
        Test.stopTest();
    }
    
    @isTest private static void getEventSessionMethod(){
        
        Account newAccount = new Account();
        newAccount.Name = 'Location';
        newAccount.BillingStreet = '222 Lonsdale Street';
        newAccount.BillingCity = 'Melbourne';
        newAccount.BillingPostalCode = '3000';
        newAccount.BillingState = 'VIC';
        newAccount.BillingCountry = 'Australia';
        insert newAccount;
        
        system.debug('--- newAccount ' + newAccount);
        
        Campaign campaignRecord = new Campaign();
        campaignRecord.Event_Id__c = 'kkjdu34304';
        campaignRecord.Name= 'Evendra123';
        campaignRecord.Subtitle__c= 'Evendra123';
        campaignRecord.Hero_Image_URL__c= 'https://www.google.com';
        campaignRecord.Campaign_Logo_URL__c= 'https://www.google.com';
        campaignRecord.Description__c= 'Evendra123';
        campaignRecord.Contact_Us_Tag_Line__c= 'Evendra123';
        campaignRecord.Contact_Us_Message__c= 'Evendra123';
        campaignRecord.Location__c = newAccount.Id;
        campaignRecord.Start_Date_Time__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        campaignRecord.End_Date_Time__c = DateTime.newInstance(2020, 08, 29, 18, 30, 0);
        insert campaignRecord;
        
        Campaign campaignRecord2 =  [SELECT 	Name,
                                     Subtitle__c,
                                     Event_Id__c
                                     FROM Campaign WHERE Id =:campaignRecord.Id];
        
        Campaign campaignRecord3 = new Campaign();
        campaignRecord3.Event_Id__c = 'kkjdu34305';
        campaignRecord3.ParentId = campaignRecord.Id;
        campaignRecord3.Name= 'Evendra123';
        campaignRecord3.Subtitle__c= 'Evendra123';
        campaignRecord3.Hero_Image_URL__c= 'https://www.google.com';
        campaignRecord3.Campaign_Logo_URL__c= 'https://www.google.com';
        campaignRecord3.Description__c= 'Evendra123';
        campaignRecord3.Contact_Us_Tag_Line__c= 'Evendra123';
        campaignRecord3.Contact_Us_Message__c= 'Evendra123';
        campaignRecord3.Location__c = newAccount.Id;
        campaignRecord3.Start_Date_Time__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        campaignRecord3.End_Date_Time__c = DateTime.newInstance(2020, 08, 29, 18, 30, 0);
        insert campaignRecord3;
        
        Test.startTest();
        CCEHeroController.getEventSession(campaignRecord2.Event_Id__c);
        Test.stopTest(); 
        System.assertNotEquals(CCEHeroController.getEventSession(campaignRecord2.Event_Id__c), null);
    }
    @isTest private static void getSpeakerDetailsMethod(){
        
        Account newAccount = new Account();
        newAccount.Name = 'Location';
        newAccount.BillingStreet = '222 Lonsdale Street';
        newAccount.BillingCity = 'Melbourne';
        newAccount.BillingPostalCode = '3000';
        newAccount.BillingState = 'VIC';
        newAccount.BillingCountry = 'Australia';
        insert newAccount;
        
        Contact newContact = new Contact();
        newContact.FirstName = 'Joe';
        newContact.LastName = 'Joe';
        insert newContact;
        
        
        
        Campaign campaignRecord = new Campaign();
        campaignRecord.Event_Id__c = 'kkjdu34302';
        campaignRecord.Name= 'Evendra123';
        campaignRecord.Subtitle__c= 'Evendra123';
        campaignRecord.Hero_Image_URL__c= 'https://www.google.com';
        campaignRecord.Campaign_Logo_URL__c= 'https://www.google.com';
        campaignRecord.Description__c= 'Evendra123';
        campaignRecord.Contact_Us_Tag_Line__c= 'Evendra123';
        campaignRecord.Contact_Us_Message__c= 'Evendra123';
        campaignRecord.Location__c = newAccount.Id;
        campaignRecord.Start_Date_Time__c = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        campaignRecord.End_Date_Time__c = DateTime.newInstance(2020, 08, 29, 18, 30, 0);
        insert campaignRecord;
        
        
        Event_Role__c newEventRole = new Event_Role__c();
        newEventRole.Show_in_Event_Site__c = true;
        newEventRole.Role__c = 'Speaker';
        newEventRole.Contact__c = newContact.Id;
        newEventRole.Campaign__c = campaignRecord.Id ;
        insert newEventRole;
        
        Campaign campaignRecord2 =  [SELECT 	Name,
                                     Subtitle__c,
                                     Event_Id__c
                                     FROM Campaign WHERE Id =:campaignRecord.Id];
        
        
        Test.startTest();
        CCEHeroController.getSpeakerDetails(campaignRecord2.Event_Id__c);
        Test.stopTest(); 
        System.assertNotEquals(CCEHeroController.getSpeakerDetails(campaignRecord2.Event_Id__c), null);
    }
    
}