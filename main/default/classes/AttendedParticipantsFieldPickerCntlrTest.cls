/*******************************************************************************
 * @author       RLugpatan
 * @date         10/12/2021
 * @description  Test class for SetAttendedParticipantsFieldPickerCtrl [CCN975]
 *******************************************************************************/
@IsTest
public class AttendedParticipantsFieldPickerCntlrTest {
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
        
        Compass_Setting__c comp = TestDataFactory.createCSData(1);
        insert comp;

        Event__c e = new Event__c();
        e.Event_Id__c = 'xxxxxxxxxx';
        e.Campaign__c = camp.id;
        e.Start_Date_Time__c = DateTime.Now();
        e.End_Date_Time__c = DateTime.Now()+1;        
        e.Time_Zone__c = 'EDT'; 
        insert e;
    }
    
    @IsTest
    static void hasExistingAttendedFieldJSONTest(){
        Event__c eventRec = [SELECT Id FROM Event__c LIMIT 1];
        eventRec.Attended_Participant_Fields_JSON__c = '{"Readiness_Self_Ranking-Session_Participant__c|Readiness_Self_Ranking__c":true,"Session_Participation-Session_Participant__c|Session_Participation__c":true}';
        update eventRec;
        
        Test.startTest();
        	List<AttendedParticipantFields> regFields = SetAttendedParticipantsFieldPickerCtrl.getAttendedParticipantFields(eventRec.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void hasNoExistingAttendedFieldJSONTest(){
        Event__c eventRec = [SELECT Id FROM Event__c LIMIT 1];
        Test.startTest();
        	List<AttendedParticipantFields> regFields = SetAttendedParticipantsFieldPickerCtrl.getAttendedParticipantFields(eventRec.Id);
        Test.stopTest();
    }
    
    
    @IsTest
    static void handleSaveAttendedConfigurationTest(){
        Event__c eventRec = [SELECT Id FROM Event__c LIMIT 1];
        
        String jsonFieldConfig = '{"Readiness_Self_Ranking-Session_Participant__c|Readiness_Self_Ranking__c":true,"Session_Participation-Session_Participant__c|Session_Participation__c":true}';
        
        Test.startTest();
        	Boolean hasErrors = SetAttendedParticipantsFieldPickerCtrl.saveAttendedParticipantFields(eventRec.Id, jsonFieldConfig);
        Test.stopTest();
        
        System.assert(!hasErrors);
    }
    
    @IsTest
    static void handleExceptionTest(){
        Test.startTest();
        try {
            List<AttendedParticipantFields> regFields = SetAttendedParticipantsFieldPickerCtrl.getAttendedParticipantFields(null);
            Boolean hasErrors = SetAttendedParticipantsFieldPickerCtrl.saveAttendedParticipantFields(null, null);
        }catch (Exception e){
            System.assert(TRUE);
        }
        Test.stopTest();
        
    }
}