public class UTIL_LoggingServiceBatch implements Schedulable, Database.Batchable<sObject>{
    
    public void execute(SchedulableContext sCon) {
        Database.executeBatch(new UTIL_LoggingServiceBatch(), 200);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, CreatedDate FROM ExceptionLog__c WHERE CreatedDate = LAST_N_DAYS:30]);
    }
    
    public void execute(Database.BatchableContext bc, List<ExceptionLog__c> exceptionLogList){
        try {
            List<ExceptionLog__c> exceptionLogToDeleteList = new List<ExceptionLog__c>();
            
            for(ExceptionLog__c excepLog : exceptionLogList){
                exceptionLogToDeleteList.add(excepLog);
            }
            
            List<String> errors = new List<String>();
            
            if(!exceptionLogToDeleteList.isEmpty()){
                Database.DeleteResult[] srList = Database.delete(exceptionLogToDeleteList, false);
            }
            
        }catch(Exception e){
            UTIL_LoggingService.logHandledException(e);
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }
    
}