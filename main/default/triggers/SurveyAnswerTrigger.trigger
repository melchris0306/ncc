trigger SurveyAnswerTrigger on Survey_Answer__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	new SurveyAnswerTriggerHandler().execute();
}