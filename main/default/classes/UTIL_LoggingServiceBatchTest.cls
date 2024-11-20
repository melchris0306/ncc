@isTest
public class UTIL_LoggingServiceBatchTest {
    
    @testSetup static void setup(){
        //Insert Exception Logs records
        List<ExceptionLog__c> exceptLogInserted = new List<ExceptionLog__c>();
        for (Integer i = 0; i < 200; i++) {
            exceptLogInserted.add(new ExceptionLog__c(ApexTrigger__c = 'TestTrigger',
                                                      Application__c = 'Test App',
                                                      ClassName__c = 'Test Class' + i,
                                                      ContextUser__c = UserInfo.getUserId(),
                                                      ExceptionType__c = 'Test System.DmlException',
                                                      ExceptionDetails__c = 'Test System.DmlException Details',
                                                      ExceptionLogTimestamp__c = DateTime.now(),
                                                      MethodName__c = 'Test Method',
                                                      Severity__c = 'ERROR'
                                                     ));
        }
        insert exceptLogInserted;
    }
    
    @isTest
    static void testBatchDeleteExceptionLogs(){
        test.startTest();
        Database.executeBatch(new UTIL_LoggingServiceBatch());
        test.stopTest();
        system.assertEquals(0, [SELECT Count() FROM ExceptionLog__c WHERE Application__c = 'Test App']);
    }
    
    @isTest
    static void testSchedulableDeleteExceptionLogs(){
        Test.startTest();
        UTIL_LoggingServiceBatch sh1 = new UTIL_LoggingServiceBatch();
        String sch = '0 0 12 30 1/1 ?'; 
        system.schedule('Schedule Delete Exception Logs', sch, sh1); 
        Test.stopTest();
    }

}