/*******************************************************************************
 * @author       Angelo Rivera
 * @date         07.07.2022
 * @description  CCN-JOU-1849-DV - Updates Started Milestone Flag
 * @revision     07.07.2022- APRivera - Created
 *******************************************************************************/

global class BatchUpdateStartedMilestones implements Database.Batchable<SObject>, Schedulable, Database.Stateful{

    public String strQuery = '';
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        strQuery = 'SELECT Id, Name, Start_Date__c, End_Date__c, Milestone_Started__c FROM Milestone__c ' +
                    'WHERE Start_Date__c <= TODAY AND Milestone_Started__c = FALSE';

        System.debug(LoggingLevel.DEBUG, 'QUERY: ' + strQuery);
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        List<Milestone__c> lstMilestones = (List<Milestone__c>)scope;
        List<Milestone__c> lstMilestonesToUpdate = new List<Milestone__c>();

        if (!lstMilestones.isEmpty()) {
            for(Milestone__c m : lstMilestones){
                m.Milestone_Started__c = true;
                lstMilestonesToUpdate.add(m);
            }

            //CCN-2359 XEN REYES 2.DEC.2022
            Database.SaveResult[] srList = Database.update(lstMilestonesToUpdate, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred. ' + sr.getId());                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage() + ' ' + err.getFields());
                    }
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC) {

    }

    global void execute(SchedulableContext sc) {
        BatchUpdateStartedMilestones  batchObj = new  BatchUpdateStartedMilestones ();
        Id batchProcessId = Database.executeBatch(batchObj,100);
    }
}