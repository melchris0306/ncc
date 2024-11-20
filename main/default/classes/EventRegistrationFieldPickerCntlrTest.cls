/*******************************************************************************
 * @author       Kyzer Buhay
 * @date         06/07/2021
 * @description  Test class for EventRegistrationFieldPickerControllerTest
 * @revision     06/07/2021 - ADFrancisco - Created
 *******************************************************************************/
@IsTest
public class EventRegistrationFieldPickerCntlrTest {
    @TestSetup static void createData(){
        Campaign__c camp = new Campaign__c();
        camp.Name = 'Test Campaign';
        insert camp;
        
        Contact c = new Contact();
        c.FirstName = 'John';
        c.LastName = 'John';
        c.Department = 'IT';
        c.Email = 'John@test.com';
        insert c;
        
        Event__c e = new Event__c();
        e.Event_Id__c = 'xxxxxxxxxx';
        e.Campaign__c = camp.id;
        e.Start_Date_Time__c = DateTime.Now();
        e.End_Date_Time__c = DateTime.Now()+1;
        //Start [CCN-2530] RIANNO RIZARRI Feb01.2023 - Added this required field for test data.
        e.time_zone__c = 'AKDT';
        //End [CCN-2530] RIANNO RIZARRI Feb01.2023 - Added this required field for test data.
        insert e;
    }
    
    @IsTest
    static void hasExistingRegistrationFieldJSONTest(){
        Event__c eventRec = [SELECT Id FROM Event__c LIMIT 1];
        //Start [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
        eventRec.Registration_Fields_JSON__c = '{"RegistrationField_FirstName-Contact|FirstName":{"required":true,"active":true},"RegistrationField_LastName-Contact|LastName":{"required":true,"active":true},"RegistrationField_Email-Contact|Email":{"required":true,"active":true},"RegistrationField_Site-Contact|Site__c":{"required":false,"active":true},"RegistrationField_Department-Contact|Department":{"required":false,"active":false},"RegistrationField_Title-Contact|Title":{"required":false,"active":true}}';
		//END [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.        
        update eventRec;
        
        Test.startTest();
        	List<RegistrationFields> regFields = EventRegistrationFieldPickerController.getAvailableRegistrationFields(eventRec.Id);
        Test.stopTest();
        System.assert(regFields.size() > 0);
    }
    
    @IsTest
    static void hasNoExistingRegistrationFieldJSONTest(){
        Event__c eventRec = [SELECT Id FROM Event__c LIMIT 1];
        Test.startTest();
        	List<RegistrationFields> regFields = EventRegistrationFieldPickerController.getAvailableRegistrationFields(eventRec.Id);
        Test.stopTest();
        System.assert(regFields.size() > 0);
    }
    
    
    @IsTest
    static void handleSaveRegistrationConfigurationTest(){
        Event__c eventRec = [SELECT Id FROM Event__c LIMIT 1];
        
        String jsonFieldConfig = '{"RegistrationField_FirstName-Contact|FirstName":true,"RegistrationField_LastName-Contact|LastName":true,' +
            									'"RegistrationField_Email-Contact|Email":true,"RegistrationField_Site-Contact|Department":false}';
        
        Test.startTest();
        	Boolean hasErrors = EventRegistrationFieldPickerController.saveRegistrationFormFields(eventRec.Id, jsonFieldConfig);
        Test.stopTest();
        
        System.assert(!hasErrors);
    }
}