/**
* Description: This is the helper class for CustomContactSupportFormController, which creates a task from the data entered on the custom contact
* support form. The helpers will check if the event's Contact_Us_User field has a value, if yes it will asssign
* the task to this user, otherwise it will assign it to the event's owner. It will also check if a contact/person account
* exist with the email entered on the form, if yes it will link this contact/person account to the Name field on the task,
* otherwise it will create a person account from these details and assign it to the Name field. 
* Author: Jasmine Nguyen
* Version: 1.0
* Last modified date: 15/8/2020
**/
public with sharing class CustomContactSupportFormHelper{ 
    
    private static WithoutSharingClass withoutShare = new WithoutSharingClass();

    @testVisible
    public static Boolean throwFakeTaskException = false;
    
    @testVisible
    public static Boolean throwFakePersonAccountException = false;
    
    public static void createTaskHelper(String eventId, String firstname, String lastname, String email, String phone, String subject, String comments){
        
        // Check if Contact_Us_User__c is populated on event, if not assign task to event's owner
        Event__c event = getEventDetails(eventId);

        String task_OwnerId;
        if (event != null && (String.isNotBlank(event.Contact_Us_User__c))){
            task_OwnerId = event.Contact_Us_User__c;
        } else if (event != null && (String.isNotBlank(event.OwnerId))) {
            task_OwnerId = event.OwnerId;
        }
        
        // Check a contact with entered email already exists to assign to the task's Name field
        // If no contacts found, a person account will be created along with a contact which will be used in the task's Name field
        // CCN-JOU-1224-DV CCN-EVE-1223-DV XEN REYES April 28, 2022
        Contact task_WhoId = checkContactExists(firstname, lastname, email, phone);
        
        createTaskOnEvent(event, task_OwnerId, task_WhoId.Id, subject, comments, phone);
    } 
    
    // Create task
    public static void createTaskOnEvent(Event__c event, String task_OwnerId, String task_WhoId, String subject, String comments, String phone){
        Task newTask = new Task();
        newTask.Subject = subject;
        newTask.Description = comments;
        newTask.OwnerId = task_OwnerId;
        newTask.WhoId = task_WhoId;
        newTask.WhatId = event.Id;
        newTask.Task_Origin__c = 'Contact Us Page';
        newTask.Type = 'Email';
        newTask.ActivityDate = System.today();
        newTask.Phone_Number__c = phone; //CCN-JOU-1224-DV CCN-EVE-1223-DV XEN REYES 10 Apr 2022
        
        try{
            // Set WhatId to an invalid ID to trigger a fake exception
            if (throwFakeTaskException){
                newTask.WhatId = 'somerandomId';
            }

            //removed FLSUtil check because all fields are non-creatable despite having Edit Access in those fields
            List<Task> newTaskList = new List<Task>{newTask};
            withoutShare.createTask(newTaskList);
            // Updated by JC Espino [CCN1042] MAR082022 - ADDED EMAIL FUNCTIONALITY UPON CONTACT US INQUIRY SUBMISSION
            if(event != null && event.Contact_Us_User__c != null && newTask != null){
                withoutShare.sendContactUsEmail(newTask, event);
            }
            
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // Get event details
    public static Event__c getEventDetails(String eventId){
        List<Event__c> events = new List<Event__c>();
        if(FlsUtils.isAccessible('Event__c', new List<String>{'Name','Description__c','OwnerId','Contact_Us_User__c', 'Email_Sender_Id__c'})){
            events = withoutShare.getEvents(eventId);
        }

        return !events.isEmpty() ? events[0] : null;
    }
    
    // Check if a person account exists for the entered email
    //CCN-JOU-1224-DV CCN-EVE-1223-DV XEN REYES April 28, 2022
    public static Contact checkContactExists(String firstname, String lastname, String email, String phone){
        List<Contact> contacts = withoutShare.getContacts(email);
        if (!contacts.isEmpty()){
            //return contacts[0].Id;

            //Update contact with the value of phone number from contact us if empty
            if(contacts[0].Phone == null && phone != null){
                String invalidNumbers = '[^0-9]'; 
                contacts[0].Phone = phone.replaceAll( invalidNumbers, '' );
                withoutShare.updateContact(new List<Contact>{contacts[0]});
            }
            return contacts[0];

        } else {
            //String task_whoId = createContact(firstname, lastname, email, phone); //[00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021
            //return task_whoId;
            Contact contactNew = createContact(firstname, lastname, email, phone); //[00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021
            return contactNew;
        }
    }
   
    //START [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021
    //CCN-JOU-1224-DV CCN-EVE-1223-DV XEN REYES April 28, 2022
    public static Contact createContact(String firstname, String lastname, String email, String phone){
        Contact conRecord = new Contact();
        conRecord.FirstName = firstname;
        conRecord.LastName = lastname;
        conRecord.Email = email;
        conRecord.Phone = phone;

        if(FlsUtils.isCreateable(conRecord, new List<String>{'FirstName', 'LastName', 'Email', 'Phone'})){
            List<Contact> conList = new List<Contact>{conRecord};
            withoutShare.createContact(conList);
        }

        //return conRecord.Id;
        return conRecord;
    }
    //END [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021

    //Needs inner class declared without sharing for guest users to retrieve relevant records
    private without sharing class WithoutSharingClass{

        public void createTask(List<Task> newTaskList){
            insert newTaskList;
        }

        public void createContact(List<Contact> conRecordList){
            insert conRecordList;
        }

        public List<Contact> getContacts(String email){
            //CCN-JOU-1224-DV CCN-EVE-1223-DV XEN REYES April 28, 2022
            return [SELECT Firstname, Lastname, Email, Phone FROM Contact WHERE Email =: email LIMIT 1];
        }

        //CCN-JOU-1224-DV CCN-EVE-1223-DV XEN REYES April 28, 2022
        public void updateContact (List<Contact> conRecordList){
            update conRecordList;
        }

        public List<Event__c> getEvents(String eventId){
            return [SELECT Id, Name, Description__c, OwnerId, Contact_Us_User__c, Email_Sender_Id__c FROM Event__c WHERE Event_Id__c = :eventId];
        }

        // Updated by JC Espino [CCN1042] MAR082022 - ADDED EMAIL FUNCTIONALITY UPON CONTACT US INQUIRY SUBMISSION
        public void sendContactUsEmail(Task newTask, Event__c event) {
            User contactUsUser = [SELECT FirstName, LastName FROM User WHERE Id = :event.Contact_Us_User__c];
            Contact requestor = [SELECT Name, Email, Phone FROM Contact WHERE Id = :newTask.whoId];
    
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            String emailBody = 
                '<p>Dear ' + contactUsUser.FirstName + ' ' + contactUsUser.LastName + ',</p>' +
                '<p>Someone has reached out through Contact Us in the ' + event.Name +  '.</p>' +
                'Subject: ' + newTask.Subject + '<br>' +
                'Comment: ' + newTask.Description + '<br>' +
                'Submitted by: <br>' +
                '&emsp;' + requestor.Name + '<br>' +
                '&emsp;' + requestor.Email + '<br>' +
                '&emsp;' + ((newTask.Phone != null) ? newTask.Phone : '');

            message.setTargetObjectId(event.Contact_Us_User__c);
            message.setSaveAsActivity(false);
            message.setOrgWideEmailAddressId(event.Email_Sender_Id__c);
            message.setSubject('A New Contact Us Item Has Been Created For Your Event');
            message.setHtmlBody(emailBody);
    
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message});
        }

    }
}