@isTest
public with sharing class CustomContactSupportFormTest {
    @testSetup static void createData() {

        Compass_Setting__c compassSetting = new Compass_Setting__c();
        compassSetting.Name = 'Default Settings';
        compassSetting.Email_Sender_Name__c = 'Test Sender';
        insert compassSetting;
        
        List<Apex_Trigger_Switch__c> switchRecs = TestDataFactory.createAllTriggerSwitch();
        insert switchRecs;
    }
    // Test create task with missing data
    @isTest public static void testCreateTaskMissingData(){
        Test.startTest();
        String eventId = '';
        String firstname = 'CS';
        String lastname = 'User';
        String email = 'cs.user@gmail.com';
        String subject = 'Test Task';
        String comments = 'Lorem ipsum';
        String phone = '';
        CCEHeroController.createTask(eventId, firstname, lastname, email, phone, subject, comments);
        Test.stopTest();
        List<Task> resultTasks = [SELECT Id FROM Task];
        System.assertEquals(0, resultTasks.size());
    }
    
    // Test creating task with new contact created and no contact us user specified on event
    /*@isTest public static void testCreateTaskContactNotExistNoContactUsUser(){
        Campaign testCampaign = TestFactory.createCampaign('Test Campaign', 'Event');
        testCampaign.Event_Id__c = 'sfjzu42308xlz';
        update testCampaign;
        String firstname = 'New';
        String lastname = 'Contact';
        String email = 'new.contact@gmail.com';
        String phone = '0123456789';
        String subject = 'Test Task 0001';
        String comments = 'Lorem Ipsum';
        
        Test.startTest();
        CCEHeroController.createTask(testCampaign.Event_Id__c, firstname, lastname, email, phone, subject, comments);
        Test.stopTest();
        
        Campaign resultCampaign = [SELECT Id, Contact_Us_User__c, OwnerId FROM Campaign WHERE Event_Id__c = 'sfjzu42308xlz'][0];
        Task resultTask = [SELECT Id, Subject, Description, ActivityDate, OwnerId, WhatId, WhoId, Type, Task_Origin__c FROM Task WHERE WhatId =: resultCampaign.Id];
        Contact resultContact = [SELECT Id, Firstname, Lastname, Email, Phone FROM Contact WHERE Email =: email];
        
        System.assertNotEquals(null, resultCampaign);
        
        System.assertNotEquals(null, resultContact);
        System.assertEquals(firstname, resultContact.FirstName);
        System.assertEquals(lastname, resultContact.Lastname);
        System.assertEquals(email, resultContact.Email);
        System.assertEquals(phone, resultContact.Phone);
        
        System.assertNotEquals(null, resultTask);
        System.assertEquals(subject, resultTask.Subject);
        System.assertEquals(comments, resultTask.Description);
        System.assertEquals(System.today(), resultTask.ActivityDate);
        System.assertEquals(resultCampaign.OwnerId, resultTask.OwnerId);
        System.assertEquals(resultCampaign.Id, resultTask.WhatId);
        System.assertEquals(resultContact.Id, resultTask.WhoId);
        System.assertEquals('Email', resultTask.Type);
        System.assertEquals('Contact Us Page', resultTask.Task_Origin__c);
        }
        
        
        // Test creating task with existing contact created and no contact us user specified on event
        @isTest public static void testCreateTaskContactExistWithContactUsUser(){
        User contactUsUser = TestFactory.createInteralUser('ContactUs', 'User', 'contactus@gmail.com', 'System Administrator');
        Campaign testCampaign = TestFactory.createCampaign('Test Campaign', 'Event');
        testCampaign.Event_Id__c = 'sfjzu42308xlz';
        testCampaign.Contact_Us_User__c = contactUsUser.Id;
        update testCampaign;
        
        String firstname = 'Existing';
        String lastname = 'Contact';
        String email = 'existing.contact@gmail.com';
        String phone = '0123456789';
        String subject = 'Test Task 0002';
        String comments = 'Lorem Ipsum';
        
        Account existingPersonAccount = TestFactory.createPersonAccount(firstname, lastname, email);
        existingPersonAccount.Phone = phone;
        update existingPersonAccount;
        
        Test.startTest();
        CCEHeroController.createTask(testCampaign.Event_Id__c, firstname, lastname, email, phone, subject, comments);
        Test.stopTest();
        
        Campaign resultCampaign = [SELECT Id, Contact_Us_User__c, OwnerId FROM Campaign WHERE Event_Id__c = 'sfjzu42308xlz'][0];
        Task resultTask = [SELECT Id, Subject, Description, ActivityDate, OwnerId, WhatId, WhoId, Type, Task_Origin__c FROM Task WHERE WhatId =: resultCampaign.Id];
        Contact resultContact = [SELECT Id, Firstname, Lastname, Email, Phone FROM Contact WHERE Email =: email];
        
        System.assertNotEquals(null, resultCampaign);
        
        System.assertNotEquals(null, resultContact);
        System.assertEquals(firstname, resultContact.FirstName);
        System.assertEquals(lastname, resultContact.Lastname);
        System.assertEquals(email, resultContact.Email);
        System.assertEquals(phone, resultContact.Phone);
        
        System.assertNotEquals(null, resultTask);
        System.assertEquals(subject, resultTask.Subject);
        System.assertEquals(comments, resultTask.Description);
        System.assertEquals(System.today(), resultTask.ActivityDate);
        System.assertEquals(resultCampaign.Contact_Us_User__c, resultTask.OwnerId);
        System.assertEquals(resultCampaign.Id, resultTask.WhatId);
        System.assertEquals(resultContact.Id, resultTask.WhoId);
        System.assertEquals('Email', resultTask.Type);
        System.assertEquals('Contact Us Page', resultTask.Task_Origin__c);
    }*/
    
    
    // Test creating task with exception thrown
    @isTest public static void testCreateTaskFakeTaskExceptionThrown(){
        Campaign testCampaign = TestFactory.createCampaign('Test Campaign', 'Event');
        testCampaign.Event_Id__c = 'sfjzu42308xlz';
        update testCampaign;
        String firstname = 'New';
        String lastname = 'Contact';
        String email = 'new.contact@gmail.com';
        String phone = '0123456789';
        String subject = 'Test Task 0001';
        String comments = 'Lorem Ipsum';
        
        Test.startTest();
        CustomContactSupportFormHelper.throwFakeTaskException = true;      
        try{
            CCEHeroController.createTask(testCampaign.Event_Id__c, firstname, lastname, email, phone, subject, comments);
        } catch(Exception e){
            System.assertNotEquals(null, e);
        }
        Test.stopTest();
    }
    
    // Test creating task with exception thrown
    @isTest public static void testCreateTaskFakePersonAccountExceptionThrown(){
        //START [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021
        Event__c testCampaign = TestFactory.createEvent('Test Event');
        //Campaign testCampaign = TestFactory.createCampaign('Test Campaign', 'Event');
        //END [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021
        testCampaign.Event_Id__c = 'sfjzu42308xlz';
        update testCampaign;
        String firstname = 'New';
        String lastname = 'Contact';
        String email = 'new.contact@gmail.com';
        String phone = '0123456789';
        String subject = 'Test Task 0001';
        String comments = 'Lorem Ipsum';
        
        Test.startTest();
        CustomContactSupportFormHelper.throwFakePersonAccountException = true;      
        try{
            CCEHeroController.createTask(testCampaign.Event_Id__c, firstname, lastname, email, phone, subject, comments);
        } catch(Exception e){
            System.assertNotEquals(null, e);
        }
        Test.stopTest();
    }
    /*START [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021
    // Test getRecordID
    @isTest public static void testGetRecordId(){
    System.assertNotEquals(null, CustomContactSupportFormHelper.getRecordTypeId('Event', 'Campaign'));
    }
    END [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021*/
    
    // Test get event details
    @isTest public static void testGetEventDetails(){
        //START [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021
        Event__c testCampaign = TestFactory.createEvent('Test Event');
        //Campaign testCampaign = TestFactory.createCampaign('Test Campaign', 'Event');
        //END [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021
        testCampaign.Event_Id__c = 'sfjzu42308xlz';
        update testCampaign;
        Test.startTest();
        System.assertNotEquals(null, CustomContactSupportFormHelper.getEventDetails(testCampaign.Event_Id__c));
        Test.stopTest();
    }
    
    // Test check contact exists
    @isTest public static void testCheckContactExsist(){
        Contact cont = TestFactory.createContact('Test', 'Contact', 'test.contact@gmail.com');
        Test.startTest();
        CustomContactSupportFormHelper.checkContactExists('Test', 'Contact', 'test.contact@gmail.com', '0842341232');
        Test.stopTest();
        System.assertNotEquals(null, cont);
    }
    
    // Test create task
    @isTest public static void testCreateTask(){
        //User contactUsUser = TestFactory.createInteralUser('ContactUs', 'User', 'contactus@gmail.com', 'System Administrator');
        List<User> contactUsUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        //START [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021
        Event__c testCampaign = TestFactory.createEvent('Test Event');
        //Campaign testCampaign = TestFactory.createCampaign('Test Campaign', 'Event');
        //END [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021
        testCampaign.Event_Id__c = 'sfjzu42308xlz';
        testCampaign.Contact_Us_User__c = contactUsUser[0].Id;
        update testCampaign;
        System.debug('testCampaign: '+testCampaign);
        
        String firstname = 'Existing';
        String lastname = 'Contact';
        String email = 'existing.contact@gmail.com';
        String phone = '0123456789';
        String subject = 'Test Task 0002';
        String comments = 'Lorem Ipsum';
        Contact cont = TestFactory.createContact('Test', 'Contact', 'test.contact@gmail.com');
        Test.startTest();
        CustomContactSupportFormHelper.createTaskHelper(testCampaign.Event_Id__c, firstname, lastname, email, phone, subject, comments);
        Test.stopTest();
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId =: testCampaign.Id];
        System.assertNotEquals(0, tasks.size());
    }
    
    /*START [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021
    // Test create person account
    @isTest public static void testCreatePersonAccountPANotEnabled(){
    Test.startTest();
    System.assertNotEquals(null, CustomContactSupportFormHelper.createPersonAccount('Person', 'Account', 'person.account@gmail.com', '03123123'));
    Test.stopTest();
    }
    END [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021*/
    
    // Test create contact
    @isTest public static void testCreateContact(){
        Test.startTest();
        System.assertNotEquals(null, CustomContactSupportFormHelper.createContact('Person', 'Account', 'person.account@gmail.com', '03123123'));
        Test.stopTest();
    }
}