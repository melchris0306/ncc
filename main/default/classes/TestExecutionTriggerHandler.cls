public class TestExecutionTriggerHandler {
    
    public static void onBeforeInsert(List<Test_Execution__c> newTestExecutionTaskList, Map<Id,Test_Execution__c> newTestExecutionTaskMap, List<Test_Execution__c> oldTestExecutionTaskList, Map<Id,Test_Execution__c> oldTestExecutionTaskMap){
        
        Set<Id> QATaskIds = new Set<Id>();
        List<Test_Execution__c> testExecutionFromButtonList = new List<Test_Execution__c>();
        
        for (Test_Execution__c testExecRecord : newTestExecutionTaskList){
            //START - CAPM-PMG-929-DV - MGP - 11/4/2023
            //if (testExecRecord.From_Test_Execution_Button__c
            if (testExecRecord.From_Test_Execution_Button__c && !testExecRecord.isClone() && !testExecRecord.IsClone__c){
                if(testExecRecord.Assigned_To__c == null){
                    testExecRecord.addError('Assigned To is required. Kindly complete the field.');
                }else{
                    testExecRecord.OwnerId = testExecRecord.Assigned_To__c;
                    testExecutionFromButtonList.add(testExecRecord);
                    QATaskIds.add(testExecRecord.QA_Task__c);
                }
                
            }else if(testExecRecord.isClone() || testExecRecord.IsClone__c){
                if(!testExecRecord.IsClone__c){
                    testExecRecord.Assigned_To__c = null;
                    testExecRecord.Testing_Phase__c = 'Other';
                }
                
                testExecRecord.Actual_Results__c = null;
                
                QATaskIds.add(testExecRecord.QA_Task__c);
                formatTestExecutionFromQA(newTestExecutionTaskList, QATaskIds);
            }//END - CAPM-PMG-929-DV - MGP - 11/4/2023
        }
        
        if(!testExecutionFromButtonList.isEmpty() && !QATaskIds.isEmpty()){
            formatTestExecutionFromQA(testExecutionFromButtonList, QATaskIds);
        }
        
    }
    
    
    public static void formatTestExecutionFromQA(List<Test_Execution__c> newTestExecutionList, Set<Id> QATaskIds){
        Map<String, Integer> mapOfTENamesAndCount = new Map<String, Integer>();
        Integer counter = 1;
        Map<String, String> testingPhaseMap = new Map<String, String>{'System Integration Testing' => 'SIT', 'User Acceptance Testing' => 'UAT', 'Prod Smoke Testing' => 'SMOKE', 'Other' => 'Other'};
            Map<Id, Test_Execution__c> testExecutionCountMap = new Map<Id, Test_Execution__c>([SELECT Id, Test_Execution__c.Name, QA_Task__c, Testing_Phase__c, Assigned_To__c, QA_Task__r.Name FROM Test_Execution__c WHERE QA_Task__c IN: QATaskIds]);
        System.debug('TECountmap: '+testExecutionCountMap.size());
        for (Test_Execution__c tee : testExecutionCountMap.values()){
            String teKey = (String.isNotBlank(tee.Name) ? extractSubstringUntilQA(tee.Name) : tee.Name)  + '-TE-' + testingPhaseMap.get(tee.Testing_Phase__c);
            String testExecutionNameFormat =  teKey + ';' + tee.QA_Task__c ;
            if(mapOfTENamesAndCount.containsKey(testExecutionNameFormat)){
                mapOfTENamesAndCount.put(testExecutionNameFormat, mapOfTENamesAndCount.get(testExecutionNameFormat)+1);
            }else{
                mapOfTENamesAndCount.put(testExecutionNameFormat, 1);
            }        
        }
        for(Test_Execution__c te: newTestExecutionList){
            String teKey = (String.isNotBlank(te.Name) ? extractSubstringUntilQA(te.Name) : te.Name)  + '-TE-' + testingPhaseMap.get(te.Testing_Phase__c);
            
            
            if(!mapOfTENamesAndCount.containsKey(teKey+';'+te.QA_Task__c)){
                mapOfTENamesAndCount.put(teKey+';'+te.QA_Task__c, 1);
                te.Name = teKey + '-' + 1 ; 
            }else{
                te.Name = teKey + '-' + (mapOfTENamesAndCount.get(teKey+';'+te.QA_Task__c)+1) ;
                mapOfTENamesAndCount.put((teKey+';'+te.QA_Task__c),mapOfTENamesAndCount.get(teKey+';'+te.QA_Task__c) + 1);
            }
            
            //START - CAPM-PMG-929-DV - MGP - 11/4/2023
            
        }
    }
    
    public static String extractSubstringUntilQA(String input) {
        Integer index = input.indexOf('-QA');
        if (index != -1) {
            return input.substring(0, index + 3); // Include "QA-" in the result
        }
        return input; // Return the original string if "QA-" is not found
    }
    
}