/**
* 			@description Controller for CloneTestExecutionScreen LWC 
* 
*           11/29/2023 - Miguel Punzal - Initial Version
*
**/
public class CloneTestExecutionScreenController {
    
    public class TestExecutionData {
        @AuraEnabled public List<Test_Execution__c> testExeuctionRecords = new List<Test_Execution__c>();
        @AuraEnabled public List<TestingPhaseValue> testingPhaseValues = new List<TestingPhaseValue>();
    }
    
    public class TestingPhaseValue {
        @AuraEnabled public String label = '';
        @AuraEnabled public String value = '';
    }
    
    @AuraEnabled
    public static TestExecutionData getData(String recId){
        
        TestExecutionData teData = new TestExecutionData();
        teData.testExeuctionRecords = getTestExecutions(recId);
        teData.testingPhaseValues = getTestingPhaseValues();
        return teData;
    }
    
    @AuraEnabled
    public static List<TestingPhaseValue> getTestingPhaseValues(){
        List<TestingPhaseValue> testingPhaseValues = new List<TestingPhaseValue>();
        
        // Get the object describe result
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get('Test_Execution__c').getDescribe();
        
        // Get the field describe result for the picklist field
        Schema.DescribeFieldResult fieldDescribe = describeResult.fields.getMap().get('Testing_Phase__c').getDescribe();
        
        // Check if the field is a picklist
        if (fieldDescribe.getType() == Schema.DisplayType.PICKLIST) {
            // Get the picklist values
            List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
            
            // Loop through the picklist values to get label and value
            for (Schema.PicklistEntry picklistEntry : picklistValues) {
                TestingPhaseValue teVal = new TestingPhaseValue();
                teVal.label = picklistEntry.getLabel();
                teVal.value = picklistEntry.getValue();
                testingPhaseValues.add(teVal); 
            }
        } else {
            // Handle if the field is not a picklist
            System.debug('Field is not a picklist.');
        }
            
        return testingPhaseValues;
    }
    
    @AuraEnabled
    public static List<Test_Execution__c> getTestExecutions(String recordId){
        if(String.isBlank(recordId)){
            return new List<Test_Execution__c>();
        }
        return [SELECT Id, Name, QA_Task__c, Expected_Results__c, Testing_Phase__c, Epic__c, Epic__r.Name, Assigned_To__c, Assigned_To__r.Name, OwnerId, Owner.Name, Project__c, Feature__c, Functionality__c, Dev_Task__c, Template_Task__c, Test_Scenario__c  FROM Test_Execution__c 
                WHERE QA_Task__c =: recordId OR Project__c =: recordId OR Functionality__c =: recordId OR Feature__c =: recordId OR Epic__c =: recordId OR Dev_Task__c =: recordId ORDER BY Name ASC];
    }
    
    @AuraEnabled
    public static List<Test_Execution__c> getTestExecutionsById(List<String> recordIds){
        if(recordIds.isEmpty()){
            return new List<Test_Execution__c>();
        }
        return [SELECT Id, Name, QA_Task__c, Expected_Results__c, Testing_Phase__c, Epic__c, Epic__r.Name, Assigned_To__c, Assigned_To__r.Name, OwnerId, Owner.Name, Project__c, Feature__c, Functionality__c, Dev_Task__c, Template_Task__c, Test_Scenario__c FROM Test_Execution__c 
                WHERE Id IN :recordIds];
    }
}