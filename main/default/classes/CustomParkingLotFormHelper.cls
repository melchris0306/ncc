/**
* Description: This is the helper class for CustomParkingLotFormController, which creates a parking lot record
* Author: Jester Cabantog
* Version: 1.0
* Last modified date: 12/16/2020
**/

public with sharing class CustomParkingLotFormHelper {

    private static WithoutSharingClass withoutShare = new WithoutSharingClass(); 

    //PT-00333 Event Parking Lot
    public static void createParkingLotHelper(String eventId, String session, String email, String phone, String description, String type, String category){
        
        // Check a contact with entered email already exists to assign to the parking lot's raised by field
        // If no contacts found, a person account will be created along with a contact which will be used in the parking lot's raised by field
        String raisedById = checkContactExistsPL(email, phone);
        
        Parking_Lot__c newParkingLot = new Parking_Lot__c(
            Event__c = eventId,
            Session__c = session,
            Raised_By__c = raisedById,
            Description__c = description,
            Status__c = 'Open',
            Type__c = type,
            Category__c = category
        );

        try{
            //if(FlsUtils.isCreateable(newParkingLot, new List<String>{'Event__c','Session__c','Raised_By__c','Description__c','Status__c','Type__c'})){
                withoutShare.insertParkingLot(newParkingLot);
            //}
        } catch(DmlException e){
            throw new AuraHandledException(e.getMessage());
        }
    } 
    
    //PT-00333 Event Parking Lot
    // Check if a person account exists for the entered email
    public static String checkContactExistsPL(String email, String phone){
        List<Contact> contacts = new List<Contact>();
        if(FlsUtils.isAccessible('Contact', new List<String>{'Firstname','Lastname','Email'})){
            contacts = withoutShare.getContacts(email);
        }

        if (contacts.size() > 0){
            return contacts[0].Id;
        } else {
            String task_whoId = createContact(email, phone);
            return task_whoId;
        }
    }
	
	//START [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021
    public static String createContact(String email, String phone){
        Contact conRecord = new Contact();
        conRecord.FirstName = '';
        conRecord.LastName = email;
        conRecord.Email = email;
        conRecord.Phone = phone;

        if(FlsUtils.isCreateable(conRecord, new List<String>{'FirstName','LastName','Email','Phone'})){
            withoutShare.insertContact(conRecord);
        }

        return conRecord.Id;
    }
    //END [00780] Fix Partking Lot and Contact Us Form - Jester 2/5/2021 

    //Needs inner class declared without sharing for guest users to retrieve relevant records
    private without sharing class WithoutSharingClass {

        public void insertParkingLot(Parking_Lot__c newParkingLot){
            insert newParkingLot;
        }

        public void insertContact(Contact conRecord){
            insert conRecord;
        }

        public List<Contact> getContacts(String email){
            return [SELECT Firstname, Lastname, Email FROM Contact WHERE Email = :email ORDER BY CreatedDate DESC LIMIT 1];
        }
    }
}