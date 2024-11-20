trigger OutreachNotificationSettingTrigger on Outreach_Notification_Setting__c (before insert, before update) {
    if(Trigger.isBefore && Trigger.isInsert){
        ONSettingTriggerHandler.onBeforeInsert(Trigger.new);
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        ONSettingTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}