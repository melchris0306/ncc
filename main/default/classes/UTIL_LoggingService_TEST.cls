/*************************************************************************************************************
 * @name            UTIL_LoggingService_TEST
 * @author          divinobrinas <dbrinas@ulapp.co>
 * @created         2022-02-23
 * @description     [CCN1172] Test Class for UTIL_LoggingService class.
 *
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 *              No.     Date            Author                  Description
 *              ----    ------------    --------------------    ----------------------------------------------
 * @version     1.0     2022-02-23      divinobrinas            Initial version
 *
**************************************************************************************************************/

@isTest
private class UTIL_LoggingService_TEST{
    
    // Start of Constants for Test Methods
     
    private static final String UN_ALIAS = 'unEr';
    private static final String HN_ALIAS = 'hEr';
    private static final Integer NUM = 1;
    private static final String SYSTEM_ADMIN = 'System Administrator';
    private static final String TEST_EMAIL = 'automation@testapex.com';
    
    private static final String CLASS_ONE = 'CreateApexErrorLog';
    private static final String SUBJECT_ONE =  'Fwd: Force.com Sandbox: script exception from Accenture : '+
                                               'CreateApexErrorLog : Attempted to schedule too '+ 
                                               'many concurrent batch jobs in this org (limit is 5)';                                                
    private static final String BODY_ONE_A =  'Apex script unhandled exception by user/organization: ';
    private static final String BODY_ONE_B = ' /00D90000000fOLB caused by: System.Exception: Attempted to schedule too'+
                                            ' many concurrent batch jobs '+ 
                                            'Class.CreateApexErrorLog.execute: Debug Log: Starts';
    
    private static final String SUBJECT_TWO = 'Developer script exception from Accenture : CreateApexErrorLog : '+
                                              'Attempt to de-reference a null object';
    private static final String BODY_TWO_A = 'Apex script unhandled exception by user/organization: ';
    private static final String BODY_TWO_B = '/00D90000000fOLB Visualforce Page: /apex/flowfinishsecpage '+
                                             'caused by: System.NullPointerException: Attempt to de-reference a null object '+
                                             'Class.CreateApexErrorLog.dataSplit: line 132, column 1';
    
    private static final String CLASS_THREE = 'BeforeUpdate';
    private static final String SUBJECT_THREE = 'RE: Developer script exception from Test Org :BeforeUpdate: execution of AfterInsert';
    private static final String BODY_THREE_A = 'Apex script unhandled trigger exception by user/organization: ';
    private static final String BODY_THREE_B = ' /00D90000000fOLB exception by Test user Org System.QueryException: test: Trigger.BeforeUpdate: line 5, column 1';
    
    private static final String SUBJECT_FOUR_A = 'FW: Developer script exception from Test Org :';
    private static final String SUBJECT_FOUR_B = ' : List index out of bounds ';
    private static final String BODY_FOUR_A = 'Apex script unhandled exception by user/organization: ';
    private static final String BODY_FOUR_B = ' /00D90000000fOLB exception by Test user Org' +
                                              UTIL_ErrorConstants.CAUSED_BY + 'System.ListException: List index out of bounds:' +
                                              UTIL_ErrorConstants.PREFIX_CLASS;
    private static final String BODY_FOUR_C = '.testMethod: line 132, column 1'; 
    
    private static final String SUBJECT_SIX = 'Test:Subject:Exception';
    private static final String BODY_SIX = 'Test Body';
    
    private static final String TEST_ORG_ID = 'TestOrgId';
    private static final String TEST_APP = 'TestApp';
    private static final String TEST_CLASS = 'TestClass';
    private static final String TEST_METHOD = 'TestMethod';
    private static final String TEST_USER_ROLE = 'TestUserRole';
    private static final String ERROR = 'Error';
    private static final String SAMPLE = 'Example';
    private static final String ERROR_MESSAGE = 'ERROR MESSAGE';
    private static final String SAMPLE_PARAMATER = 'SAMPLE_PARAMATER';
    
    // End of Constants for Test Methods
    
    /**
      * @description       Method to create Messaging.InboundEmail type test data. 
      * @param             subject Subject of the email
      * @param             body Body of the email
      * @return            Messaging.InboundEmail
      * @throws            NA
      */
    private static Messaging.InboundEmail emailData(String subject, String body){
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = subject;
        email.plainTextBody = body;
        email.fromAddress = TEST_EMAIL;
        return email;
    }
    
    /**
      * @description       Method to create Custom Setting record to determine severity level. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    public static void severityLevelValue(){
        LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
        logLevel.LoggingLevel__c=UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
        insert logLevel;  
    }
    
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is logged
                           in case of Email sent from Sandbox Environment due to an Unhandled Exception. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void unhandledExceptionOne(){
        //User runUser = UTIL_TestMethods.runningUser(UN_ALIAS+NUM , SYSTEM_ADMIN);
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        //insert runUser; 
        severityLevelValue();
        String subject = SUBJECT_ONE;
        String body = UTIL_ErrorConstants.START_APEX_SCRIPT + UTIL_ErrorConstants.SANDBOX_EMAIL + BODY_ONE_A + runUser.Id + BODY_ONE_B;
                      
        Messaging.InboundEmail email1 = emailData(subject, body);         
        
        Test.startTest();
        System.runAs(runUser){
           UTIL_LoggingService.logUnhandledException(email1);
        }
        Test.stopTest();
        
        ExceptionLog__c excpData = [SELECT Id, ClassName__c FROM ExceptionLog__c WHERE ClassName__c=:CLASS_ONE]; 
        System.assertEquals(excpData.ClassName__c, CLASS_ONE);
    }
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is logged
                           in case of Email sent due to an Unhandled Exception. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void unhandledExceptionTwo(){
        //User runUser = UTIL_TestMethods.runningUser(UN_ALIAS+NUM+1 , SYSTEM_ADMIN);
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        //insert runUser; 
        severityLevelValue();
        String subject = SUBJECT_TWO;
        String body = BODY_TWO_A + runUser.Id + BODY_TWO_B;
                      
        Messaging.InboundEmail email2 = emailData(subject, body);         
        
        Test.startTest();
        System.runAs(runUser){
           UTIL_LoggingService.logUnhandledException(email2);
        }
        Test.stopTest();
        
        ExceptionLog__c excpData = [SELECT Id, ClassName__c, ExceptionDetails__c FROM ExceptionLog__c WHERE ClassName__c=:CLASS_ONE]; 
        System.assertEquals(excpData.ClassName__c, CLASS_ONE);
    }
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is logged
                           in case of Email sent due to an Unhandled Exception by a Trigger. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void unhandledExceptionThree(){
        //User runUser = UTIL_TestMethods.runningUser(UN_ALIAS+NUM+2 , SYSTEM_ADMIN);
        //insert runUser; 
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        severityLevelValue();
        String subject = SUBJECT_THREE;
        String body = BODY_THREE_A + runUser.Id + BODY_THREE_B;
                      
        Messaging.InboundEmail email3 = emailData(subject, body);         
        
        Test.startTest();
        System.runAs(runUser){
           UTIL_LoggingService.logUnhandledException(email3);
        }
        Test.stopTest();
        
        ExceptionLog__c excpData = [SELECT Id, ApexTrigger__c FROM ExceptionLog__c WHERE ApexTrigger__c=: CLASS_THREE]; 
        System.assertEquals(excpData.ApexTrigger__c, CLASS_THREE);
    }
    
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is logged
                           in case of Email sent due to an Unhandled Exception. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void unhandledExceptionFour(){
        //User runUser = UTIL_TestMethods.runningUser(UN_ALIAS+NUM+3 , SYSTEM_ADMIN);
        //insert runUser; 
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        severityLevelValue();
        ApexClass className = [SELECT Id, Name FROM ApexClass LIMIT 1];
        String subject = SUBJECT_FOUR_A + className.Name + SUBJECT_FOUR_B;
        String body = BODY_FOUR_A + runUser.Id + BODY_FOUR_B + className.Name + BODY_FOUR_C;
                      
        Messaging.InboundEmail email4 = emailData(subject, body);
        
        Test.startTest();
        System.runAs(runUser){
           UTIL_LoggingService.logUnhandledException(email4);
        }
        Test.stopTest();
        
        ExceptionLog__c excpData = [SELECT Id, ClassName__c FROM ExceptionLog__c WHERE ClassName__c=:className.Name];
        System.assertEquals(excpData.ClassName__c, className.Name);
    }
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is logged due to handled exception thrown
                           when logging an Unhandled Exception in case of an Email sent due to an Unhandled Exception.
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void unhandledExceptionFive(){
        //User runUser = UTIL_TestMethods.runningUser(UN_ALIAS+NUM+4 , SYSTEM_ADMIN);
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        severityLevelValue();        
        String subject = UTIL_ErrorConstants.BLANK_SPACE;
        String body = UTIL_ErrorConstants.BLANK_SPACE;
                      
        Messaging.InboundEmail email5 = emailData(subject, body);
        
        Test.startTest();
        System.runAs(runUser){
           UTIL_LoggingService.logUnhandledException(email5);
        }
        Test.stopTest();
        
       // ExceptionLog__c excpData = [SELECT Id, ClassName__c FROM ExceptionLog__c WHERE MethodName__c=:UTIL_ErrorConstants.UNHANDLED_ERROR_LOG_METHOD]; 
        
        //System.assertEquals(excpData.ClassName__c , UTIL_ErrorConstants.ERROR_LOG_CLASS);
    }
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is logged 
                           in case of an Email sent due to an Unhandled Exception. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void unhandledExceptionSix(){
        //User runUser = UTIL_TestMethods.runningUser(UN_ALIAS+NUM+5 , SYSTEM_ADMIN);
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        severityLevelValue();        
        String subject = SUBJECT_SIX;
        String body = BODY_SIX;
                      
        Messaging.InboundEmail email6 = emailData(subject, body);
        
        Test.startTest();
        System.runAs(runUser){
           UTIL_LoggingService.logUnhandledException(email6);
        }
        Test.stopTest();
        
        Integer excpDataCount = [SELECT COUNT() FROM ExceptionLog__c]; 
        System.assertEquals(excpDataCount , 1);
    }
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is logged 
                           in case of any program throwing a Handled Exception. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void handledException(){
        //User runUser = UTIL_TestMethods.runningUser(HN_ALIAS+NUM , SYSTEM_ADMIN);
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        severityLevelValue();
        try{
            Account testData = new Account();
            insert(testData);           
        }
        catch(DMLException excp){        
            Test.startTest();
              try {
                System.runAs(runUser){
                    UTIL_LoggingService.logHandledException(excp, TEST_ORG_ID, TEST_APP, TEST_CLASS, TEST_METHOD, null, LoggingLevel.ERROR);
                    UTIL_LoggingService.logHandledException(excp);
                    UTIL_LoggingService.logHandledExceptionReturnId(excp,TEST_ORG_ID,TEST_APP,TEST_CLASS,TEST_METHOD,null,LoggingLevel.ERROR);
                    UTIL_LoggingService.logHandledException('Error', TEST_ORG_ID, TEST_APP, TEST_CLASS, 
                                                            TEST_METHOD, null, LoggingLevel.ERROR,'400',true);
                    UTIL_LoggingService.createException(excp, TEST_ORG_ID, TEST_APP, TEST_CLASS, TEST_METHOD, null, LoggingLevel.ERROR);
                    
                        }
              } catch (Exception e) {

              }
            Test.stopTest();
        }
        List<ExceptionLog__c> excpData = [SELECT ClassName__c,MethodName__c,WSTransactionID__c, Severity__c,ExceptionType__c,ExceptionDetails__c,ContextUser__c FROM ExceptionLog__c WHERE Application__c =:TEST_APP LIMIT 1]; 
        //UTIL_LoggingService.logException(excpData);
        UTIL_LoggingService.logHandledException(excpData);
        System.assertEquals(excpData[0].ClassName__c, TEST_CLASS);
    }
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is merged with an existing ExceptionLog__c record
                           in case of any program throwing a Handled Exception. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void handledExceptionMerge(){
        //User runUser = UTIL_TestMethods.runningUser(HN_ALIAS+NUM+1 , SYSTEM_ADMIN);
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        severityLevelValue();
        try{
            Account testData1 = new Account();
            insert(testData1);           
        }
        catch(DMLException excp){                    
            try{
                Account testData2 = new Account();
                insert(testData2);           
            }
            catch(DMLException dmlExcp){
                Test.startTest();
                try {
                  System.runAs(runUser){
                    UTIL_LoggingService.logHandledException(excp, TEST_ORG_ID, TEST_APP, TEST_CLASS, TEST_METHOD, null, LoggingLevel.ERROR);
                  }
                } catch (Exception e) {

                }
                try {
                  System.runAs(runUser){
                    UTIL_LoggingService.logHandledException(dmlExcp, TEST_ORG_ID, TEST_APP, TEST_CLASS, TEST_METHOD, null, LoggingLevel.ERROR);
                  }
                } catch (Exception e) {

                }
                Test.stopTest();
            }
        }
        ExceptionLog__c excpData = [SELECT NumberOfTimesOccured__c FROM ExceptionLog__c WHERE Application__c=:TEST_APP]; 
        System.assertEquals(excpData.NumberOfTimesOccured__c, 2);
    }
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is logged 
                           in case of any program throwing an Exception due to Database.insert() operation. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void handledExceptionSave(){
        //User runUser = UTIL_TestMethods.runningUser(HN_ALIAS+NUM+2 , SYSTEM_ADMIN);
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        severityLevelValue();
        List<Account> accList = new List<Account>();
        Account accData1= new Account(Name = TEST_USER_ROLE+NUM);
        Account accData2= new Account();
        accList.add(accData1);
        accList.add(accData2);
        Database.SaveResult[] svRes = Database.insert(accList, false);          
                
        Test.startTest();
        System.runAs(runUser){

           UTIL_LoggingService.logDmlResults(svRes, null, accList, TEST_APP, TEST_CLASS, TEST_METHOD, null, LoggingLevel.ERROR);
        }
        Test.stopTest();
        
        ExceptionLog__c excpData = [SELECT ClassName__c, Severity__c FROM ExceptionLog__c WHERE Application__c=:TEST_APP]; 
        System.assertEquals(excpData.ClassName__c, TEST_CLASS);
        Integer noOfExcep = [SELECT COUNT() FROM ExceptionLog__c WHERE Application__c=:TEST_APP];
        System.assertEquals(noOfExcep, 1);
    }

    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is logged 
                           in case of any program throwing an Exception due to Database.delete() operation. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void handledExceptionDelete(){
        //User runUser = UTIL_TestMethods.runningUser(HN_ALIAS+NUM+3 , SYSTEM_ADMIN);
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        severityLevelValue();
        List<Account> accList = new List<Account>();
        Account accData1= new Account(Name = TEST_USER_ROLE+NUM);
        Account accData2= new Account(Name = TEST_USER_ROLE+NUM+1);
        accList.add(accData1);
        accList.add(accData2);
        insert accList;
        delete accList;
        Database.DeleteResult[] delRes = Database.delete(accList, false);            
                
        Test.startTest();
        System.runAs(runUser){
           UTIL_LoggingService.logDmlResults(null, delRes, accList, TEST_APP, TEST_CLASS, TEST_METHOD, null, LoggingLevel.ERROR);
        }
        Test.stopTest();
        
        List<ExceptionLog__c> excpData = [SELECT ClassName__c, Severity__c FROM ExceptionLog__c WHERE Application__c=:TEST_APP]; 
        System.assertEquals(excpData[0].ClassName__c, TEST_CLASS);
        Integer noOfExcep = [SELECT COUNT() FROM ExceptionLog__c WHERE Application__c=:TEST_APP];
        System.assertEquals(noOfExcep, 2);
    }
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is merged with an existing ExceptionLog__c record
                           in case of any program throwing an Exception due to Database.insert() operation.
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void handledExceptionSaveMerge(){
        //User runUser = UTIL_TestMethods.runningUser(HN_ALIAS+NUM+4 , SYSTEM_ADMIN);
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        severityLevelValue();
        List<Account> accList1 = new List<Account>();
        List<Account> accList2 = new List<Account>();
        
        Account accData1= new Account(Name = TEST_USER_ROLE+NUM );
        Account accData2= new Account();
        Account accData3= new Account(Name = TEST_USER_ROLE+NUM+1 );
        accList1.add(accData1);
        accList1.add(accData2);
        accList2.add(accData3);
        accList2.add(accData2);
        Database.SaveResult[] svRes1 = Database.insert(accList1, false);   
        Database.SaveResult[] svRes2 = Database.insert(accList2, false);                        
        Test.startTest();
        System.runAs(runUser){
           UTIL_LoggingService.logDmlResults(svRes1, null, accList1, TEST_APP, TEST_CLASS, TEST_METHOD, null, LoggingLevel.ERROR);
           UTIL_LoggingService.logDmlResults(svRes2, null, accList2, TEST_APP, TEST_CLASS, TEST_METHOD, null, LoggingLevel.ERROR);
        }
        Test.stopTest();
        try {
            List<ExceptionLog__c> excpData = [SELECT NumberOfTimesOccured__c FROM ExceptionLog__c WHERE Application__c=:TEST_APP]; 
        }
        catch(Exception e) {}
        //System.assertEquals(excpData.NumberOfTimesOccured__c, 2);
    }
    
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is logged 
                           in case of any program throwing a list of Handled Exceptions. 
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void handledLogListException(){
        //User runUser = UTIL_TestMethods.runningUser(HN_ALIAS+NUM+6 , SYSTEM_ADMIN);
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        severityLevelValue();
        List<ExceptionLog__c> excpList = new List<ExceptionLog__c>();                     
        ExceptionLog__c excepSingle = new ExceptionLog__c();
        
        try{
            UserRole userRoleRec = new UserRole();
            insert userRoleRec;
        }
        catch(DMLException excp){
            excepSingle = new ExceptionLog__c(ExceptionType__c=excp.getTypeName(), OrgId__c=TEST_ORG_ID, Application__c=TEST_APP, 
                                              ClassName__c=TEST_CLASS, MethodName__c=TEST_METHOD, Severity__c=UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR);
            excpList.add(excepSingle);
        }
        try{
            Account accRec = new Account();
            insert accRec;
        }
        catch(DMLException excp){
            excepSingle = new ExceptionLog__c(ExceptionType__c=excp.getTypeName(), OrgId__c=TEST_ORG_ID, Application__c=TEST_APP, 
                                              ClassName__c=TEST_CLASS, MethodName__c=TEST_METHOD, Severity__c=UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR);
            excpList.add(excepSingle);
        }
        Test.startTest();
        System.runAs(runUser){
           UTIL_LoggingService.logListException(excpList);
        }
        Test.stopTest();    
        Integer excpDataListNo = [SELECT COUNT() FROM ExceptionLog__c WHERE MethodName__c=:TEST_METHOD];
        System.assertEquals(excpDataListNo, 2);          
    }
    
    /**
      * @description       This Test Method is to verify that only 1 ExceptionLog__c record is logged when user inserts a list
                           of same exceptions. NumberoftimesOccured__c field value is set as 2.
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void handledListException(){
        //User runUser = UTIL_TestMethods.runningUser(HN_ALIAS+NUM+7 , SYSTEM_ADMIN);
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        severityLevelValue();
        List<ExceptionLog__c> excpList = new List<ExceptionLog__c>();
        ExceptionLog__c excepSingle = new ExceptionLog__c();
        try{
            Account accRec = new Account();
            insert accRec;
        }
        catch(DMLException excp){
            excepSingle = new ExceptionLog__c(ExceptionType__c=excp.getTypeName(), OrgId__c=TEST_ORG_ID, Application__c=TEST_APP, 
                                              ClassName__c=TEST_CLASS, MethodName__c=TEST_METHOD, ExceptionDetails__c=excp.getMessage(), 
                                              Severity__c=UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR);
            excpList.add(excepSingle);
        }
        try{
            Account accRec = new Account();
            insert accRec;
        }
        catch(DMLException excp){
            excepSingle = new ExceptionLog__c(ExceptionType__c=excp.getTypeName(), OrgId__c=TEST_ORG_ID, Application__c=TEST_APP, 
                                              ClassName__c=TEST_CLASS, MethodName__c=TEST_METHOD, ExceptionDetails__c=excp.getMessage(),
                                              Severity__c=UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR);           
            excpList.add(excepSingle);
        }
        Test.startTest();
        System.runAs(runUser){
            UTIL_LoggingService.logListException(excpList);
        }
        Test.stopTest();    
        Integer excpDataListNo = [SELECT COUNT() FROM ExceptionLog__c WHERE MethodName__c=:TEST_METHOD AND NumberOfTimesOccured__c=2];
        System.assertEquals(excpDataListNo, 1);          
    }
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is not logged when 
                           the Logging Level is below 'ERROR'.
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void handledExceptionLoggingLevel(){
        //User runUser = UTIL_TestMethods.runningUser(HN_ALIAS+NUM+8 , SYSTEM_ADMIN);
        User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        severityLevelValue();
        try{
            Account testData = new Account();
            insert(testData);           
        }
        catch(DMLException excp){        
            Test.startTest();
            System.runAs(runUser){
              try {
               UTIL_LoggingService.logHandledException(excp, TEST_ORG_ID, TEST_APP, TEST_CLASS, TEST_METHOD, null, LoggingLevel.FINE);
              } catch (Exception e) {

              }
            }
            Test.stopTest();
        }
        Integer excpDataCount = [SELECT COUNT() FROM ExceptionLog__c WHERE Application__c=:TEST_APP]; 
        System.assertEquals(excpDataCount, 0);
    }
    
    /**
      * @description       This Test Method is to verify that ExceptionLog__c record is logged 
                           in case of any program throwing a Handled Exception due to webservice call.
      * @param             NA
      * @return            void
      * @throws            NA
      */
    private static testMethod void logHandledServiceException(){
         //User runUser = UTIL_TestMethods.runningUser(HN_ALIAS+NUM+9 , SYSTEM_ADMIN);
         User runUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
         severityLevelValue();
         try{
             Account testData = new Account();
             insert(testData);           
         }
         catch(Exception excp){        
             Test.startTest();
             System.runAs(runUser){
                UTIL_LoggingService.logServiceException(excp, TEST_ORG_ID, TEST_APP, TEST_CLASS, TEST_METHOD, null, LoggingLevel.ERROR, TEST_APP, TEST_CLASS, TEST_APP+NUM, true);
             }
             Test.stopTest();
         }
         ExceptionLog__c excpData = [SELECT ClassName__c, Severity__c FROM ExceptionLog__c WHERE Application__c=:TEST_APP]; 
         System.assertEquals(excpData.ClassName__c, TEST_CLASS);
    }

    // private static testMethod void logAsynchCallOutExceptionTest(){
    //      User runUser = UTIL_TestMethods.runningUser(HN_ALIAS+NUM+10 , SYSTEM_ADMIN);
    //      severityLevelValue();
    //      AsynchRequest__c asycnhReq =new AsynchRequest__c();
    //      asycnhReq.AsynchType__c = SAMPLE;
    //      asycnhReq.Outcome__c = ERROR;
    //      asycnhReq.Outcome_Message__c = ERROR_MESSAGE;
    //      asycnhReq.Params__c = SAMPLE_PARAMATER;
    //      asycnhReq.Retries__c = 1;
    //      insert asycnhReq;
    //      AsynchRequest__c asycnhReqData = [Select Id,AsynchType__c,Outcome__c ,Outcome_Message__c,Params__c,Retries__c from AsynchRequest__c Where Id=: asycnhReq.Id];
    //     //Set mock callout class
    //     Test.startTest();
    //         UTIL_LoggingService.logAsynchCallOutException(asycnhReqData, LoggingLevel.ERROR, '401');
    //    Test.stopTest();
        
    //     ExceptionLog__c excp = [Select Id, Params__c,AsynchType__c,AsynchRequest__c From ExceptionLog__c where AsynchRequest__c=:asycnhReqData.Id];
    //     System.assertEquals(excp.Params__c, SAMPLE_PARAMATER); 
    //     System.assertEquals(asycnhReqData.Id, excp.AsynchRequest__c);  
         
    // }
}