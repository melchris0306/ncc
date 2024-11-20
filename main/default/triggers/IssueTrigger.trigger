/**
@revision Kyzer Buhay - Removed Project in Trigger name (ProjectIssueTrigger) to IssueTrigger
**/
trigger IssueTrigger on Issue__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  new IssueTriggerHandler().execute();
}