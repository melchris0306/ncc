global class BatchDeleteMilestoneMetrics implements Database.Batchable<SObject>, Database.Stateful{

        public String strQuery = '';
        global Database.QueryLocator start(Database.BatchableContext BC)
        {
            try {
                if(Test.isRunningTest()){
                    strQuery = 'SELECT Id, Name, Metric_Used__c, Milestone__c, Milestone__r.Journey__c, Milestone__r.Journey__r.Journey__c ' +
                            'FROM Participant_Milestone_Metric__c';
                }else{
                    strQuery = 'SELECT Id, Name, Metric_Used__c, Milestone__c, Milestone__r.Journey__c, Milestone__r.Journey__r.Journey__c ' +
                            'FROM Participant_Milestone_Metric__c WHERE Milestone__r.Journey__r.Journey__c = \'a594X000002XBtXQAW\'';
                }

                System.debug(LoggingLevel.DEBUG, 'QUERY: ' + strQuery);
                return Database.getQueryLocator(strQuery);
            } catch(Exception e) {
                return null;
            }
        }

        global void execute(Database.BatchableContext BC, List<SObject> scope)
        {
            List<Participant_Milestone_Metric__c> lstMetrics = (List<Participant_Milestone_Metric__c>)scope;

            if (!lstMetrics.isEmpty()) {
                Database.delete(lstMetrics);
            }
        }

        global void finish(Database.BatchableContext BC) {

        }
    }